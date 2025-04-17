# NebularGovernance
[Git Source](https://github.com/jeffersson-abreu/nebula_contracts/blob/b75b76e73206eb62056b1782781cf7d34ff74fa2/src/contracts/governance/NebularGovernance.sol)

**Inherits:**
[INebularGovernance](/src/contracts/governance/interfaces/INebularGovernance.sol/interface.INebularGovernance.md), Governor, GovernorTimelockControl, GovernorVotes, GovernorCountingOverridable, GovernorVotesQuorumFraction


## State Variables
### nebularToken
Returns the governance token used for voting.


```solidity
INebularToken public immutable nebularToken;
```


## Functions
### constructor

Initializes the Nebular Governance DAO.


```solidity
constructor(INebularToken _token, TimelockController _timelock)
    Governor("NBL Governance DAO")
    GovernorVotes(IVotes(address(_token)))
    GovernorTimelockControl(_timelock)
    GovernorCountingOverridable()
    GovernorVotesQuorumFraction(51);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_token`|`INebularToken`|The governance token contract implementing INebularToken.|
|`_timelock`|`TimelockController`|The TimelockController enforcing execution delay before proposal execution.|


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
function state(uint256 proposalId)
    public
    view
    override(INebularGovernance, Governor, GovernorTimelockControl)
    returns (ProposalState);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`proposalId`|`uint256`|The unique identifier of the proposal.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`ProposalState`|proposalState The state of the proposal (e.g., Pending, Active, Canceled, etc.).|


### proposalNeedsQueuing

Checks if a proposal needs queuing before execution.


```solidity
function proposalNeedsQueuing(uint256 proposalId)
    public
    view
    override(INebularGovernance, Governor, GovernorTimelockControl)
    returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`proposalId`|`uint256`|The unique proposal identifier.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|True if the proposal requires queuing.|


### votingDelay

Returns the required voting delay before voting starts.


```solidity
function votingDelay() public pure override(INebularGovernance, Governor) returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The number of blocks for the voting delay.|


### votingPeriod

Returns the duration of the voting period.


```solidity
function votingPeriod() public pure override(INebularGovernance, Governor) returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The number of blocks voting remains open.|


### quorum

Returns the required quorum for a given block.


```solidity
function quorum(uint256 blockNumber)
    public
    view
    override(INebularGovernance, Governor, GovernorVotesQuorumFraction)
    returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`blockNumber`|`uint256`|The block number for quorum calculation.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The quorum value at the specified block.|


### getVotes

Retrieves past voting power of an account.


```solidity
function getVotes(address account, uint256 blockNumber)
    public
    view
    override(INebularGovernance, Governor)
    returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`address`|The address of the voter.|
|`blockNumber`|`uint256`|The block number at which to retrieve votes.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The voting power at the given block.|


### CLOCK_MODE

Returns the clock mode used by the governor.


```solidity
function CLOCK_MODE() public pure override(INebularGovernance, Governor, GovernorVotes) returns (string memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`string`|A string identifying the clock mode.|


### clock

Returns the current clock value (block number).


```solidity
function clock() public view override(INebularGovernance, Governor, GovernorVotes) returns (uint48);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint48`|The block number used as clock.|


### COUNTING_MODE

Returns the counting mode used by the governor.


```solidity
function COUNTING_MODE()
    public
    pure
    override(INebularGovernance, IGovernor, GovernorCountingOverridable)
    returns (string memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`string`|A string identifying the counting mode.|


### hasVoted

Checks if an account has voted on a proposal.


```solidity
function hasVoted(uint256 proposalId, address account)
    public
    view
    override(INebularGovernance, IGovernor, GovernorCountingOverridable)
    returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`proposalId`|`uint256`|The unique proposal identifier.|
|`account`|`address`|The address of the voter.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|True if the account has voted.|


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


