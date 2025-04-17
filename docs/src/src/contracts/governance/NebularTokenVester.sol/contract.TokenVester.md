# TokenVester
[Git Source](https://github.com/jeffersson-abreu/nebula_contracts/blob/b75b76e73206eb62056b1782781cf7d34ff74fa2/src/contracts/governance/NebularTokenVester.sol)

**Inherits:**
[INebularTokenVester](/src/contracts/governance/interfaces/INebularTokenVester.sol/interface.INebularTokenVester.md), Ownable


## State Variables
### token
Returns the ERC20 token being vested.


```solidity
IERC20 public immutable token;
```


### start
Returns the timestamp when vesting starts.


```solidity
uint256 public immutable start;
```


### cliffDuration
Returns the duration of the cliff period before vesting begins.


```solidity
uint256 public immutable cliffDuration;
```


### initialRelease
Returns the initial amount of tokens released at vesting start.


```solidity
uint256 public immutable initialRelease;
```


### totalAllocation
Returns the total amount of tokens allocated for vesting.


```solidity
uint256 public immutable totalAllocation;
```


### vestingDuration
Returns the duration over which the remaining tokens vest linearly.


```solidity
uint256 public immutable vestingDuration;
```


### released
Returns the total amount of tokens already released.


```solidity
uint256 public released;
```


### beneficiary
The address that will be the beneficiary of the tokens


```solidity
address public beneficiary;
```


## Functions
### constructor

Initializes the vesting contract with specified parameters.

*Requires _totalAllocation > _initialRelease and _vestingDuration > 0.*


```solidity
constructor(
    IERC20 _token,
    uint256 _cliffDuration,
    uint256 _initialRelease,
    uint256 _totalAllocation,
    uint256 _vestingDuration,
    address _beneficiary,
    address _owner
) Ownable(_owner);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_token`|`IERC20`|The ERC20 token to vest.|
|`_cliffDuration`|`uint256`|Time (in seconds) before any vesting begins.|
|`_initialRelease`|`uint256`|Amount of tokens released immediately after cliff.|
|`_totalAllocation`|`uint256`|Total tokens allocated for vesting.|
|`_vestingDuration`|`uint256`|Duration (in seconds) over which remaining tokens vest linearly.|
|`_beneficiary`|`address`|Address entitled to receive vested tokens.|
|`_owner`|`address`|Address granted ownership privileges (can call release).|


### release

Releases any vested tokens to the beneficiary.

*Can only be called by the contract owner. Reverts if no tokens are available.*


```solidity
function release() external override onlyOwner;
```

### calculateVestedAmount

Calculates the total amount of tokens vested up to the current timestamp.


```solidity
function calculateVestedAmount() public view override returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The total vested token amount.|


