# RewardSystem
[Git Source](https://github.com/jeffersson-abreu/nebula_contracts/blob/5cae3cf31fffc063887e8ff58da33da2f0e0820b/src/contracts/pools/RewardSystem.sol)


## State Variables
### rewardToken

```solidity
IGovernanceToken public rewardToken;
```


### positionNFT

```solidity
PositionNFT public positionNFT;
```


## Functions
### constructor


```solidity
constructor(address _rewardToken, address _positionNFT);
```

### claimRewards


```solidity
function claimRewards(uint256 tokenId) external;
```

## Events
### RewardsClaimed

```solidity
event RewardsClaimed(address indexed user, uint256 amount);
```

