// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@nebular/contracts/oracles/ChainLink.sol";
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/**
 * @title ChainlinkFeedMock
 * @notice Mock implementation of Chainlink's AggregatorV3Interface for testing purposes.
 */
contract ChainlinkFeedMock is AggregatorV3Interface {
    int256 private latestAnswer;
    uint80 private latestRoundId;
    uint256 private latestTimestamp;
    uint8 private feedDecimals;
    string private feedDescription;
    uint256 private feedVersion;

    /**
     * @notice Initializes the mock contract with an initial price and metadata.
     * @param _initialPrice The initial price to be returned by the mock.
     * @param _decimals The number of decimals the feed uses.
     * @param _description A string describing the feed (e.g., "ETH/USD").
     * @param _version The version number of the feed.
     */
    constructor(int256 _initialPrice, uint8 _decimals, string memory _description, uint256 _version) {
        latestAnswer = _initialPrice;
        latestRoundId = 1;
        latestTimestamp = block.timestamp;
        feedDecimals = _decimals;
        feedDescription = _description;
        feedVersion = _version;
    }

    /**
     * @notice Updates the latest price in the mock feed.
     * @param _newPrice The new price to be returned by the mock.
     */
    function setLatestAnswer(int256 _newPrice) external {
        latestAnswer = _newPrice;
        latestRoundId++;
        latestTimestamp = block.timestamp;
    }

    /**
     * @notice Returns the number of decimals the feed uses.
     * @return The number of decimals.
     */
    function decimals() external view override returns (uint8) {
        return feedDecimals;
    }

    /**
     * @notice Returns the description of the feed.
     * @return A string describing the feed.
     */
    function description() external view override returns (string memory) {
        return feedDescription;
    }

    /**
     * @notice Returns the version of the aggregator.
     * @return The version number.
     */
    function version() external view override returns (uint256) {
        return feedVersion;
    }

    /**
     * @notice Returns round data for a given round ID.
     * @param _roundId The round ID to fetch data for.
     * @return roundId The round ID.
     * @return answer The price for that round.
     * @return startedAt The timestamp when the round started.
     * @return updatedAt The timestamp when the round was last updated.
     * @return answeredInRound The round ID when the price was last updated.
     */
    function getRoundData(uint80 _roundId)
        external
        view
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        require(_roundId == latestRoundId, "Invalid round ID");
        return (latestRoundId, latestAnswer, latestTimestamp, latestTimestamp, latestRoundId);
    }

    /**
     * @notice Returns the latest round data in Chainlink's AggregatorV3Interface format.
     * @return roundId The round ID.
     * @return answer The latest price.
     * @return startedAt Timestamp when the round started.
     * @return updatedAt Timestamp when the round was last updated.
     * @return answeredInRound The round ID when the price was last updated.
     */
    function latestRoundData()
        external
        view
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (latestRoundId, latestAnswer, latestTimestamp, latestTimestamp, latestRoundId);
    }
}


/**
 * @title ChainlinkOracleTest
 * @notice Test suite for the ChainlinkOracle contract.
 */
contract ChainlinkTest is Test {
    ChainlinkOracle oracle;
    ChainlinkFeedMock chainlinkMock;

    /// @dev Initial mock price for Chainlink (scaled to 8 decimals as per Chainlink standard).
    int256 constant INITIAL_PRICE = 2000 * 10 ** 8;

    function setUp() public {
        // Deploy a mock Chainlink feed with an initial price
        chainlinkMock = new ChainlinkFeedMock(INITIAL_PRICE, 8, "ETH/USD", 1);

        // Deploy the oracle with the mock Chainlink feed
        oracle = new ChainlinkOracle(address(chainlinkMock));
    }

    /**
     * @notice Tests that the oracle retrieves the correct price from Chainlink.
     */
    function testGetPrice() public view {
        uint256 price = oracle.getPrice();
        uint256 expectedPrice = SafeMath.toWad(uint256(INITIAL_PRICE), 8);
        assertEq(price, expectedPrice, "Price should match the Chainlink feed");
    }

    /**
     * @notice Tests if the price updates correctly when the Chainlink feed changes.
     */
    function testPriceUpdate() public {
        int256 newPrice = 2200 * 10 ** 8;
        chainlinkMock.setLatestAnswer(newPrice);
        uint256 updatedPrice = oracle.getPrice();
        uint256 expectedPrice = SafeMath.toWad(uint256(newPrice), 8);
        assertEq(updatedPrice, expectedPrice, "Updated price should match the new Chainlink feed value");
    }

    /**
     * @notice Tests handling of a zero price from Chainlink feed.
     * @dev This should revert since a price of zero is invalid.
     */
    function testZeroPriceReverts() public {
        chainlinkMock.setLatestAnswer(0);
        vm.expectRevert("Invalid Chainlink price");
        oracle.getPrice();
    }

    /**
     * @notice Tests handling of a negative price from Chainlink feed.
     * @dev This should revert since negative prices are not valid in this context.
     */
    function testNegativePriceReverts() public {
        chainlinkMock.setLatestAnswer(-100 * 10 ** 8);
        vm.expectRevert("Invalid Chainlink price");
        oracle.getPrice();
    }
}
