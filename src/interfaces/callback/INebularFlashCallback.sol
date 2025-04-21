// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Callback for INebularPoolActions#flash
/// @notice Any contract that calls INebularPoolActions#flash must implement this interface
interface INebularFlashCallback {
    /// @notice Called to `msg.sender` after transferring to the recipient from INebularPool#flash.
    /// @dev In the implementation you must repay the pool the tokens sent by flash plus the computed fee amounts.
    /// The caller of this method must be checked to be a NebularPool deployed by the canonical NebularFactory.
    /// @param fee0 The fee amount in token0 due to the pool by the end of the flash
    /// @param fee1 The fee amount in token1 due to the pool by the end of the flash
    /// @param data Any data passed through by the caller via the INebularPoolActions#flash call
    function nebularFlashCallback(
        uint256 fee0,
        uint256 fee1,
        bytes calldata data
    ) external;
}
