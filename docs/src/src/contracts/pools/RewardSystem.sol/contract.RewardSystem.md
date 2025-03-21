# RewardSystem
[Git Source](https://github.com/jeffersson-abreu/nebula_contracts/blob/713b150e780334d0bd03d6604842282ffc694e40/src/contracts/pools/RewardSystem.sol)


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

