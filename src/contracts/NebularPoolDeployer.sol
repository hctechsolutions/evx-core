// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@nebular/interfaces/INebularPoolDeployer.sol";
import "@nebular/contracts/NebularPool.sol";

/**
 * @title NebularPoolDeployer
 * @notice Handles deterministic deployment of NebularPool instances with provided parameters.
 * @dev Uses transient storage to pass constructor parameters to the deployed NebularPool.
 */
contract NebularPoolDeployer is INebularPoolDeployer {
    /**
     * @notice Temporary parameters used during pool deployment.
     * @dev This struct is used to pass initialization parameters into the NebularPool constructor.
     */
    struct Parameters {
        /// @notice The address of the factory that initiated deployment.
        address factory;

        /// @notice The first token of the pool, sorted by address.
        address token0;

        /// @notice The second token of the pool, sorted by address.
        address token1;

        /// @notice The fee tier of the pool, in hundredths of a bip (e.g., 500 = 0.05%).
        uint24 fee;

        /// @notice The spacing between usable ticks in this pool.
        int24 tickSpacing;
    }

    /// @inheritdoc INebularPoolDeployer
    Parameters public override parameters;

    /**
     * @notice Deploys a new NebularPool contract with specific parameters.
     * @dev The parameters are temporarily stored in a public slot and used by the pool constructor.
     *      After deployment, the parameters are cleared to prevent reuse.
     * @param factory The address of the Nebular factory.
     * @param token0 The first token of the pool (sorted).
     * @param token1 The second token of the pool (sorted).
     * @param fee The swap fee for the pool, in hundredths of a bip.
     * @param tickSpacing The minimum tick interval that can be initialized in the pool.
     * @return pool The address of the deployed NebularPool.
     */
    function deploy(
        address factory,
        address token0,
        address token1,
        uint24 fee,
        int24 tickSpacing
    ) internal returns (address pool) {
        parameters = Parameters({factory: factory, token0: token0, token1: token1, fee: fee, tickSpacing: tickSpacing});
        pool = address(new NebularPool{salt: keccak256(abi.encode(token0, token1, fee))}());
        delete parameters;
    }
}
