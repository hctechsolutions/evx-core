# INebularGovernance
[Git Source](https://github.com/jeffersson-abreu/nebula_contracts/blob/b75b76e73206eb62056b1782781cf7d34ff74fa2/src/contracts/governance/interfaces/INebularGovernance.sol)

**Inherits:**
IGovernor

Defines the external API of the INebularGovernance contract


## Functions
### nebularToken

Returns the governance token used for voting.


```solidity
function nebularToken() external view returns (INebularToken);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`INebularToken`|The INebularToken contract address.|


### proposalNeedsQueuing

Checks if a proposal needs queuing before execution.


```solidity
function proposalNeedsQueuing(uint256 proposalId) external view returns (bool);
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
function votingDelay() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The number of blocks for the voting delay.|


### votingPeriod

Returns the duration of the voting period.


```solidity
function votingPeriod() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The number of blocks voting remains open.|


### quorum

Returns the required quorum for a given block.


```solidity
function quorum(uint256 blockNumber) external view returns (uint256);
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
function getVotes(address account, uint256 blockNumber) external view returns (uint256);
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
function CLOCK_MODE() external view returns (string memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`string`|A string identifying the clock mode.|


### clock

Returns the current clock value (block number).


```solidity
function clock() external view returns (uint48);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint48`|The block number used as clock.|


### COUNTING_MODE

Returns the counting mode used by the governor.


```solidity
function COUNTING_MODE() external view returns (string memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`string`|A string identifying the counting mode.|


### hasVoted

Checks if an account has voted on a proposal.


```solidity
function hasVoted(uint256 proposalId, address account) external view returns (bool);
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


### state

Retrieves the current state of a governance proposal.


```solidity
function state(uint256 proposalId) external view returns (ProposalState proposalState);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`proposalId`|`uint256`|The unique identifier of the proposal.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`proposalState`|`ProposalState`|The state of the proposal (e.g., Pending, Active, Canceled, etc.).|


