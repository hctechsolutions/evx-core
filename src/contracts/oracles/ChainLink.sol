// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import "@nebular/lib/MathUtils.sol";

/**
 * @title ChainlinkOracle
 * @notice Provides price feeds from Chainlink oracles, ensuring price normalization to WAD (1e18).
 */
contract ChainlinkOracle {
    using MathUtils for uint256;

    /// @notice Chainlink price feed contract
    AggregatorV3Interface public immutable priceFeed;

    /// @notice Number of decimals provided by Chainlink price feed
    uint8 public immutable chainlinkDecimals;

    /**
     * @notice Initializes the Chainlink oracle with a given price feed.
     * @param _priceFeed Address of the Chainlink price feed contract.
     */
    constructor(address _priceFeed) {
        require(_priceFeed != address(0), "Invalid Chainlink feed address");
        priceFeed = AggregatorV3Interface(_priceFeed);
        chainlinkDecimals = priceFeed.decimals();
    }

    /**
     * @notice Fetches the latest price from the Chainlink oracle.
     * @dev Normalizes the price to WAD (1e18) precision.
     * @return price The latest price scaled to WAD.
     */
    function getPrice() external view returns (uint256 price) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        require(answer > 0, "Invalid Chainlink price");
        
        uint256 rawPrice = uint256(answer);
        return MathUtils.toWad(rawPrice, chainlinkDecimals);
    }
}
