# TokenVester
[Git Source](https://github.com/jeffersson-abreu/nebula_contracts/blob/8c0ed3db7d893c386ed8057ac0f00d846f64b26e/src/contracts/governance/TokenVester.sol)

**Inherits:**
Ownable

This contract handles token vesting with configurable cliff periods, initial releases, and gradual releases.

*This contract supports different vesting plans, such as:
- **Liquidity Vesting**: No cliff, tokens vest over 4 years.
- **Team Vesting**: 1-year cliff, tokens vest over 3 years.
- **Seed Investors Vesting**: 6-month cliff, tokens vest over 2 years.
- **Marketing Vesting**: Immediate 30% release, remaining tokens vest over 2 years.
The contract ensures that tokens are released progressively based on the specified schedules.*


## State Variables
### token
The ERC20 token being vested


```solidity
IERC20 public immutable token;
```


### start
The timestamp when the vesting starts


```solidity
uint256 public immutable start;
```


### cliffDuration
The duration of the cliff period before vesting starts


```solidity
uint256 public immutable cliffDuration;
```


### initialRelease
The initial amount of tokens released at the start


```solidity
uint256 public immutable initialRelease;
```


### totalAllocation
The total amount of tokens allocated for vesting


```solidity
uint256 public immutable totalAllocation;
```


### vestingDuration
The duration over which the remaining tokens vest linearly


```solidity
uint256 public immutable vestingDuration;
```


### released
The amount of tokens that have been released


```solidity
uint256 public released;
```


## Functions
### constructor

Initializes the token vesting contract.

*Ensures valid allocation and vesting duration. Tokens are released gradually over time.*


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
|`_token`|`IERC20`|The ERC20 token that will be vested.|
|`_cliffDuration`|`uint256`|The duration (in seconds) before vesting starts.|
|`_initialRelease`|`uint256`|The number of tokens released immediately at the start.|
|`_totalAllocation`|`uint256`|The total amount of tokens allocated for vesting.|
|`_vestingDuration`|`uint256`|The duration (in seconds) over which the remaining tokens vest.|
|`_owner`|`address`|The address that will own the vesting contract.|


### release

Releases vested tokens to the contract owner.

Reverts if no new tokens are available to release.

*Only the contract owner can call this function. It calculates the total vested tokens,
deducts any already released amounts, and transfers the remaining vested tokens.*


```solidity
function release() external onlyOwner;
```

### calculateVestedAmount

Calculates the amount of tokens that have vested up to the current block timestamp.

*The function accounts for the initial release and linearly vests the remaining tokens.
If the vesting duration has passed, the full allocation is considered vested.*


```solidity
function calculateVestedAmount() public view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The total amount of vested tokens.|


## Events
### TokensReleased
Event emitted when tokens are released


```solidity
event TokensReleased(uint256 amount);
```

