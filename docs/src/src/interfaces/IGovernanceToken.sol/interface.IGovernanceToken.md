# IGovernanceToken
[Git Source](https://github.com/jeffersson-abreu/nebula_contracts/blob/8c0ed3db7d893c386ed8057ac0f00d846f64b26e/src/interfaces/IGovernanceToken.sol)

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


