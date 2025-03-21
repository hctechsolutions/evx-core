# GovernanceDAO
[Git Source](https://github.com/jeffersson-abreu/nebula_contracts/blob/5cae3cf31fffc063887e8ff58da33da2f0e0820b/src/contracts/governance/GovernanceDAO.sol)

**Inherits:**
Governor, GovernorTimelockControl, GovernorVotes, GovernorCountingOverridable, GovernorVotesQuorumFraction

A decentralized governance contract that manages protocol upgrades and parameter changes.

*This contract extends multiple OpenZeppelin governance modules to enable advanced governance mechanisms.
- `Governor`: Base contract for governance.
- `GovernorTimelockControl`: Adds timelock functionality to enforce execution delays.
- `GovernorVotes`: Integrates voting based on tokenized voting power.
- `GovernorCountingOverridable`: Allows flexible vote counting strategies.
- `GovernorVotesQuorumFraction`: Defines the quorum as a fraction of total voting supply.*


## State Variables
### governanceToken
Immutable reference to the governance token used for voting.


```solidity
IGovernanceToken public immutable governanceToken;
```


## Functions
### constructor

Constructor to initialize the governance contract.


```solidity
constructor(IGovernanceToken _token, TimelockController _timelock)
    Governor("NBL Governance DAO")
    GovernorVotes(IVotes(address(_token)))
    GovernorTimelockControl(_timelock)
    GovernorCountingOverridable()
    GovernorVotesQuorumFraction(51);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_token`|`IGovernanceToken`|The governance token contract implementing IGovernanceToken.|
|`_timelock`|`TimelockController`|The timelock controller contract.|


### _cancel

Cancels a proposal before execution.

*Resolves multiple inheritance conflicts by overriding the _cancel function.*


```solidity
function _cancel(address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes32 descriptionHash)
    internal
    override(Governor, GovernorTimelockControl)
    returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`targets`|`address[]`|The addresses of the contract calls.|
|`values`|`uint256[]`|The ether values to be sent in the transactions.|
|`calldatas`|`bytes[]`|The encoded function calls.|
|`descriptionHash`|`bytes32`|The keccak256 hash of the proposal description.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|uint256 The proposal ID that was canceled.|


### _executor

Returns the address of the executor responsible for executing proposals.

*Resolves multiple inheritance conflicts by overriding the _executor function.*


```solidity
function _executor() internal view override(Governor, GovernorTimelockControl) returns (address);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|address The executor's address.|


### state

Retrieves the current state of a governance proposal.


```solidity
function state(uint256 proposalId) public view override(Governor, GovernorTimelockControl) returns (ProposalState);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`proposalId`|`uint256`|The unique identifier of the proposal.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`ProposalState`|ProposalState The state of the proposal (e.g., Pending, Active, Canceled, etc.).|


### proposalNeedsQueuing

Determines if a proposal needs to be queued before execution.


```solidity
function proposalNeedsQueuing(uint256 proposalId)
    public
    view
    override(Governor, GovernorTimelockControl)
    returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`proposalId`|`uint256`|The unique identifier of the proposal.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|bool True if the proposal requires queuing, false otherwise.|


### votingDelay

Defines the voting delay before a proposal can be voted on.

*The delay is measured in blocks and approximates 24 hours assuming 15 seconds per block.*


```solidity
function votingDelay() public pure override(Governor) returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|uint256 The number of blocks to wait before voting starts.|


### votingPeriod

Defines the duration of the voting period.

*The duration is measured in blocks and approximates 7 days assuming 15 seconds per block.*


```solidity
function votingPeriod() public pure override(Governor) returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|uint256 The number of blocks for which voting remains open.|


### quorum

Returns the required quorum for a governance proposal.

*The quorum represents the minimum number of votes required for a proposal to be valid.*


```solidity
function quorum(uint256 blockNumber) public view override(Governor, GovernorVotesQuorumFraction) returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`blockNumber`|`uint256`|The block number for which to calculate the quorum.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|uint256 The quorum value at the given block number.|


### getVotes

Retrieves the past voting power of an account at a given block number.

*This function allows checking historical voting power, which is essential for governance proposals.*


```solidity
function getVotes(address account, uint256 blockNumber) public view override(Governor) returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`address`|The address of the voter.|
|`blockNumber`|`uint256`|The block number at which to check votes.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|uint256 The voting power of the account at the given block number.|


### CLOCK_MODE

Returns the clock mode used for voting mechanisms.

*This function defines how time is measured in the governance contract.*


```solidity
function CLOCK_MODE() public pure override(Governor, GovernorVotes) returns (string memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`string`|string A string describing the clock mode.|


### clock

Retrieves the current block number as the governance clock.

*This function is used for timekeeping in governance proposals.*


```solidity
function clock() public view override(Governor, GovernorVotes) returns (uint48);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint48`|uint48 The current block number.|


### COUNTING_MODE

Returns the counting mode for vote aggregation.

*Defines the vote counting system used in the governance contract.
"support=bravo" follows Compound-style voting.
"quorum=for,abstain" means only "for" and "abstain" votes count towards quorum.*


```solidity
function COUNTING_MODE() public pure override(IGovernor, GovernorCountingOverridable) returns (string memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`string`|string A description of the counting mode.|


### _quorumReached

Checks if a proposal has reached the required quorum.

*Determines whether the minimum number of votes has been met for a proposal.*


```solidity
function _quorumReached(uint256 proposalId)
    internal
    view
    override(Governor, GovernorCountingOverridable)
    returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`proposalId`|`uint256`|The unique identifier of the proposal.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|bool True if the quorum has been reached, false otherwise.|


### _voteSucceeded

Determines whether a proposal has succeeded based on vote counts.

*Checks if the proposal has met the required majority to pass.*


```solidity
function _voteSucceeded(uint256 proposalId)
    internal
    view
    override(Governor, GovernorCountingOverridable)
    returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`proposalId`|`uint256`|The unique identifier of the proposal.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|bool True if the proposal has succeeded, false otherwise.|


### hasVoted

Checks if a specific account has voted on a given proposal.

*This function helps track voter participation in governance proposals.*


```solidity
function hasVoted(uint256 proposalId, address account)
    public
    view
    override(IGovernor, GovernorCountingOverridable)
    returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`proposalId`|`uint256`|The unique identifier of the proposal.|
|`account`|`address`|The address of the voter.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|bool True if the account has voted, false otherwise.|


### _executeOperations

Executes the operations associated with a successful governance proposal.

*This function is called after a proposal passes and is scheduled for execution.*


```solidity
function _executeOperations(
    uint256 proposalId,
    address[] memory targets,
    uint256[] memory values,
    bytes[] memory calldatas,
    bytes32 descriptionHash
) internal override(Governor, GovernorTimelockControl);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`proposalId`|`uint256`|The unique identifier of the proposal.|
|`targets`|`address[]`|The list of contract addresses that will receive transactions.|
|`values`|`uint256[]`|The amounts of ETH to send with each transaction.|
|`calldatas`|`bytes[]`|The calldata to execute on each target contract.|
|`descriptionHash`|`bytes32`|The keccak256 hash of the proposal description.|


### _queueOperations

Queues a governance proposal for execution.

*Once a proposal passes, it must be queued in the timelock before execution.*


```solidity
function _queueOperations(
    uint256 proposalId,
    address[] memory targets,
    uint256[] memory values,
    bytes[] memory calldatas,
    bytes32 descriptionHash
) internal override(Governor, GovernorTimelockControl) returns (uint48 result);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`proposalId`|`uint256`|The unique identifier of the proposal.|
|`targets`|`address[]`|The list of contract addresses that will receive transactions.|
|`values`|`uint256[]`|The amounts of ETH to send with each transaction.|
|`calldatas`|`bytes[]`|The calldata to execute on each target contract.|
|`descriptionHash`|`bytes32`|The keccak256 hash of the proposal description.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`result`|`uint48`|The timestamp when the proposal will be executable.|


