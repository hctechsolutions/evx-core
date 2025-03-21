# TokenVester
[Git Source](https://github.com/jeffersson-abreu/nebula_contracts/blob/ec613b8e4edfc995d98c4c7aaaac9edf0c72aed1/src/contracts/governance/TokenVester.sol)

**Inherits:**
Ownable

Handles token vesting with cliff and gradual release


## State Variables
### token

```solidity
IERC20 public immutable token;
```


### start

```solidity
uint256 public immutable start;
```


### cliffDuration

```solidity
uint256 public immutable cliffDuration;
```


### initialRelease

```solidity
uint256 public immutable initialRelease;
```


### totalAllocation

```solidity
uint256 public immutable totalAllocation;
```


### vestingDuration

```solidity
uint256 public immutable vestingDuration;
```


### released

```solidity
uint256 public released;
```


## Functions
### constructor

Initializes the vesting contract


```solidity
constructor(
    IERC20 _token,
    uint256 _cliffDuration,
    uint256 _initialRelease,
    uint256 _totalAllocation,
    uint256 _vestingDuration,
    address _owner
) Ownable(_owner);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_token`|`IERC20`|The token to be vested|
|`_cliffDuration`|`uint256`|The time before vesting starts|
|`_initialRelease`|`uint256`|The initial release amount|
|`_totalAllocation`|`uint256`|Total amount allocated for vesting|
|`_vestingDuration`|`uint256`|Duration of the vesting period|
|`_owner`|`address`|Owner of the contract|


### release

Releases vested tokens


```solidity
function release() external onlyOwner;
```

### calculateVestedAmount

Calculates the amount of tokens vested


```solidity
function calculateVestedAmount() public view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The amount of vested tokens|


## Events
### TokensReleased

```solidity
event TokensReleased(uint256 amount);
```

