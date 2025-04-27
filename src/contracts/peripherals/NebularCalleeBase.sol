// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@nebular/interfaces/IERC20Minimal.sol";
import "@nebular/interfaces/INebularPool.sol";
import "@nebular/libraries/Errors.sol";

/**
 * @title  NebularCalleeBase
 * @notice Base contract for helper “callee” contracts (swap, mint, flash-loan, etc.).
 *         It offers:
 *         - Ownership (via OpenZeppelin’s {Ownable})
 *         - Sweep functions to recover stranded tokens / native currency
 *         - A pool–verification helper to secure Nebular callbacks
 * @dev    All child contracts must pass the canonical NebularFactory address
 *         to the constructor so that `_verifyPool()` can validate callbacks.
 *         The contract is intentionally *stateless* beyond that.
 */
abstract contract NebularCalleeBase is Ownable {
    /// @notice Canonical NebularFactory address used to validate callbacks.
    address public immutable factory;

    /**
     * @notice Contract constructor
     * @dev    Deploys the contract, sets the immutable factory address and transfers
     *         initial ownership to `_initialOwner`.
     * @param _initialOwner Address that will receive ownership rights.
     * @param _factory      Address of the NebularFactory deployed on the same chain.
     *
     * Requirements:
     * - `_factory` must be non-zero, otherwise a {ZeroAddress} error is thrown.
     */
    constructor(address _initialOwner, address _factory)
        Ownable(_initialOwner)
    {
        if (_factory == address(0)) revert ZeroAddress();
        factory = _factory;
    }

    /**
     * @notice Withdraw ERC-20 tokens accidentally held by the contract.
     * @dev    Only callable by the contract owner.
     * @param token   ERC-20 token address.
     * @param to      Recipient address.
     * @param amount  Amount to transfer (use `IERC20(balanceOf(this))` to drain all).
     *
     * Emits no events by design; downstream callers may emit their own logs.
     *
     * Requirements:
     * - Caller **must** be the owner (enforced by {onlyOwner}).
     * - `to` **must not** be the zero address, otherwise {ZeroAddress} error.
     */
    function sweepToken(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        if (to == address(0)) revert ZeroAddress();
        IERC20Minimal(token).transfer(to, amount);
    }

    /**
     * @notice Withdraw native currency (ETH, MATIC, etc.) held by the contract.
     * @dev    Only callable by the contract owner.
     * @param to     Recipient address.
     * @param amount Amount to transfer.
     *
     * Requirements:
     * - Caller **must** be the owner (enforced by {onlyOwner}).
     * - `to` **must not** be the zero address, otherwise {ZeroAddress} error.
     * - Call **must** succeed, otherwise it reverts with `SWEEP_NATIVE_FAILED`.
     */
    function sweepNative(address to, uint256 amount) external onlyOwner {
        if (to == address(0)) revert ZeroAddress();
        (bool success, ) = to.call{ value: amount }("");
        require(success, "SWEEP_NATIVE_FAILED");
    }

    /**
     * @notice Enables the contract to receive native currency.
     * @dev    Intentionally left empty; the fallback merely accepts ETH.
     */
    receive() external payable {}

    /**
     * @notice Internal guard for Nebular callbacks.
     * @dev    Reverts with {InvalidPool} unless `msg.sender` is a NebularPool
     *         created by the canonical factory (`factory`).
     *
     * Child contracts **must** call this in their respective callback
     * implementations (swap, mint, flash) before any sensitive logic.
     */
    function _verifyPool() internal view {
        if (INebularPool(msg.sender).factory() != factory) revert InvalidPool();
    }
}
