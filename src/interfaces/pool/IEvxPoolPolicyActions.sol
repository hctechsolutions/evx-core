// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Policy-controlled pool actions
 * @notice Contains pool methods restricted to the policy keeper for dynamic swap fee updates
 */
interface IEvxPoolPolicyActions {
    /**
     * @notice Updates the current swap fee within immutable bounds
     * @dev Callable only by policyKeeper; pool validates bounds only, never calculates policy
     * @param newFee The new swap fee in hundredths of a bip (1e-6 of swap amount)
     */
    function setDynamicFee(uint24 newFee) external;
}
