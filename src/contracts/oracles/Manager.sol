// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@nebular/contracts/oracles/Uniswap.sol";
import "@nebular/contracts/oracles/ChainLink.sol";
import "forge-std/console.sol";

/**
 * @title OracleManager
 * @notice Manages price updates using Uniswap, Chainlink, and historical averages as fallback.
 * @dev Ensures that price updates follow a defined interval and slippage constraints.
 */
contract OracleManager {
    using MathUtils for uint256;
    
    // Configurations
    uint256 public constant MAX_SLIPPAGE = 5e16; // 5% (in WAD precision)
    uint32 public constant UPDATE_INTERVAL = 300; // 5 minutes
    uint256 public constant PRICE_HISTORY_SIZE = 10;
    
    // Dependencies
    UniswapOracle public immutable uniswapOracle;
    ChainlinkOracle public immutable chainlinkOracle;
    
    // State variables
    struct PriceData {
        uint256 price;
        uint256 timestamp;
    }
    
    uint256 private _historyIndex;
    PriceData[PRICE_HISTORY_SIZE] private _priceHistory;
    uint256 public lastValidPrice;
    uint256 public lastUpdate;
    
    event PriceUpdated(uint256 price, address source, uint256 timestamp);
    event FallbackUsed(address fallbackSource, uint256 timestamp);

    /**
     * @notice Initializes the OracleManager with Uniswap and Chainlink oracles.
     * @param _uniswapOracle Address of the Uniswap oracle contract.
     * @param _chainlinkOracle Address of the Chainlink oracle contract.
     */
    constructor(
        address _uniswapOracle,
        address _chainlinkOracle
    ) {
        uniswapOracle = UniswapOracle(_uniswapOracle);
        chainlinkOracle = ChainlinkOracle(_chainlinkOracle);
    }

    /**
     * @notice Attempts to update the price using Uniswap, Chainlink, or historical average fallback.
     * @dev Requires an update interval before fetching new prices.
     */
    function updatePrice() external {
        if (lastUpdate > 0) {
            require(block.timestamp - lastUpdate >= UPDATE_INTERVAL, "Update too soon");
        }
        
        uint256 currentPrice;
        bool priceValid;
        
        // Attempt 1: Uniswap TWAP
        (currentPrice, priceValid) = tryUniswapPrice();
        if (priceValid) {
            _updatePrice(currentPrice, address(uniswapOracle));
            return;
        }

        // Attempt 2: Chainlink
        (currentPrice, priceValid) = tryChainlinkPrice();
        if (priceValid) {
            _updatePrice(currentPrice, address(chainlinkOracle));
            return;
        }

        // Fallback: Historical Average
        currentPrice = calculateHistoricalAverage();
        
        _updatePrice(currentPrice, address(this));
        emit FallbackUsed(address(this), block.timestamp);
    }

    /**
     * @notice Returns the fixed size of the price history array.
     * @return PRICE_HISTORY_SIZE The maximum number of historical price records stored.
     */
    function priceHistoryLength() external pure returns (uint256) {
        return PRICE_HISTORY_SIZE;
    }

    /**
     * @notice Fetches a specific price history entry.
     * @param index Index of the historical price entry.
     * @return price The price recorded at the given index.
     * @return timestamp The timestamp of the recorded price.
     */
    function priceHistory(uint256 index) public view returns (uint256 price, uint256 timestamp) {
        require(index < PRICE_HISTORY_SIZE, "Index out of bounds");
        PriceData memory data = _priceHistory[index];
        return (data.price, data.timestamp);
    }

    /**
     * @notice Retrieves the latest valid price.
     * @return lastValidPrice The most recent valid price recorded.
     */
    function getPrice() external view returns (uint256) {
        require(lastValidPrice > 0, "No valid price available");
        return lastValidPrice;
    }

    /**
     * @notice Updates the last valid price and maintains a rolling price history.
     * @dev Shifts the historical prices left and inserts the new price at the last position.
     *      Emits the PriceUpdated event after updating the state.
     * @param newPrice The new valid price to be stored.
     * @param source The address of the price source (Uniswap, Chainlink, or fallback).
     */
    function _updatePrice(uint256 newPrice, address source) internal {
        lastValidPrice = newPrice;

        // Shift history to the left, removing the oldest price
        for (uint256 i = 0; i < PRICE_HISTORY_SIZE - 1; i++) {
            _priceHistory[i] = _priceHistory[i + 1];
        }

        // Insert the new price at the last position
        _priceHistory[PRICE_HISTORY_SIZE - 1] = PriceData(newPrice, lastUpdate);
        lastUpdate = block.timestamp;

        emit PriceUpdated(newPrice, source, lastUpdate);
    }

    function tryUniswapPrice() internal view returns (uint256, bool) {
        try uniswapOracle.getPrice() returns (uint256 price) {
            if (_isPriceValid(price, lastValidPrice)) {
                return (price, true);
            }
            return (0, false);
        } catch {
            return (0, false);
        }
    }

    /**
     * @notice Tries to fetch the latest price from Chainlink.
     * @return price The fetched price.
     * @return valid True if the price is within the allowed slippage range, false otherwise.
     */
    function tryChainlinkPrice() internal view returns (uint256, bool) {
        try chainlinkOracle.getPrice() returns (uint256 price) {
            if (_isPriceValid(price, lastValidPrice)) {
                return (price, true);
            }
            return (0, false);
        } catch {
            return (0, false);
        }
    }

    /**
     * @notice Validates whether the new price is within the allowed slippage range.
     * @param newPrice The new price being evaluated.
     * @param referencePrice The last valid price for comparison.
     * @return isValid True if the price is within the acceptable range, false otherwise.
     */
    function _isPriceValid(uint256 newPrice, uint256 referencePrice) internal pure returns (bool) {
        if (referencePrice == 0) return true; // First price is always valid
        uint256 diff = newPrice > referencePrice 
            ? newPrice - referencePrice 
            : referencePrice - newPrice;
        return (diff * MathUtils.WAD) / referencePrice <= MAX_SLIPPAGE;
    }

    /**
     * @notice Calculates the historical average price from valid recent entries.
     * @return average The computed average price based on historical data.
     */
    function calculateHistoricalAverage() internal view returns (uint256) {
        require(_priceHistory.length > 0, "No historical data");
        
        uint256 sum;
        uint256 validCount;
        for (uint i = 0; i < PRICE_HISTORY_SIZE; i++) {
            if (block.timestamp - _priceHistory[i].timestamp <= 1 days) {
                sum += _priceHistory[i].price;
                validCount++;
            }
        }

        require(validCount > 0, "No valid historical prices");
        return sum / validCount;
    }
}
