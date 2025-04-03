// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@nebular/contracts/oracles/Uniswap.sol";
import "@nebular/interfaces/IUniswapV3Pool.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@nebular/lib/SafeMath.sol";

/**
 * @title UniswapV3PoolMock
 * @notice Mock contract for Uniswap V3 Pool used in unit tests.
 * @dev Simulates basic Uniswap V3 Pool behavior.
 */
contract UniswapV3PoolMock is IUniswapV3Pool {
    address private _token0;
    address private _token1;
    uint160 private _sqrtPriceX96;
    int24 private _tick;
    uint128 private _liquidity;
    uint24 private _fee;

    constructor(
        address token0_,
        address token1_,
        uint160 initialPrice,
        int24 initialTick,
        uint128 initialLiquidity,
        uint24 initialFee
    ) {
        _token0 = token0_;
        _token1 = token1_;
        _sqrtPriceX96 = initialPrice;
        _tick = initialTick;
        _liquidity = initialLiquidity;
        _fee = initialFee;
    }

    function token0() external view override returns (address) {
        return _token0;
    }

    function token1() external view override returns (address) {
        return _token1;
    }

    function slot0()
        external
        view
        override
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        )
    {
        return (_sqrtPriceX96, _tick, 0, 0, 0, 0, true);
    }

    function liquidity() external view override returns (uint128) {
        return _liquidity;
    }

    function fee() external view override returns (uint24) {
        return _fee;
    }

    function observe(uint32[] calldata secondsAgos)
        external
        view
        override
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128)
    {
        tickCumulatives = new int56[](secondsAgos.length);
        secondsPerLiquidityCumulativeX128 = new uint160[](secondsAgos.length);
        
        for (uint256 i = 0; i < secondsAgos.length; i++) {
            tickCumulatives[i] = int56(_tick) * int56(int32(secondsAgos[i]));
            secondsPerLiquidityCumulativeX128[i] = 0;
        }
    }

    function setPrice(uint160 newPrice, int24 newTick) external {
        _sqrtPriceX96 = newPrice;
        _tick = newTick;
    }

    function setLiquidity(uint128 newLiquidity) external {
        _liquidity = newLiquidity;
    }

    function setFee(uint24 newFee) external {
        _fee = newFee;
    }
}

/**
 * @title MockToken
 * @notice Mock ERC20 token for testing purposes.
 */
contract MockToken is ERC20 {
    uint8 private _decimals;

    constructor(string memory _name, string memory _symbol, uint8 decimals_) ERC20(_name, _symbol) {
        _decimals = decimals_;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}

/**
 * @title UniswapOracleTest
 * @notice Unit tests for UniswapOracle using Foundry.
 * @dev This contract contains unit tests to verify the accuracy and normalization of prices retrieved from UniswapOracle.
 */
contract UniswapOracleTest is Test {
    using SafeMath for uint256;

    UniswapV3PoolMock public mockPool;
    UniswapOracle public oracle;

    MockToken public token0;
    MockToken public token1;

    /**
     * @notice Sets up the test environment.
     * @dev Deploys mock tokens, a Uniswap V3 pool mock, and an oracle instance for testing.
     */
    function setUp() public {
        token0 = new MockToken("Token 0", "TK0", 8);
        token1 = new MockToken("Token 1", "TK1", 6);

        mockPool = new UniswapV3PoolMock(
            address(token0),
            address(token1),
            79228162514264337593543950336, // sqrtPriceX96 (~100)
            100,
            1000000,
            3000
        );

        oracle = new UniswapOracle(address(mockPool));
    }

    /**
     * @notice Tests that the price normalization works correctly.
     * @dev Verifies that a 1:1 price ratio is correctly normalized to 18 decimals (WAD format).
     */
    function test_GetPrice_Normalization() public {
        uint160 sqrtPriceX96 = 79228162514264337593543950336; // 1 << 96, equivale a preço 1:1
        mockPool.setPrice(sqrtPriceX96, 0);

        uint256 price = oracle.getPrice();
        uint256 expectedPrice = (uint256(sqrtPriceX96) * uint256(sqrtPriceX96) * SafeMath.WAD) / (2**192);

        assertEq(price, expectedPrice, "Price should be normalized to 18 decimals");
    }

    /**
     * @notice Tests that the price is correctly computed for different decimal configurations.
     * @dev Verifies that a 0.5:1 price ratio is correctly converted.
     */
    function test_GetPrice_WithDifferentDecimals() public {
        uint160 sqrtPriceX96 = 39614081257132168796771975168; // sqrt(0.5) << 96
        mockPool.setPrice(sqrtPriceX96, 0);

        uint256 price = oracle.getPrice();
        uint256 expectedPrice = (uint256(sqrtPriceX96) * uint256(sqrtPriceX96) * SafeMath.WAD) / (2**192);

        assertEq(price, expectedPrice, "Price should reflect 0.5:1 ratio correctly");
    }

    /**
     * @notice Tests if the oracle correctly updates when the pool price changes.
     */
    function test_GetPrice_UpdatesOnNewPoolPrice() public {
        uint160 initialPrice = 79228162514264337593543950336; // sqrt(1) << 96
        mockPool.setPrice(initialPrice, 0);

        uint256 initialOraclePrice = oracle.getPrice();
        assertGt(initialOraclePrice, 0, "Initial price should be valid");

        uint160 newPrice = 11180339887498948482045800906; // sqrt(0.25) << 96
        mockPool.setPrice(newPrice, 0);

        uint256 updatedOraclePrice = oracle.getPrice();
        uint256 expectedUpdatedPrice = (uint256(newPrice) * uint256(newPrice) * SafeMath.WAD) / (2**192);

        assertEq(updatedOraclePrice, expectedUpdatedPrice, "Updated price should be correct");
    }

    /**
     * @notice Tests if the oracle correctly retrieves the price for a higher value asset.
     */
    function test_GetPrice_HighValueAsset() public {
        uint160 highPrice = 15874010519681947723869928283; // sqrt(2) << 96
        mockPool.setPrice(highPrice, 0);

        uint256 price = oracle.getPrice();
        uint256 expectedPrice = (uint256(highPrice) * uint256(highPrice) * SafeMath.WAD) / (2**192);

        assertEq(price, expectedPrice, "Price should match for high-value assets");
    }
}
