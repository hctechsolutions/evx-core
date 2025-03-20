// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@nebula/contracts/LiquidityPool.sol";
import "@nebula/contracts/PositionNFT.sol";

/**
 * @title LiquidityPoolFactory
 * @notice Factory contract to deploy LiquidityPool instances
 */
contract LiquidityPoolFactory {
    LiquidityPool[] public liquidityPools;

    event LiquidityPoolCreated(address indexed pool, address token0, address token1);

    function createLiquidityPool(address _token0, address _token1, address _oracle) external returns (LiquidityPool pool) {
        pool = new LiquidityPool(_token0, _token1, IPriceOracle(_oracle));
        liquidityPools.push(pool);

        emit LiquidityPoolCreated(address(pool), _token0, _token1);
    }

    function getLiquidityPoolCount() external view returns (uint256) {
        return liquidityPools.length;
    }
}
