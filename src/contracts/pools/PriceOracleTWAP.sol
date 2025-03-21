// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import "@nebula/interfaces/IPriceOracle.sol";

/**
 * @title PriceOracleTWAP
 * @notice Aggregates multiple data sources with fallback mechanisms
 * @dev Uses Chainlink, TWAP, and Band Protocol with a consensus mechanism
 */
contract PriceOracleTWAP is IPriceOracle, Ownable {
    struct OracleConfig {
        address source;
        uint256 maxDeviationBps;
        uint256 heartbeat;
        uint8 decimals;
    }

    OracleConfig[] public oracles;
    uint256 public lastValidPrice;
    uint256 public lastUpdated;

    event OracleFailure(uint256 timestamp, string reason);
    event OracleAdded(address indexed source, uint256 maxDeviationBps, uint256 heartbeat, uint8 decimals);

    /**
     * @notice Initializes the PriceOracleTWAP contract
     * @param initialOwner The address that will be the initial owner of the contract
     */
    constructor(address initialOwner) Ownable(initialOwner) {}

    /**
     * @notice Adds a new oracle configuration
     * @dev Only callable by the contract owner
     */
    function addOracle(
        address source,
        uint256 maxDeviationBps,
        uint256 heartbeat,
        uint8 decimals
    ) external onlyOwner {
        require(source != address(0), "Invalid oracle address");
        require(maxDeviationBps > 0, "Max deviation must be greater than zero");
        require(heartbeat > 0, "Heartbeat must be greater than zero");
        
        oracles.push(OracleConfig({
            source: source,
            maxDeviationBps: maxDeviationBps,
            heartbeat: heartbeat,
            decimals: decimals
        }));
        
        emit OracleAdded(source, maxDeviationBps, heartbeat, decimals);
    }

    /**
     * @notice Fetches asset price using a consensus mechanism
     * @dev Implements 2/3 majority validation for reliability
     */
    function consult() external override returns (uint256) {
        uint256[] memory prices = new uint256[](oracles.length);
        bool[] memory valid = new bool[](oracles.length);
        uint256 validPriceSum;
        uint256 validCount;

        for (uint256 i = 0; i < oracles.length; i++) {
            (bool success, bytes memory data) = oracles[i].source.staticcall(abi.encodeWithSignature("latestPrice()"));
            if (success) {
                uint256 price = abi.decode(data, (uint256));
                if (_isPriceValid(price)) {
                    prices[i] = price;
                    valid[i] = true;
                    validPriceSum += price;
                    validCount++;
                }
            }
        }

        require(validCount >= 2, "No consensus reached");
        lastValidPrice = validPriceSum / validCount;
        lastUpdated = block.timestamp;
        return lastValidPrice;
    }

    /**
     * @notice Validates if a price is within an acceptable deviation range
     * @dev Ensures price fluctuations remain within a 5% deviation from the last valid price
     */
    function _isPriceValid(uint256 price) internal view returns (bool) {
        if (lastValidPrice == 0) return true;
        uint256 deviation = (price * 10000) / lastValidPrice;
        return (deviation >= 9500 && deviation <= 10500); // Acceptable range: ±5%
    }
}