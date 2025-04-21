// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title INebularPoolDeployer
 * @notice Interface for contracts capable of deploying NebularPool instances.
 * @dev Enables deployment of pools without constructor arguments to ensure deterministic CREATE2 addresses.
 */
interface INebularPoolDeployer {
    /**
     * @notice Returns the parameters used to construct a pool.
     * @dev These parameters are temporarily stored and accessed by the NebularPool constructor during deployment.
     * @return factory The address of the Nebular factory that initiated deployment.
     * @return token0 The first token of the pool, sorted by address.
     * @return token1 The second token of the pool, sorted by address.
     * @return fee The fee tier for the pool, in hundredths of a bip (e.g., 3000 = 0.3%).
     * @return tickSpacing The spacing between usable ticks in the pool.
     */
    function parameters()
        external
        view
        returns (
            address factory,
            address token0,
            address token1,
            uint24 fee,
            int24 tickSpacing
        );
}
