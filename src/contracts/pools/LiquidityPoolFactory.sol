// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@nebular/contracts/pools/LiquidityPool.sol";
import "@nebular/contracts/oracles/ChainLink.sol";
import "@nebular/contracts/oracles/Uniswap.sol";
import "@nebular/contracts/oracles/Nebular.sol";
import "@nebular/interfaces/IOracle.sol";


contract LiquidityPoolFactory {

    error InvalidTokenAddresses();
    error IdenticalTokens();
    error InvalidChainlinkFeed();
    error InvalidUniswapPool();
    error PoolAlreadyExists();
    error ChainlinkOracleCreationFailed();
    error UniswapOracleCreationFailed();
    
    LiquidityPool[] public liquidityPools;
    mapping(address => mapping(address => address)) public getPool;

    event LiquidityPoolCreated(address indexed pool, address token0, address token1);

    /**
     * @notice Creates a new LiquidityPool contract.
     * @dev Deploys a new LiquidityPool instance and stores its reference.
     * The function enforces:
     *      - Tokens must be different addresses
     *      - Both oracle addresses must be non-zero
     *      - Deploys three oracle contracts (Chainlink -> Uniswap -> Nebular fallback)
     * @param _token0 Address of the first token in the pair
     * @param _token1 Address of the second token in the pair
     * @param _chainLinkPriceFeed Address of the Chainlink AggregatorV3Interface contract
     * @param _uniSwapPoolAddress Address of the Uniswap V3 pool
     * @return pool Address of the newly created LiquidityPool contract
     */
    function createLiquidityPool(
        address _token0, 
        address _token1, 
        address _chainLinkPriceFeed,
        address _uniSwapPoolAddress
    ) external returns (LiquidityPool pool) {
        // Validações convertidas para custom errors
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

        IOracle chainLinkOracle;
        IOracle uniswapOracle;
        IOracle nebularOracle;
        
        try new ChainlinkOracle(_chainLinkPriceFeed) returns (ChainlinkOracle createdOracle) {
            chainLinkOracle = createdOracle;
        } catch {
            revert ChainlinkOracleCreationFailed();
        }
        
        try new UniswapOracle(_uniSwapPoolAddress) returns (UniswapOracle createdOracle) {
            uniswapOracle = createdOracle;
        } catch {
            revert UniswapOracleCreationFailed();
        }

        nebularOracle = new NebularOracle(
            address(uniswapOracle), 
            address(chainLinkOracle)
        );

        pool = new LiquidityPool(_token0, _token1, nebularOracle);
        
        liquidityPools.push(pool);
        getPool[_token0][_token1] = address(pool);
        getPool[_token1][_token0] = address(pool);

        emit LiquidityPoolCreated(address(pool), _token0, _token1);
    }

    /**
     * @notice Returns the total number of deployed LiquidityPools.
     * @return The count of LiquidityPool instances created by this factory.
     */
    function getLiquidityPoolCount() external view returns (uint256) {
        return liquidityPools.length;
    }

    /**
    * @notice Checks if a liquidity pool exists for a given token pair
    * @dev Uses the factory's mapping storage for O(1) lookup complexity.
    *      The check is bidirectional - works regardless of token order.
    *      Returns false if either token address is invalid (zero address).
    * 
    * @param tokenA First token address of the pair
    * @param tokenB Second token address of the pair
    * @return bool True if pool exists, false otherwise
    */
    function poolExists(address tokenA, address tokenB) external view returns (bool) {
        return getPool[tokenA][tokenB] != address(0);
    }
}