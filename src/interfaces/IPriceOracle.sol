// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Price Oracle Interface
 * @notice Provides asset price data with redundancy and validation
 */
interface IPriceOracle {
    /**
     * @notice Fetches the current price of the asset
     * @dev Implements multi-source consensus and fallback logic
     * @return price Normalized price (18 decimals)
     */
    function consult() external returns (uint256 price);

    /**
     * @notice Returns timestamp of last valid price update
     */
    function lastUpdated() external view returns (uint256);

    /**
     * @notice Event emitted when oracle consensus fails
     */
    event FallbackTriggered(string reason);
}
