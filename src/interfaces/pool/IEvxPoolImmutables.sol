// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Pool parameters set at initialization
 * @notice Most values are fixed for the life of the pool. Exception: `fee()` is the current swap fee and may
 *         change via setDynamicFee within [feeBase, feeMax].
 */
interface IEvxPoolImmutables {
    /**
     * @notice Returns the contract that deployed the pool
     * @dev The deployer must adhere to the IEvxFactory interface
     * @return The factory contract address
     */
    function factory() external view returns (address);

    /**
     * @notice Returns the first of the two tokens of the pool, sorted by address
     * @return The token0 contract address
     */
    function token0() external view returns (address);

    /**
     * @notice Returns the second of the two tokens of the pool, sorted by address
     * @return The token1 contract address
     */
    function token1() external view returns (address);

    /**
     * @notice Returns the pool's current swap fee in hundredths of a bip
     * @dev Represented as 1e-6 of the swap amount; mutable via setDynamicFee within [feeBase, feeMax]
     * @return The current swap fee
     */
    function fee() external view returns (uint24);

    /**
     * @notice Returns the immutable floor for dynamic swap fee
     * @dev Set to the creation fee tier at initialize; cannot be changed
     * @return The minimum allowed swap fee
     */
    function feeBase() external view returns (uint24);

    /**
     * @notice Returns the immutable ceiling for dynamic swap fee
     * @dev Set at initialize; cannot be changed; must be < 1e6
     * @return The maximum allowed swap fee
     */
    function feeMax() external view returns (uint24);

    /**
     * @notice Returns the address authorized to call setDynamicFee
     * @dev Set at initialize; no rotation in current protocol version
     * @return The policy keeper address
     */
    function policyKeeper() external view returns (address);

    /**
     * @notice Returns the pool tick spacing
     * @dev Ticks can only be initialized at multiples of this value; minimum of 1 and always positive
     *      For example, a tickSpacing of 3 allows ticks at ..., -6, -3, 0, 3, 6, ...
     * @return The tick spacing as an int24
     */
    function tickSpacing() external view returns (int24);

    /**
     * @notice Returns the maximum amount of position liquidity that can use any tick in the range
     * @dev Enforced per tick to prevent overflow of uint128 and to restrict out-of-range liquidity
     * @return The max liquidity per tick
     */
    function maxLiquidityPerTick() external view returns (uint128);
}
