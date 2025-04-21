// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title INebularFlashCallback
 * @notice Interface for contracts that use flash loans via INebularPoolActions#flash.
 * @dev Contracts executing a flash loan must implement this interface to handle the callback and repay the loan.
 */
interface INebularFlashCallback {
    /**
     * @notice Callback invoked by a NebularPool after executing a flash loan.
     * @dev The recipient must repay the borrowed amount plus the fees for both token0 and token1 within this call.
     *      The caller must be validated to ensure it is a NebularPool deployed by the canonical NebularFactory.
     * @param fee0 Amount of token0 that must be repaid as a fee.
     * @param fee1 Amount of token1 that must be repaid as a fee.
     * @param data Arbitrary data passed through from the original flash call.
     */
    function nebularFlashCallback(
        uint256 fee0,
        uint256 fee1,
        bytes calldata data
    ) external;
}
