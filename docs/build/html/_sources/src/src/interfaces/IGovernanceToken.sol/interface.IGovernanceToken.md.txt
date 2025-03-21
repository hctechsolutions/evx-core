# IGovernanceToken
[Git Source](https://github.com/jeffersson-abreu/nebula_contracts/blob/5cae3cf31fffc063887e8ff58da33da2f0e0820b/src/interfaces/IGovernanceToken.sol)

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


