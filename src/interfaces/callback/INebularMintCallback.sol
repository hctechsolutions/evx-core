// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Callback for INebularPoolActions#mint
/// @notice Any contract that calls INebularPoolActions#mint must implement this interface
interface INebularMintCallback {
    /// @notice Called to `msg.sender` after minting liquidity to a position from INebularPool#mint.
    /// @dev In the implementation you must pay the pool tokens owed for the minted liquidity.
    /// The caller of this method must be checked to be a NebularPool deployed by the canonical NebularFactory.
    /// @param amount0Owed The amount of token0 due to the pool for the minted liquidity
    /// @param amount1Owed The amount of token1 due to the pool for the minted liquidity
    /// @param data Any data passed through by the caller via the INebularPoolActions#mint call
    function nebularMintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata data
    ) external;
}
