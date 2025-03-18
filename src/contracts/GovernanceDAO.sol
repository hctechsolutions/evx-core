// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorTimelockControl.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorCountingOverridable.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";
import "@openzeppelin/contracts/governance/utils/IVotes.sol";
import "@nebula/interfaces/IGovernanceToken.sol";

/**
 * @title GovernanceDAO
 * @notice A decentralized governance contract that manages protocol upgrades and parameter changes.
 */
contract GovernanceDAO is
    Governor, 
    GovernorTimelockControl, 
    GovernorVotes, 
    GovernorCountingOverridable, 
    GovernorVotesQuorumFraction 
{
    IGovernanceToken public immutable governanceToken;

    /**
     * @notice Constructor to initialize the governance contract.
     * @param _token The governance token contract implementing IGovernanceToken.
     * @param _timelock The timelock controller contract.
     */
    constructor(IGovernanceToken _token, TimelockController _timelock)
        Governor("NBL Governance DAO")
        GovernorVotes(IVotes(address(_token))) // Explicit conversion to IVotes
        GovernorTimelockControl(_timelock)
        GovernorCountingOverridable()
        GovernorVotesQuorumFraction(51) // Set quorum to 51%
    {
        governanceToken = _token;
    }

    /**
     * @notice Overrides to resolve multiple inheritance conflicts.
     */
    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) returns (uint256) {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }

    function _executor() internal view override(Governor, GovernorTimelockControl) returns (address) {
        return super._executor();
    }

    function state(uint256 proposalId) public view override(Governor, GovernorTimelockControl) returns (ProposalState) {
        return super.state(proposalId);
    }

    function proposalNeedsQueuing(uint256 proposalId)
        public
        view
        override(Governor, GovernorTimelockControl)
        returns (bool)
    {
        return super.proposalNeedsQueuing(proposalId);
    }

    /**
     * @notice Defines the voting delay in blocks before a proposal can be voted on.
     * @return uint256 Number of blocks (~24 hours assuming 15s/block).
     */
    function votingDelay() public pure override(Governor) returns (uint256) {
        return 5760;
    }

    /**
     * @notice Defines the voting period duration.
     * @return uint256 Number of blocks (~7 days).
     */
    function votingPeriod() public pure override(Governor) returns (uint256) {
        return 40320;
    }

    /**
     * @notice Returns the required quorum for governance proposals.
     * @param blockNumber The block number for which to calculate quorum.
     * @return uint256 Quorum value.
     */
    function quorum(uint256 blockNumber) 
        public 
        view 
        override(Governor, GovernorVotesQuorumFraction) 
        returns (uint256) 
    {
        return super.quorum(blockNumber);
    }

    /**
     * @notice Retrieves the past voting power of an account at a given block number.
     * @param account The address of the voter.
     * @param blockNumber The block number at which to check votes.
     * @return uint256 The voting power.
     */
    function getVotes(address account, uint256 blockNumber)
        public
        view
        override(Governor)
        returns (uint256)
    {
        return governanceToken.getPastVotes(account, blockNumber);
    }

    function CLOCK_MODE() 
        public 
        pure 
        override(Governor, GovernorVotes) 
        returns (string memory) 
    {
        return "mode=blocknumber&from=default";
    }

    function clock() 
        public 
        view 
        override(Governor, GovernorVotes) 
        returns (uint48) 
    {
        return uint48(block.number);
    }

    function COUNTING_MODE() 
        public 
        pure 
        override(IGovernor, GovernorCountingOverridable) 
        returns (string memory) 
    {
        return "support=bravo&quorum=for,abstain";
    }

    function _quorumReached(uint256 proposalId) 
        internal 
        view 
        override(Governor, GovernorCountingOverridable) 
        returns (bool) 
    {
        return super._quorumReached(proposalId);
    }

    function _voteSucceeded(uint256 proposalId) 
        internal 
        view 
        override(Governor, GovernorCountingOverridable) 
        returns (bool) 
    {
        return super._voteSucceeded(proposalId);
    }

    function hasVoted(uint256 proposalId, address account) 
        public 
        view 
        override(IGovernor, GovernorCountingOverridable) 
        returns (bool) 
    {
        return super.hasVoted(proposalId, account);
    }

    function _executeOperations(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) {
        super._executeOperations(proposalId, targets, values, calldatas, descriptionHash);
    }

    function _queueOperations(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) returns (uint48 result) {
        return super._queueOperations(proposalId, targets, values, calldatas, descriptionHash);
    }
}
