# RewardSystem
[Git Source](https://github.com/jeffersson-abreu/nebula_contracts/blob/8c0ed3db7d893c386ed8057ac0f00d846f64b26e/src/contracts/pools/RewardSystem.sol)


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

