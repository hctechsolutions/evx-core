// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { GovernorCountingOverridable } from "@openzeppelin/contracts/governance/extensions/GovernorCountingOverridable.sol";
import { GovernorVotesQuorumFraction } from "@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";
import { GovernorTimelockControl } from "@openzeppelin/contracts/governance/extensions/GovernorTimelockControl.sol";
import { GovernorVotes } from "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import { TimelockController } from "@openzeppelin/contracts/governance/TimelockController.sol";
import { IGovernor } from "@openzeppelin/contracts/governance/IGovernor.sol";
import { IVotes } from "@openzeppelin/contracts/governance/utils/IVotes.sol";
import { IGovernanceToken } from "@nebular/interfaces/IGovernanceToken.sol";
import { Governor } from "@openzeppelin/contracts/governance/Governor.sol";

/**
 * @title GovernanceDAO
 * @notice A decentralized governance contract that manages protocol upgrades and parameter changes.
 * @dev This contract extends multiple OpenZeppelin governance modules to enable advanced governance mechanisms.
 *      - `Governor`: Base contract for governance.
 *      - `GovernorTimelockControl`: Adds timelock functionality to enforce execution delays.
 *      - `GovernorVotes`: Integrates voting based on tokenized voting power.
 *      - `GovernorCountingOverridable`: Allows flexible vote counting strategies.
 *      - `GovernorVotesQuorumFraction`: Defines the quorum as a fraction of total voting supply.
 */
