// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { LiquidityPool } from "@nebular/contracts/pools/LiquidityPool.sol";
import { ChainlinkOracle } from "@nebular/contracts/oracles/ChainLink.sol";
import { UniswapOracle } from "@nebular/contracts/oracles/Uniswap.sol";
import { NebularOracle } from "@nebular/contracts/oracles/Nebular.sol";
import { IOracle } from "@nebular/interfaces/IOracle.sol";

/**
 * @title LiquidityPoolFactory
 * @notice Factory contract for creating and managing LiquidityPool instances
 * @dev Handles the creation of liquidity pools with integrated oracle support
 */
contract LiquidityPoolFactory {
    /// @notice Error thrown when token addresses are invalid (zero address)
    error InvalidTokenAddresses();
    
    /// @notice Error thrown when both tokens in a pair are identical
    error IdenticalTokens();
    
    /// @notice Error thrown when Chainlink price feed address is invalid
    error InvalidChainlinkFeed();
    
    /// @notice Error thrown when Uniswap pool address is invalid
    error InvalidUniswapPool();
    
    /// @notice Error thrown when attempting to create an existing pool
    error PoolAlreadyExists();
    
    /// @notice Error thrown when Chainlink oracle creation fails
    error ChainlinkOracleCreationFailed();
    
    /// @notice Error thrown when Uniswap oracle creation fails
    error UniswapOracleCreationFailed();
    
    /// @notice Array of all created liquidity pools
    LiquidityPool[] public liquidityPools;
    
    /// @notice Mapping from token pairs to their respective pool addresses
    mapping(address => mapping(address => address)) public getPool;

    /**
     * @notice Emitted when a new liquidity pool is created
     * @param pool The address of the newly created pool
     * @param token0 The first token in the pair
     * @param token1 The second token in the pair
     */
    event LiquidityPoolCreated(address indexed pool, address token0, address token1);

    /**
     * @notice Creates a new LiquidityPool with oracle support
     * @dev Deploys a complete oracle stack (Chainlink -> Uniswap -> Nebular fallback)
     * @param _token0 First token in the pair
     * @param _token1 Second token in the pair
     * @param _chainLinkPriceFeed Chainlink price feed address
     * @param _uniSwapPoolAddress Uniswap V3 pool address
     * @return pool The created LiquidityPool instance
     * 
     * @custom:validation 
     * - Ensures token addresses are valid (non-zero)
     * - Ensures tokens are different
     * - Validates oracle addresses
     * - Checks for existing pools
     * 
     * @custom:oracle-stack
     * 1. ChainlinkOracle: Primary price source
     * 2. UniswapOracle: Secondary price source
     * 3. TWAP: Fallback mechanism
     */
    function createLiquidityPool(
        address _token0, 
        address _token1, 
        address _chainLinkPriceFeed,
        address _uniSwapPoolAddress
    ) external returns (LiquidityPool pool) {
        // Input validations
        if (_token0 == address(0) || _token1 == address(0)) {
            revert InvalidTokenAddresses();
        }
        if (_token0 == _token1) {
            revert IdenticalTokens();
        }
        if (_chainLinkPriceFeed == address(0)) {
            revert InvalidChainlinkFeed();
        }
        if (_uniSwapPoolAddress == address(0)) {
            revert InvalidUniswapPool();
        }
        if (getPool[_token0][_token1] != address(0)) {
            revert PoolAlreadyExists();
        }

        // Oracle deployment with fallback handling
        address chainLinkOracle;
        address uniswapOracle;
        IOracle nebularOracle;
        
        try new ChainlinkOracle(_chainLinkPriceFeed) returns (ChainlinkOracle createdOracle) {
            chainLinkOracle = address(createdOracle);
        } catch {
            revert ChainlinkOracleCreationFailed();
        }
        
        try new UniswapOracle(_uniSwapPoolAddress) returns (UniswapOracle createdOracle) {
            uniswapOracle = address(createdOracle);
        } catch {
            revert UniswapOracleCreationFailed();
        }

        nebularOracle = new NebularOracle(uniswapOracle, chainLinkOracle);

        // Pool creation and registration
        pool = new LiquidityPool(_token0, _token1, nebularOracle);
        
        liquidityPools.push(pool);
        getPool[_token0][_token1] = address(pool);
        getPool[_token1][_token0] = address(pool);

        emit LiquidityPoolCreated(address(pool), _token0, _token1);
    }

    /**
     * @notice Gets the total number of created pools
     * @return The current count of liquidity pools
     * @dev Useful for enumeration and monitoring pool creation activity
     */
    function getLiquidityPoolCount() external view returns (uint256) {
        return liquidityPools.length;
    }

    /**
     * @notice Checks for existence of a pool for given token pair
     * @dev Checks both token orderings (tokenA-tokenB and tokenB-tokenA)
     * @param tokenA First token address
     * @param tokenB Second token address
     * @return bool True if pool exists, false otherwise
     * 
     * @custom:note Returns false for zero address inputs
     */
    function poolExists(address tokenA, address tokenB) external view returns (bool) {
        return getPool[tokenA][tokenB] != address(0);
    }
}