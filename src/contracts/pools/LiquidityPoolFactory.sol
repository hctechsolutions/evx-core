// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@nebula/contracts/pools/LiquidityPool.sol";
import "@nebula/contracts/pools/PositionNFT.sol";

/**
 * @title LiquidityPoolFactory
 * @notice Factory contract for deploying LiquidityPool instances.
 * @dev This contract allows the creation and tracking of deployed liquidity pools.
 */
contract LiquidityPoolFactory {
    /// @dev Stores all deployed LiquidityPool instances.
    LiquidityPool[] public liquidityPools;

    /**
     * @notice Emitted when a new LiquidityPool is created.
     * @param pool The address of the newly deployed liquidity pool.
     * @param token0 The first token in the liquidity pair.
     * @param token1 The second token in the liquidity pair.
     */
    event LiquidityPoolCreated(address indexed pool, address token0, address token1);

    /**
     * @notice Creates a new LiquidityPool contract.
     * @dev Deploys a new LiquidityPool instance and stores its reference.
     * @param _token0 The address of the first token in the pool.
     * @param _token1 The address of the second token in the pool.
     * @param _oracle The address of the price oracle for the pool.
     * @return pool The address of the newly created LiquidityPool.
     */
    function createLiquidityPool(address _token0, address _token1, address _oracle)
        external
        returns (LiquidityPool pool)
    {
        require(address(_token0) != address(_token1), "Token addresses must be different");
        pool = new LiquidityPool(_token0, _token1, IPriceOracle(_oracle));
        liquidityPools.push(pool);

        emit LiquidityPoolCreated(address(pool), _token0, _token1);
    }

    /**
     * @notice Returns the total number of deployed LiquidityPools.
     * @return The count of LiquidityPool instances created by this factory.
     */
    function getLiquidityPoolCount() external view returns (uint256) {
        return liquidityPools.length;
    }
}
