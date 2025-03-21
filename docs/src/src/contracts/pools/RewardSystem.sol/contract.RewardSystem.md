# RewardSystem
[Git Source](https://github.com/jeffersson-abreu/nebula_contracts/blob/ec613b8e4edfc995d98c4c7aaaac9edf0c72aed1/src/contracts/pools/RewardSystem.sol)


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

