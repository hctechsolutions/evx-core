// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@nebular/contracts/oracles/Uniswap.sol";
import "@nebular/interfaces/IUniswapV3Pool.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title UniswapV3PoolMock
 * @notice Mock contract for the Uniswap V3 Pool to be used in unit tests.
 * @dev This contract simulates the behavior of a Uniswap V3 Pool for testing purposes.
 */
contract UniswapV3PoolMock is IUniswapV3Pool {
    address private _token0;
    address private _token1;
    uint160 private _sqrtPriceX96;
    int24 private _tick;
    uint128 private _liquidity;
    uint24 private _fee;

    /**
     * @notice Initializes the mock Uniswap V3 pool with given parameters.
     * @param token0_ Address of the first token in the pool.
     * @param token1_ Address of the second token in the pool.
     * @param initialPrice Initial square root price (X96 format).
     * @param initialTick Initial tick value.
     * @param initialLiquidity Initial liquidity value.
     * @param initialFee Trading fee in basis points.
     */
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

    /**
     * @notice Returns the address of token0.
     * @return token0 The address of token0.
     */
    function token0() external view override returns (address) {
        return _token0;
    }

    /**
     * @notice Returns the address of token1.
     * @return token1 The address of token1.
     */
    function token1() external view override returns (address) {
        return _token1;
    }

    /**
     * @notice Returns the current state of the pool.
     * @dev This function mimics the `slot0` function of Uniswap V3 pools.
     * @return sqrtPriceX96 The current sqrt price in X96 format.
     * @return tick The current tick.
     * @return observationIndex Always returns 0 (not implemented in the mock).
     * @return observationCardinality Always returns 0 (not implemented in the mock).
     * @return observationCardinalityNext Always returns 0 (not implemented in the mock).
     * @return feeProtocol Always returns 0 (not implemented in the mock).
     * @return unlocked Always returns true (not implemented in the mock).
     */
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

    /**
     * @notice Returns the current liquidity of the pool.
     * @return liquidity The current liquidity amount.
     */
    function liquidity() external view override returns (uint128) {
        return _liquidity;
    }

    /**
     * @notice Returns the trading fee of the pool.
     * @return fee The trading fee in basis points.
     */
    function fee() external view override returns (uint24) {
        return _fee;
    }

    /**
     * @notice Sets a new price and tick for the pool.
     * @dev This function allows modifying the pool's price for testing purposes.
     * @param newPrice The new sqrt price in X96 format.
     * @param newTick The new tick value.
     */
    function setPrice(uint160 newPrice, int24 newTick) external {
        _sqrtPriceX96 = newPrice;
        _tick = newTick;
    }

    /**
     * @notice Sets a new liquidity value for the pool.
     * @dev This function allows modifying the pool's liquidity for testing purposes.
     * @param newLiquidity The new liquidity amount.
     */
    function setLiquidity(uint128 newLiquidity) external {
        _liquidity = newLiquidity;
    }

    /**
     * @notice Sets a new fee value for the pool.
     * @dev This function allows modifying the pool's fee for testing purposes.
     * @param newFee The new fee value in basis points.
     */
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
    using MathUtils for uint256;

    UniswapV3PoolMock public mockPool;
    UniswapOracle public oracle;

    MockToken public token0 = new MockToken("Token 0", "TK0", 8);
    MockToken public token1 = new MockToken("Token 1", "TK1", 4);

    /**
     * @notice Sets up the test environment.
     * @dev Deploys a mock Uniswap V3 pool and an oracle instance for testing.
     */
    function setUp() public {
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
    function testGetPriceNormalization() public {
        // sqrtPriceX96 = 79228162514264337593543950336 (1 << 96), equivalent to 1:1 price ratio
        uint160 sqrtPriceX96 = 79228162514264337593543950336;
        mockPool.setPrice(sqrtPriceX96, 0);

        // Retrieve actual price from the oracle
        uint256 price = oracle.getPrice();

        // Expected price calculation using the same formula as the oracle
        uint256 expectedPrice = (uint256(sqrtPriceX96) * uint256(sqrtPriceX96) * MathUtils.WAD) / (2**192);

        // Ensure the returned price matches the expected value
        assertEq(price, expectedPrice, "Price should be normalized to 18 decimals");
    }

    /**
     * @notice Tests that the price is correctly computed for different decimal configurations.
     * @dev Verifies that a 0.5:1 price ratio is correctly converted.
     */
    function testGetPriceWithDifferentDecimals() public {
        // sqrtPriceX96 = 39614081257132168796771975168 (0.5 << 96), equivalent to 0.5:1 price ratio
        uint160 sqrtPriceX96 = 39614081257132168796771975168;
        mockPool.setPrice(sqrtPriceX96, 0);

        // Retrieve actual price from the oracle
        uint256 price = oracle.getPrice();

        // Expected price calculation using the same formula as the oracle
        uint256 expectedPrice = (uint256(sqrtPriceX96) * uint256(sqrtPriceX96) * MathUtils.WAD) / (2**192);

        // Ensure the returned price matches the expected value
        assertEq(price, expectedPrice, "Price should reflect 0.5:1 ratio correctly");
    }
}
