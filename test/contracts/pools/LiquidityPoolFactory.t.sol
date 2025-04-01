// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@nebular/contracts/pools/LiquidityPoolFactory.sol";
import "@nebular/contracts/pools/LiquidityPool.sol";
import "@nebular/contracts/oracles/ChainLink.sol";
import "@nebular/contracts/oracles/Uniswap.sol";
import "@nebular/contracts/oracles/Nebular.sol";
import "@nebular/interfaces/IOracle.sol";

/**
 * @title MockAggregatorV3
 * @notice Mock implementation of Chainlink's AggregatorV3Interface for testing
 * @dev Provides mock price feed data with configurable decimals
 */
contract MockAggregatorV3 {
    /**
     * @notice Returns the number of decimals in the price feed
     * @return uint8 Number of decimals (set to 8)
     */
    function decimals() external pure returns (uint8) {
        return 8;
    }
    
    /**
     * @notice Provides mock latest round data
     * @return roundId Mock round ID
     * @return answer Mock price (1e18)
     * @return startedAt Timestamp when round started
     * @return updatedAt Current block timestamp
     * @return answeredInRound Round ID in which answer was computed
     */
    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        return (0, 1e18, 0, block.timestamp, 0);
    }
}

/**
 * @title MockUniswapV3Pool
 * @notice Mock implementation of Uniswap V3 pool for testing
 * @dev Simulates basic pool functionality including slot0 data
 */
contract MockUniswapV3Pool {
    address public token0;
    address public token1;
    uint160 public sqrtPriceX96 = 79228162514264337593543950336; // Corresponds to price of 1.0
    
    /**
     * @notice Initializes the mock pool with token addresses
     * @param _token0 Address of first token in pair
     * @param _token1 Address of second token in pair
     */
    constructor(address _token0, address _token1) {
        token0 = _token0;
        token1 = _token1;
    }
    
    /**
     * @notice Returns mock pool state data
     * @return sqrtPriceX96_ The sqrt(price) of the pool as a Q64.96
     * @return tick The current tick of the pool
     * @return observationIndex The index of the last oracle observation
     * @return observationCardinality The current maximum number of observations stored
     * @return observationCardinalityNext The next maximum number of observations to store
     * @return feeProtocol The protocol fee for both tokens of the pool
     * @return unlocked Whether the pool is currently locked
     */
    function slot0() external view returns (
        uint160 sqrtPriceX96_,
        int24 tick,
        uint16 observationIndex,
        uint16 observationCardinality,
        uint16 observationCardinalityNext,
        uint8 feeProtocol,
        bool unlocked
    ) {
        return (sqrtPriceX96, 0, 0, 0, 0, 0, true);
    }
}

/**
 * @title MockERC20
 * @notice Minimal ERC20 mock for testing token interactions
 */
contract MockERC20 {
    /**
     * @notice Returns the number of decimals for the token
     * @return uint8 Always returns 18 decimals
     */
    function decimals() external pure returns (uint8) { return 18; }
}

/**
 * @title LiquidityPoolFactoryTest
 * @notice Comprehensive test suite for LiquidityPoolFactory contract
 * @dev Tests all major functionality including pool creation, validation, and oracle integration
 */
