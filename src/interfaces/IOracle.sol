// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

/**
 * @title IOracle
 * @notice Interface for an oracle that provides asset price information.
 */
interface IOracle {
    /**
     * @notice Returns the latest price from the oracle.
     * @dev The price is expected to be normalized to 18 decimals (WAD precision).
     * @return price The latest asset price in WAD format.
     */
    function getPrice() external view returns (uint256 price);
}