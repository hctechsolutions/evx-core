// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Governance Token Interface
 * @notice Provides voting power tracking for governance systems
 */
interface IGovernanceToken {
    /**
     * @notice Gets past voting power of an account
     * @param account Address to check
     * @param blockNumber Block number to query
     * @return votes Voting power at specified block
     */
    function getPastVotes(address account, uint256 blockNumber) external view returns (uint256 votes);
}