contract GovernanceDAO is
    Governor,
    GovernorTimelockControl,
    GovernorVotes,
    GovernorCountingOverridable,
    GovernorVotesQuorumFraction
{
    /// @notice Immutable reference to the governance token used for voting.
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
     * @notice Cancels a proposal before execution.
     * @dev Resolves multiple inheritance conflicts by overriding the _cancel function.
     * @param targets The addresses of the contract calls.
     * @param values The ether values to be sent in the transactions.
     * @param calldatas The encoded function calls.
     * @param descriptionHash The keccak256 hash of the proposal description.
     * @return uint256 The proposal ID that was canceled.
     */
    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) returns (uint256) {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }

    /**
     * @notice Returns the address of the executor responsible for executing proposals.
     * @dev Resolves multiple inheritance conflicts by overriding the _executor function.
     * @return address The executor's address.
     */
    function _executor() internal view override(Governor, GovernorTimelockControl) returns (address) {
        return super._executor();
    }

    /**
     * @notice Retrieves the current state of a governance proposal.
     * @param proposalId The unique identifier of the proposal.
     * @return ProposalState The state of the proposal (e.g., Pending, Active, Canceled, etc.).
     */
    function state(uint256 proposalId)
        public
        view
        override(Governor, GovernorTimelockControl)
        returns (ProposalState)
    {
        return super.state(proposalId);
    }

    /**
     * @notice Determines if a proposal needs to be queued before execution.
     * @param proposalId The unique identifier of the proposal.
     * @return bool True if the proposal requires queuing, false otherwise.
     */
    function proposalNeedsQueuing(uint256 proposalId)
        public
        view
        override(Governor, GovernorTimelockControl)
        returns (bool)
    {
        return super.proposalNeedsQueuing(proposalId);
    }

    /**
     * @notice Defines the voting delay before a proposal can be voted on.
     * @dev The delay is measured in blocks and approximates 24 hours assuming 15 seconds per block.
     * @return uint256 The number of blocks to wait before voting starts.
     */
    function votingDelay() public pure override(Governor) returns (uint256) {
        return 5760;
    }

    /**
     * @notice Defines the duration of the voting period.
     * @dev The duration is measured in blocks and approximates 7 days assuming 15 seconds per block.
     * @return uint256 The number of blocks for which voting remains open.
     */
    function votingPeriod() public pure override(Governor) returns (uint256) {
        return 40320;
    }

    /**
     * @notice Returns the required quorum for a governance proposal.
     * @dev The quorum represents the minimum number of votes required for a proposal to be valid.
     * @param blockNumber The block number for which to calculate the quorum.
     * @return uint256 The quorum value at the given block number.
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
     * @dev This function allows checking historical voting power, which is essential for governance proposals.
     * @param account The address of the voter.
     * @param blockNumber The block number at which to check votes.
     * @return uint256 The voting power of the account at the given block number.
     */
    function getVotes(address account, uint256 blockNumber) public view override(Governor) returns (uint256) {
        return governanceToken.getPastVotes(account, blockNumber);
    }

    /**
     * @notice Returns the clock mode used for voting mechanisms.
     * @dev This function defines how time is measured in the governance contract.
     * @return string A string describing the clock mode.
     */
    function CLOCK_MODE() public pure override(Governor, GovernorVotes) returns (string memory) {
        return "mode=blocknumber&from=default";
    }

    /**
     * @notice Retrieves the current block number as the governance clock.
     * @dev This function is used for timekeeping in governance proposals.
     * @return uint48 The current block number.
     */
    function clock() public view override(Governor, GovernorVotes) returns (uint48) {
        return uint48(block.number);
    }

    /**
     * @notice Returns the counting mode for vote aggregation.
     * @dev Defines the vote counting system used in the governance contract.
     *      "support=bravo" follows Compound-style voting.
     *      "quorum=for,abstain" means only "for" and "abstain" votes count towards quorum.
     * @return string A description of the counting mode.
     */
    function COUNTING_MODE() public pure override(IGovernor, GovernorCountingOverridable) returns (string memory) {
        return "support=bravo&quorum=for,abstain";
    }

    /**
     * @notice Checks if a proposal has reached the required quorum.
     * @dev Determines whether the minimum number of votes has been met for a proposal.
     * @param proposalId The unique identifier of the proposal.
     * @return bool True if the quorum has been reached, false otherwise.
     */
    function _quorumReached(uint256 proposalId)
        internal
        view
        override(Governor, GovernorCountingOverridable)
        returns (bool)
    {
        return super._quorumReached(proposalId);
    }

    /**
     * @notice Determines whether a proposal has succeeded based on vote counts.
     * @dev Checks if the proposal has met the required majority to pass.
     * @param proposalId The unique identifier of the proposal.
     * @return bool True if the proposal has succeeded, false otherwise.
     */
    function _voteSucceeded(uint256 proposalId)
        internal
        view
        override(Governor, GovernorCountingOverridable)
        returns (bool)
    {
        return super._voteSucceeded(proposalId);
    }

    /**
     * @notice Checks if a specific account has voted on a given proposal.
     * @dev This function helps track voter participation in governance proposals.
     * @param proposalId The unique identifier of the proposal.
     * @param account The address of the voter.
     * @return bool True if the account has voted, false otherwise.
     */
    function hasVoted(uint256 proposalId, address account)
        public
        view
        override(IGovernor, GovernorCountingOverridable)
        returns (bool)
    {
        return super.hasVoted(proposalId, account);
    }

    /**
     * @notice Executes the operations associated with a successful governance proposal.
     * @dev This function is called after a proposal passes and is scheduled for execution.
     * @param proposalId The unique identifier of the proposal.
     * @param targets The list of contract addresses that will receive transactions.
     * @param values The amounts of ETH to send with each transaction.
     * @param calldatas The calldata to execute on each target contract.
     * @param descriptionHash The keccak256 hash of the proposal description.
     */
    function _executeOperations(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) {
        super._executeOperations(proposalId, targets, values, calldatas, descriptionHash);
    }

    /**
     * @notice Queues a governance proposal for execution.
     * @dev Once a proposal passes, it must be queued in the timelock before execution.
     * @param proposalId The unique identifier of the proposal.
     * @param targets The list of contract addresses that will receive transactions.
     * @param values The amounts of ETH to send with each transaction.
     * @param calldatas The calldata to execute on each target contract.
     * @param descriptionHash The keccak256 hash of the proposal description.
     * @return result The timestamp when the proposal will be executable.
     */
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
