# IGovernanceToken
[Git Source](https://github.com/jeffersson-abreu/nebula_contracts/blob/ec613b8e4edfc995d98c4c7aaaac9edf0c72aed1/src/interfaces/IGovernanceToken.sol)

Provides voting power tracking for governance systems


## Functions
### getPastVotes

Gets past voting power of an account


```solidity
function getPastVotes(address account, uint256 blockNumber) external view returns (uint256 votes);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`address`|Address to check|
|`blockNumber`|`uint256`|Block number to query|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`votes`|`uint256`|Voting power at specified block|


