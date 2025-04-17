# INebularToken
[Git Source](https://github.com/jeffersson-abreu/nebula_contracts/blob/b75b76e73206eb62056b1782781cf7d34ff74fa2/src/contracts/governance/interfaces/INebularToken.sol)

Interface for the Nebular token contract with voting and permit capabilities.


## Functions
### nonces

Returns the current nonce for an owner, required for permit signatures.


```solidity
function nonces(address owner) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`owner`|`address`|The address to query.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The next valid nonce for the owner.|


### getPastVotes

Returns the past voting power of an account at a specific block number.


```solidity
function getPastVotes(address account, uint256 blockNumber) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`address`|The address of the token holder.|
|`blockNumber`|`uint256`|The block number at which to retrieve the voting power.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The voting power of the account at the given block.|


## Events
### AutoDelegated
Emitted when an account is automatically self-delegated upon first token receipt.


```solidity
event AutoDelegated(address indexed account);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`address`|The address that was auto-delegated.|

