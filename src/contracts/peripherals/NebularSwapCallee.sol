// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@nebular/interfaces/IERC20Minimal.sol";
import "@nebular/interfaces/callback/INebularSwapCallback.sol";
import "@nebular/interfaces/pool/INebularPoolActions.sol";
import "@nebular/contracts/peripherals/NebularCalleeBase.sol";

/**
 * @title  NebularSwapCallee
 * @notice Helper contract that initiates **exact-input** swaps on a NebularPool
 *         and settles the resulting token deltas in the callback.
 * @dev    Stateless wrapper around {INebularPoolActions.swap}. The contract:
 *         1. Pulls `amountIn` from the caller.
 *         2. Calls `swap()` with positive `amountSpecified`.
 *         3. Pays any positive `amount0Delta`/`amount1Delta` back to the pool
 *            during `nebularSwapCallback`.
 */
contract NebularSwapCallee is NebularCalleeBase, INebularSwapCallback {
    /**
     * @notice Contract constructor.
     * @param _initialOwner Address that will become the contract owner.
     * @param _factory      Canonical NebularFactory address (used in {_verifyPool}).
     */
    constructor(address _initialOwner, address _factory)
        NebularCalleeBase(_initialOwner, _factory)
    {}

    /**
     * @notice Execute an exact-input swap on a NebularPool.
     * @dev    Encodes `token0` and `token1` so the callback knows which tokens
     *         to transfer back. For simplicity, the payer is always `address(this)`.
     *
     * @param pool              Address of the target NebularPool.
     * @param recipient         Address receiving the output tokens.
     * @param zeroForOne        Swap direction (`true` = token0 → token1).
     * @param amountIn          Exact input amount (sent to the pool).
     * @param sqrtPriceLimitX96 Price limit (Uniswap-style). Can be `0` for no limit.
     * @param token0            ERC-20 address of token0.
     * @param token1            ERC-20 address of token1.
     *
     * Requirements:
     * - Caller must have approved this contract for at least `amountIn`
     *   of the *input* token.
     * - At least one of `token0` / `token1` must be non-zero (enforced by pool).
     */
    function swapExactInput(
        address pool,
        address recipient,
        bool zeroForOne,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96,
        address token0,
        address token1
    ) external {
        address tokenIn = zeroForOne ? token0 : token1;

        // Pull exact input from caller to this contract
        IERC20Minimal(tokenIn).transferFrom(msg.sender, address(this), amountIn);

        // Initiate the swap; pool will callback for settlement
        INebularPoolActions(pool).swap(
            recipient,
            zeroForOne,
            int256(amountIn),           // positive ⇒ exact input
            sqrtPriceLimitX96,
            abi.encode(token0, token1)  // context for callback
        );
    }

    /**
     * @inheritdoc INebularSwapCallback
     * @dev Transfers any positive delta back to the pool (`msg.sender`).
     *
     * Decoded `data` layout: `(address token0, address token1)`.
     *
     * Requirements:
     * - Caller must be a NebularPool verified by {_verifyPool}.
     * - The contract must hold at least `amount{0,1}Delta` of each token,
     *   otherwise the call will revert due to an ERC-20 `transfer` failure.
     */
    function nebularSwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external override {
        _verifyPool();

        (address token0, address token1) =
            abi.decode(data, (address, address));

        if (amount0Delta > 0) {
            IERC20Minimal(token0).transfer(msg.sender, uint256(amount0Delta));
        }
        if (amount1Delta > 0) {
            IERC20Minimal(token1).transfer(msg.sender, uint256(amount1Delta));
        }
    }
}
