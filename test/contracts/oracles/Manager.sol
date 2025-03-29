// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@nebular/contracts/oracles/Manager.sol";
import "forge-std/console.sol";

interface IOracleManagerEvents {
    event PriceUpdated(uint256 price, address source, uint256 timestamp);
    event FallbackUsed(address fallbackSource, uint256 timestamp);
}

contract MockUniswapOracle is IOracle {
    bool public shouldRevert;
    uint256 public mockPrice;
    
    function setPrice(uint256 price) external {
        mockPrice = price;
    }
    
    function setShouldRevert(bool revert_) external {
        shouldRevert = revert_;
    }
    
    function getPrice() external view returns (uint256) {
        require(!shouldRevert, "Uniswap Oracle Failed");
        return mockPrice;
    }
}

contract MockChainlinkOracle is IOracle {
    bool public shouldRevert;
    uint256 public mockPrice;
    
    function setPrice(uint256 price) external {
        mockPrice = price;
    }
    
    function setShouldRevert(bool revert_) external {
        shouldRevert = revert_;
    }
    
    function getPrice() external view returns (uint256) {
        require(!shouldRevert, "Chainlink Oracle Failed");
        return mockPrice;
    }
}

contract OracleManagerTest is Test, IOracleManagerEvents {
    OracleManager public manager;
    MockUniswapOracle public uniswapOracle;
    MockChainlinkOracle public chainlinkOracle;
    
    uint256 constant WAD = 1e18;
    uint256 constant MAX_SLIPPAGE = 0.05e18; // 5%

    function setUp() public {
        uniswapOracle = new MockUniswapOracle();
        chainlinkOracle = new MockChainlinkOracle();
        manager = new OracleManager(
            address(uniswapOracle),
            address(chainlinkOracle)
        );
    }

    /**
     * @notice Advances time and updates the price.
     * @dev This helper function ensures the update respects the required interval.
     */
    function _updatePriceWithDelay() internal {
        vm.warp(block.timestamp + 1 + manager.UPDATE_INTERVAL());
        manager.updatePrice();
    }

    /**
     * @notice Tests if Uniswap provides the first valid price.
     */
    function test_UniswapPriceFirst() public {
        uint256 testPrice = 1000e18;
        uniswapOracle.setPrice(testPrice);
        
        vm.expectEmit(true, true, true, true);
        emit PriceUpdated(testPrice, address(uniswapOracle), block.timestamp);
        
        manager.updatePrice();        
        assertEq(manager.lastValidPrice(), testPrice, "Incorrect price");

        (uint256 historyPrice, ) = manager.priceHistory(manager.PRICE_HISTORY_SIZE() - 1);
        assertEq(historyPrice, testPrice, "Incorrect history");
    }

    /**
     * @notice Tests fallback to Chainlink when Uniswap fails.
     */
    function test_ChainlinkFallback() public {
        uniswapOracle.setShouldRevert(true);
        chainlinkOracle.setPrice(1005e18);
        
        vm.expectEmit(true, true, true, true, address(manager));
        emit PriceUpdated(1005e18, address(chainlinkOracle), block.timestamp);
        
        manager.updatePrice();
    }

    /**
     * @notice Tests fallback to historical average when both oracles fail.
     */
    function test_HistoricalAverageFallback() public {
        uint256 sum;
        uint256 basePrice = 990e18;
        for (uint i = 0; i < manager.PRICE_HISTORY_SIZE(); i++) {
            uint256 price = basePrice + ((basePrice * 4) / 1000) * i;
            uniswapOracle.setPrice(price);
            manager.updatePrice();
            sum += price;
            vm.warp(block.timestamp + manager.UPDATE_INTERVAL());
        }
        
        uniswapOracle.setShouldRevert(true);
        chainlinkOracle.setShouldRevert(true);
        
        vm.expectEmit(true, true, true, true);
        emit FallbackUsed(address(manager), block.timestamp);

        manager.updatePrice();

        uint256 expectedAverage = sum / manager.PRICE_HISTORY_SIZE();
        assertEq(manager.lastValidPrice(), expectedAverage, "Incorrect historical average");
    }

    /**
     * @notice Tests that slippage protection works.
     */
    function test_SlippageProtection() public {
        uniswapOracle.setPrice(1000e18);
        manager.updatePrice();
        
        uniswapOracle.setPrice(1060e18);
        chainlinkOracle.setPrice(1005e18);
        
        _updatePriceWithDelay();
        
        assertEq(manager.lastValidPrice(), 1005e18, "Slippage not detected");
    }

    /**
     * @notice Tests that rapid updates fail.
     */
    function test_UpdateTooSoon() public {
        manager.updatePrice();
        
        vm.warp(block.timestamp + manager.UPDATE_INTERVAL());
        manager.updatePrice();
        
        vm.expectRevert("Update too soon");
        manager.updatePrice();
    }

    /**
     * @notice Tests that the price history maintains a fixed limit.
     */
    function test_PriceHistoryLimit() public {
        uniswapOracle.setShouldRevert(false);
        uint256 lastValid = 1e18;
        uniswapOracle.setPrice(lastValid);
        _updatePriceWithDelay();

        for (uint256 i = 1; i <= 12; i++) {
            uint256 newPrice = (lastValid * 105) / 100; 
            uniswapOracle.setPrice(newPrice);
            _updatePriceWithDelay();
            lastValid = newPrice;
        }

        assertEq(manager.priceHistoryLength(), 10, "History exceeds limit");
        assertEq(manager.lastValidPrice(), lastValid, "Incorrect latest data");
    }

    /**
     * @notice Tests that expired prices are ignored in the historical average.
     */
    function test_ExpiredPricesIgnored() public {
        for (uint i = 0; i < 5; i++) {
            uniswapOracle.setPrice(1000e18 + i * 1e18);
            manager.updatePrice();
            vm.warp(block.timestamp + manager.UPDATE_INTERVAL());
        }
        
        vm.warp(block.timestamp + 1 days + 1);
        
        uniswapOracle.setShouldRevert(true);
        chainlinkOracle.setShouldRevert(true);
        
        vm.expectRevert("No valid historical prices");
        manager.updatePrice();
    }

    /**
     * @notice Tests price updates with fuzzing.
     */
    function testFuzz_PriceUpdates(uint256 price) public {
        vm.assume(price > 0.1e18 && price < 1e30);
        
        uniswapOracle.setPrice(price);
        manager.updatePrice();
        
        assertEq(manager.lastValidPrice(), price, "Fuzzing failed");
    }
}
