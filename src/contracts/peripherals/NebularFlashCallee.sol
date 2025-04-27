// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@nebular/interfaces/IERC20Minimal.sol";
import "@nebular/interfaces/callback/INebularFlashCallback.sol";
import "@nebular/interfaces/pool/INebularPoolActions.sol";
import "@nebular/contracts/peripherals/NebularCalleeBase.sol";

/**
 * @title  NebularFlashCallee
 * @notice Helper contract that requests a flash-loan from a NebularPool and
 *         repays principal **plus** fee in the callback.
 * @dev    Stateless wrapper around {INebularPoolActions.flash}. All state-full
 *         validations live in the pool itself. This contract only:
 *         1. Pre-funds the pool with the requested principal (pull-model).
 *         2. Decodes callback data and repays principal + fee.
 *         3. Uses {_verifyPool} to ensure the caller is an authentic NebularPool.
 */
contract NebularFlashCallee is NebularCalleeBase, INebularFlashCallback {
    /**
     * @notice Contract constructor.
     * @param _initialOwner Address that will become the contract owner.
     * @param _factory      Canonical NebularFactory address (used in {_verifyPool}).
     */
    constructor(address _initialOwner, address _factory)
        NebularCalleeBase(_initialOwner, _factory)
    {}

    /**
     * @notice Initiate a flash-loan on a target NebularPool.
     * @dev    Uses **pull** payment: the principal is transferred *before*
     *         calling {INebularPoolActions.flash}, ensuring the pool can
     *         safely forward funds to `recipient`.
     *
     * @param pool      Address of the NebularPool to borrow from.
     * @param recipient Address that will receive the borrowed tokens.
     * @param amount0   Amount of `token0` to borrow (may be zero).
     * @param amount1   Amount of `token1` to borrow (may be zero).
     * @param token0    ERC-20 address of token0 as defined by the pool.
     * @param token1    ERC-20 address of token1 as defined by the pool.
     *
     * Requirements:
     * - Caller must have approved this contract to spend `amount0/amount1`
     *   of each respective token.
     * - At least one of `amount0` or `amount1` must be non-zero.
     */
    function flashBorrow(
        address pool,
        address recipient,
        uint256 amount0,
        uint256 amount1,
        address token0,
        address token1
    ) external {
        // Pre-fund the pool so it can forward the borrowed amounts.
        if (amount0 > 0) IERC20Minimal(token0).transferFrom(msg.sender, pool, amount0);
        if (amount1 > 0) IERC20Minimal(token1).transferFrom(msg.sender, pool, amount1);

        // Encode callback context: tokens, principal & payer address
        bytes memory data = abi.encode(token0, token1, amount0, amount1, msg.sender);

        // Trigger the flash-loan
        INebularPoolActions(pool).flash(recipient, amount0, amount1, data);
    }

    /**
     * @inheritdoc INebularFlashCallback
     * @dev Re-enters the pool to repay `principal + fee`. Uses {_verifyPool}
     *      to guarantee the caller is the trusted pool.
     *
     * @param fee0  Fee amount owed for token0.
     * @param fee1  Fee amount owed for token1.
     * @param data  ABI-encoded context produced in {flashBorrow}.
     *
     * Decoded `data` layout:  
     * `(address token0, address token1, uint256 amount0, uint256 amount1, address payer)`.
     */
    function nebularFlashCallback(
        uint256 fee0,
        uint256 fee1,
        bytes calldata data
    ) external override {
        _verifyPool();

        (
            address token0,
            address token1,
            uint256 amount0,
            uint256 amount1,
            address payer
        ) = abi.decode(data, (address, address, uint256, uint256, address));

        uint256 total0 = amount0 + fee0;
        uint256 total1 = amount1 + fee1;

        // Pull the total owed amounts from `payer` back to the pool (msg.sender).
        if (total0 > 0) IERC20Minimal(token0).transferFrom(payer, msg.sender, total0);
        if (total1 > 0) IERC20Minimal(token1).transferFrom(payer, msg.sender, total1);
    }
}