contract LiquidityPoolFactoryTest is Test {
    LiquidityPoolFactory public factory;
    MockAggregatorV3 public chainlinkFeed;
    MockUniswapV3Pool public uniswapPool;
    
    // Test token addresses
    address public tokenA;
    address public tokenB;
    address public tokenC;
    address public tokenD;
    
    /**
     * @notice Event emitted when a new liquidity pool is created
     * @param pool Address of the created pool
     * @param token0 First token in the pair
     * @param token1 Second token in the pair
     */
    event LiquidityPoolCreated(address indexed pool, address token0, address token1);

    /**
     * @notice Sets up the test environment before each test
     * @dev Deploys mock tokens, oracles and the factory contract
     */
    function setUp() public {
        // Deploy mock tokens
        tokenA = address(new MockERC20());
        tokenB = address(new MockERC20());
        tokenC = address(new MockERC20());
        tokenD = address(new MockERC20());
        
        // Deploy mock oracles
        chainlinkFeed = new MockAggregatorV3();
        uniswapPool = new MockUniswapV3Pool(tokenA, tokenB);
        
        // Deploy factory contract
        factory = new LiquidityPoolFactory();
    }

    /**
     * @notice Tests successful pool creation
     * @dev Verifies event emission and proper pool registration
     */
    function testCreateLiquidityPoolSuccess() public {
        // Expect pool creation event
        vm.expectEmit(false, true, true, true);
        emit LiquidityPoolCreated(address(0), tokenA, tokenB);

        LiquidityPool pool = factory.createLiquidityPool(
            tokenA, 
            tokenB, 
            address(chainlinkFeed), 
            address(uniswapPool)
        );

        // Verify pool registration
        assertEq(address(factory.getPool(tokenA, tokenB)), address(pool));
        assertEq(factory.getLiquidityPoolCount(), 1);
        
        // Verify pool parameters
        assertEq(pool.token0(), tokenA);
        assertEq(pool.token1(), tokenB);
    }

    /**
     * @notice Tests validation for zero address token0
     * @dev Expects revert with InvalidTokenAddresses error
     */
    function testRevertWhenToken0IsZero() public {
        vm.expectRevert(LiquidityPoolFactory.InvalidTokenAddresses.selector);
        factory.createLiquidityPool(address(0), tokenB, address(chainlinkFeed), address(uniswapPool));
    }

    /**
     * @notice Tests validation for zero address token1
     * @dev Expects revert with InvalidTokenAddresses error
     */
    function testRevertWhenToken1IsZero() public {
        vm.expectRevert(LiquidityPoolFactory.InvalidTokenAddresses.selector);
        factory.createLiquidityPool(tokenA, address(0), address(chainlinkFeed), address(uniswapPool));
    }

    /**
     * @notice Tests validation for identical tokens
     * @dev Expects revert with IdenticalTokens error
     */
    function testRevertWhenIdenticalTokens() public {
        vm.expectRevert(LiquidityPoolFactory.IdenticalTokens.selector);
        factory.createLiquidityPool(tokenA, tokenA, address(chainlinkFeed), address(uniswapPool));
    }

    /**
     * @notice Tests validation for invalid Chainlink feed
     * @dev Expects revert with InvalidChainlinkFeed error
     */
    function testRevertWhenInvalidChainlinkFeed() public {
        vm.expectRevert(LiquidityPoolFactory.InvalidChainlinkFeed.selector);
        factory.createLiquidityPool(tokenA, tokenB, address(0), address(uniswapPool));
    }

    /**
     * @notice Tests validation for invalid Uniswap pool
     * @dev Expects revert with InvalidUniswapPool error
     */
    function testRevertWhenInvalidUniswapPool() public {
        vm.expectRevert(LiquidityPoolFactory.InvalidUniswapPool.selector);
        factory.createLiquidityPool(tokenA, tokenB, address(chainlinkFeed), address(0));
    }

    /**
     * @notice Tests prevention of duplicate pool creation
     * @dev Expects revert with PoolAlreadyExists error
     */
    function testRevertWhenPoolAlreadyExists() public {
        factory.createLiquidityPool(tokenA, tokenB, address(chainlinkFeed), address(uniswapPool));
        vm.expectRevert(LiquidityPoolFactory.PoolAlreadyExists.selector);
        factory.createLiquidityPool(tokenA, tokenB, address(chainlinkFeed), address(uniswapPool));
    }

    /**
     * @notice Tests proper oracle initialization
     * @dev Verifies oracle address is set after pool creation
     */
    function testOracleInitialization() public {
        LiquidityPool pool = factory.createLiquidityPool(
            tokenA, 
            tokenB, 
            address(chainlinkFeed), 
            address(uniswapPool)
        );
        
        // Verify oracle address is set
        assertTrue(address(pool.oracle()) != address(0));
    }

    /**
     * @notice Tests pool existence check functionality
     * @dev Verifies poolExists works bidirectionally
     */
    function testPoolExists() public {
        assertFalse(factory.poolExists(tokenA, tokenB));
        
        factory.createLiquidityPool(
            tokenA, 
            tokenB, 
            address(chainlinkFeed), 
            address(uniswapPool)
        );
        
        assertTrue(factory.poolExists(tokenA, tokenB));
        assertTrue(factory.poolExists(tokenB, tokenA)); // Bidirectional check
    }

    /**
     * @notice Tests multiple pool creation
     * @dev Verifies proper counting and registration of multiple pools
     */
    function testMultiplePoolCreation() public {
        factory.createLiquidityPool(tokenA, tokenB, address(chainlinkFeed), address(uniswapPool));
        factory.createLiquidityPool(tokenA, tokenC, address(chainlinkFeed), address(new MockUniswapV3Pool(tokenA, tokenC)));
        
        assertEq(factory.getLiquidityPoolCount(), 2);
        assertTrue(factory.poolExists(tokenA, tokenB));
        assertTrue(factory.poolExists(tokenA, tokenC));
    }

    /**
     * @notice Comprehensive integration test
     * @dev Tests complete workflow including duplicate prevention and parameter verification
     */
    function testCompleteIntegration() public {
        // Create first pool
        LiquidityPool poolAB = factory.createLiquidityPool(
            tokenA, 
            tokenB, 
            address(chainlinkFeed), 
            address(uniswapPool)
        );
    
        // Verify state
        assertEq(factory.getLiquidityPoolCount(), 1);
        assertTrue(factory.poolExists(tokenA, tokenB));
        assertEq(address(factory.getPool(tokenA, tokenB)), address(poolAB));
    
        // Test duplicate prevention
        vm.expectRevert(LiquidityPoolFactory.PoolAlreadyExists.selector);
        factory.createLiquidityPool(tokenB, tokenA, address(chainlinkFeed), address(uniswapPool));
    
        // Create second pool
        LiquidityPool poolAC = factory.createLiquidityPool(
            tokenA, 
            tokenC, 
            address(chainlinkFeed), 
            address(uniswapPool)
        );
    
        // Verify updated state
        assertEq(factory.getLiquidityPoolCount(), 2);
        assertTrue(factory.poolExists(tokenA, tokenC));
        assertFalse(factory.poolExists(tokenB, tokenC));
    
        // Verify parameters
        assertEq(poolAB.token0(), tokenA);
        assertEq(poolAB.token1(), tokenB);
        assertEq(poolAC.token0(), tokenA);
        assertEq(poolAC.token1(), tokenC);
    
        // Create third pool with new pair
        factory.createLiquidityPool(
            tokenC, 
            tokenD, 
            address(chainlinkFeed), 
            address(uniswapPool)
        );
    
        assertEq(factory.getLiquidityPoolCount(), 3);
        assertTrue(factory.poolExists(tokenC, tokenD));
    }
}