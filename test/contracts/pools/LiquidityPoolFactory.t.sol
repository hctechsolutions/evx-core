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


contract MockAggregatorV3 {
    function decimals() external view returns (uint8) {
        return 8;
    }
    
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

contract MockUniswapV3Pool  {
    address public token0;
    address public token1;
    uint160 public sqrtPriceX96 = 79228162514264337593543950336; // Corresponds to price of 1.0
    
    constructor(address _token0, address _token1) {
        token0 = _token0;
        token1 = _token1;
    }
    
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

contract MockERC20 {
    function decimals() external pure returns (uint8) { return 18; }
}


contract LiquidityPoolFactoryTest is Test {
    LiquidityPoolFactory public factory;
    MockAggregatorV3 public chainlinkFeed;
    MockUniswapV3Pool public uniswapPool;
    
    // Dummy tokens
    address public tokenA;
    address public tokenB;
    address public tokenC;
    address public tokenD;
    
    event LiquidityPoolCreated(address indexed pool, address token0, address token1);

    function setUp() public {
        // Setup mock tokens
        tokenA = address(new MockERC20());
        tokenB = address(new MockERC20());
        tokenC = address(new MockERC20());
        tokenD = address(new MockERC20());
        
        // Setup oracles
        chainlinkFeed = new MockAggregatorV3();
        uniswapPool = new MockUniswapV3Pool(tokenA, tokenB);
        
        factory = new LiquidityPoolFactory();
    }

    // ========== TESTES DE CRIAÇÃO ==========

    function testcreateLiquidityPoolSuccess() public {
        vm.expectEmit(false, true, true, true);
        emit LiquidityPoolCreated(address(0), tokenA, tokenB);

        LiquidityPool pool = factory.createLiquidityPool(
            tokenA, 
            tokenB, 
            address(chainlinkFeed), 
            address(uniswapPool)
        );

        // Verify pool creation
        assertEq(address(factory.getPool(tokenA, tokenB)), address(pool));
        assertEq(factory.getLiquidityPoolCount(), 1);
        
        // Verify pool parameters
        assertEq(pool.token0(), tokenA);
        assertEq(pool.token1(), tokenB);
    }

    // ========== TESTES DE VALIDAÇÃO ==========

    function testcreateLiquidityPoolRevertIfToken0IsZero() public {
        vm.expectRevert(LiquidityPoolFactory.InvalidTokenAddresses.selector);
        factory.createLiquidityPool(address(0), tokenB, address(chainlinkFeed), address(uniswapPool));
    }

    function testCreateLiquidityPoolRevertIf_token1IsZero() public {
        vm.expectRevert(LiquidityPoolFactory.InvalidTokenAddresses.selector);
        factory.createLiquidityPool(tokenA, address(0), address(chainlinkFeed), address(uniswapPool));
    }

    function testCreateLiquidityPoolRevertIf_identicalTokens() public {
        vm.expectRevert(LiquidityPoolFactory.IdenticalTokens.selector);
        factory.createLiquidityPool(tokenA, tokenA, address(chainlinkFeed), address(uniswapPool));
    }

    function testcreateLiquidityPoolRevertIfInvalidChainlinkFeed() public {
        vm.expectRevert(LiquidityPoolFactory.InvalidChainlinkFeed.selector);
        factory.createLiquidityPool(tokenA, tokenB, address(0), address(uniswapPool));
    }

    function testCreateLiquidityPoolRevertIf_invalidUniswapPool() public {
        vm.expectRevert(LiquidityPoolFactory.InvalidUniswapPool.selector);
        factory.createLiquidityPool(tokenA, tokenB, address(chainlinkFeed), address(0));
    }

    function testCreateLiquidityPoolRevertIfPoolAlreadyExists() public {
        factory.createLiquidityPool(tokenA, tokenB, address(chainlinkFeed), address(uniswapPool));
        vm.expectRevert(LiquidityPoolFactory.PoolAlreadyExists.selector);
        factory.createLiquidityPool(tokenA, tokenB, address(chainlinkFeed), address(uniswapPool));
    }


    // ========== TESTES DE ORACLE ==========

    function testoracleInitialization() public {
        LiquidityPool pool = factory.createLiquidityPool(
            tokenA, 
            tokenB, 
            address(chainlinkFeed), 
            address(uniswapPool)
        );
        
        // Verify oracle chain was created correctly
        IOracle nebularOracle = pool.oracle();
        
        // In a real test, you would verify the oracle chain structure
        assertTrue(address(nebularOracle) != address(0));
    }

    // ========== TESTES ADICIONAIS ==========

    function testpoolExists() public {
        assertFalse(factory.poolExists(tokenA, tokenB));
        
        LiquidityPool pool = factory.createLiquidityPool(
            tokenA, 
            tokenB, 
            address(chainlinkFeed), 
            address(uniswapPool)
        );
        
        assertTrue(factory.poolExists(tokenA, tokenB));
        assertTrue(factory.poolExists(tokenB, tokenA)); // Should work bidirectionally
    }

    function testmultiplePoolCreation() public {
        factory.createLiquidityPool(tokenA, tokenB, address(chainlinkFeed), address(uniswapPool));
        factory.createLiquidityPool(tokenA, tokenC, address(chainlinkFeed), address(new MockUniswapV3Pool(tokenA, tokenC)));
        
        assertEq(factory.getLiquidityPoolCount(), 2);
        assertTrue(factory.poolExists(tokenA, tokenB));
        assertTrue(factory.poolExists(tokenA, tokenC));
    }

    function testCompleteIntegration() public {
        // Cria primeiro pool
        LiquidityPool poolAB = factory.createLiquidityPool(
            tokenA, 
            tokenB, 
            address(chainlinkFeed), 
            address(uniswapPool)
        );
    
        // Verifica estado
        assertEq(factory.getLiquidityPoolCount(), 1);
        assertTrue(factory.poolExists(tokenA, tokenB));
        assertEq(address(factory.getPool(tokenA, tokenB)), address(poolAB));
    
        // Tenta criar pool duplicado
        vm.expectRevert(LiquidityPoolFactory.PoolAlreadyExists.selector);
        factory.createLiquidityPool(tokenB, tokenA, address(chainlinkFeed), address(uniswapPool));
    
        // Cria segundo pool
        LiquidityPool poolAC = factory.createLiquidityPool(
            tokenA, 
            tokenC, 
            address(chainlinkFeed), 
            address(uniswapPool)
        );
    
        // Verifica estado atualizado
        assertEq(factory.getLiquidityPoolCount(), 2);
        assertTrue(factory.poolExists(tokenA, tokenC));
        assertFalse(factory.poolExists(tokenB, tokenC));
    
        // Verifica parâmetros
        assertEq(poolAB.token0(), tokenA);
        assertEq(poolAB.token1(), tokenB);
        assertEq(poolAC.token0(), tokenA);
        assertEq(poolAC.token1(), tokenC);
    
        // Cria terceiro pool com novo par
        LiquidityPool poolCD = factory.createLiquidityPool(
            tokenC, 
            tokenD, 
            address(chainlinkFeed), 
            address(uniswapPool)
        );
    
        assertEq(factory.getLiquidityPoolCount(), 3);
        assertTrue(factory.poolExists(tokenC, tokenD));
    }
}
