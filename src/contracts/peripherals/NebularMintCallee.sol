// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@nebular/interfaces/IERC20Minimal.sol";
import "@nebular/interfaces/callback/INebularMintCallback.sol";
import "@nebular/interfaces/pool/INebularPoolActions.sol";
import "@nebular/contracts/peripherals/NebularCalleeBase.sol";

/**
 * @title  NebularMintCallee
 * @notice Helper contract that initiates a liquidity-mint on a NebularPool and
 *         repays the owed `token0` / `token1` amounts inside the callback.
 * @dev    Stateless wrapper around {INebularPoolActions.mint}.  
 *         The pool determines the exact owed amounts and passes them back via
 *         `nebularMintCallback`. This contract then transfers the tokens from
 *         its own balance to the pool.
 */
contract NebularMintCallee is NebularCalleeBase, INebularMintCallback {
    /**
     * @notice Contract constructor.
     * @param _initialOwner Address that will become the contract owner.
     * @param _factory      Canonical NebularFactory address (used in {_verifyPool}).
     */
    constructor(address _initialOwner, address _factory)
        NebularCalleeBase(_initialOwner, _factory)
    {}

    /**
     * @notice Convenience function to add concentrated liquidity to a pool.
     * @dev    Encodes `token0` and `token1` so the callback knows which tokens
     *         to transfer. The actual liquidity NFT is minted to `recipient`.
     *
     * @param pool       Address of the target NebularPool.
     * @param recipient  Address that will receive the liquidity-position NFT.
     * @param tickLower  Lower tick boundary of the position.
     * @param tickUpper  Upper tick boundary of the position.
     * @param amount     Liquidity to add (Q128.128 format, mirrors pool spec).
     * @param token0     ERC-20 address of token0.
     * @param token1     ERC-20 address of token1.
     *
     * Requirements:
     * - This contract must already hold sufficient `token0`/`token1`
     *   to pay the owed amounts – or the pool will revert in the callback.
     */
    function addLiquidity(
        address pool,
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        address token0,
        address token1
    ) external {
        // Encode token addresses for later repayment in the callback
        bytes memory data = abi.encode(token0, token1);
        INebularPoolActions(pool).mint(
            recipient,
            tickLower,
            tickUpper,
            amount,
            data
        );
    }

    /**
     * @inheritdoc INebularMintCallback
     * @dev Transfers the exact owed amounts back to the pool (`msg.sender`).
     *
     * @param amount0Owed Exact amount of `token0` the pool expects.
     * @param amount1Owed Exact amount of `token1` the pool expects.
     * @param data        ABI-encoded context (`token0`, `token1`).
     */
    function nebularMintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata data
    ) external override {
        _verifyPool();

        (address token0, address token1) = abi.decode(data, (address, address));

        if (amount0Owed > 0) IERC20Minimal(token0).transfer(msg.sender, amount0Owed);
        if (amount1Owed > 0) IERC20Minimal(token1).transfer(msg.sender, amount1Owed);
    }
}
