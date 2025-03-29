// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/**
 * @title IUniswapV3Pool
 * @notice Interface for interacting with Uniswap V3 pools.
 */
interface IUniswapV3Pool {

    /**
     * @notice Returns the address of token0 in the Uniswap V3 pool.
     * @dev token0 is the first token in the pair, ordered by address sorting.
     * @return token0 The address of the first token in the pool.
     */
    function token0() external view returns (address);

    /**
     * @notice Returns the address of token1 in the Uniswap V3 pool.
     * @dev token1 is the second token in the pair, ordered by address sorting.
     * @return token1 The address of the second token in the pool.
     */
    function token1() external view returns (address);

    /**
     * @notice Returns the slot0 state of the pool, containing multiple values.
     * @return sqrtPriceX96 The current sqrt price of the pool as a Q64.96 value.
     * @return tick The current tick of the pool.
     * @return observationIndex The index of the last oracle observation.
     * @return observationCardinality The number of observations stored in the pool.
     * @return observationCardinalityNext The next cardinality to be increased.
     * @return feeProtocol The protocol fee for both tokens.
     * @return unlocked Whether the pool is currently locked.
     */
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /**
     * @notice Returns the liquidity available in the pool.
     * @return The available liquidity.
     */
    function liquidity() external view returns (uint128);

    /**
     * @notice Returns the fee amount of the pool.
     * @return The pool's fee in hundredths of a bip (e.g., 3000 = 0.3%).
     */
    function fee() external view returns (uint24);

    /**
     * @notice Fetches historical tick data from the Uniswap V3 oracle.
     * @dev This function returns the cumulative tick values for the given time intervals.
     * @param secondsAgos Array of timestamps to fetch tick data for, relative to the current block timestamp.
     * @return tickCumulatives The cumulative tick values at the given timestamps.
     * @return secondsPerLiquidityCumulativeX128 Not used in this implementation, but returned for compatibility.
     */
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128);
}
