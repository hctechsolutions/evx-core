# INebularTokenVester
[Git Source](https://github.com/jeffersson-abreu/nebula_contracts/blob/b75b76e73206eb62056b1782781cf7d34ff74fa2/src/contracts/governance/interfaces/INebularTokenVester.sol)

Interface for the TokenVester vesting contract handling configurable release schedules.


## Functions
### token

Returns the ERC20 token being vested.


```solidity
function token() external view returns (IERC20);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`IERC20`|The IERC20 token contract.|


### start

Returns the timestamp when vesting starts.


```solidity
function start() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The Unix timestamp of vesting start.|


### cliffDuration

Returns the duration of the cliff period before vesting begins.


```solidity
function cliffDuration() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Duration of the cliff in seconds.|


### initialRelease

Returns the initial amount of tokens released at vesting start.


```solidity
function initialRelease() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The amount of tokens for the initial release.|


### totalAllocation

Returns the total amount of tokens allocated for vesting.


```solidity
function totalAllocation() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The total vesting allocation of tokens.|


### vestingDuration

Returns the duration over which the remaining tokens vest linearly.


```solidity
function vestingDuration() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Vesting duration in seconds.|


### beneficiary

Returns the address of the beneficiary.


```solidity
function beneficiary() external view returns (address);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|The beneficiary address.|


### released

Returns the total amount of tokens already released.


```solidity
function released() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The amount of tokens released so far.|


### release

Releases any vested tokens to the beneficiary.

*Can only be called by the contract owner. Reverts if no tokens are available.*


```solidity
function release() external;
```

### calculateVestedAmount

Calculates the total amount of tokens vested up to the current timestamp.


```solidity
function calculateVestedAmount() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The total vested token amount.|


## Events
### TokensReleased
Emitted when vested tokens are released to the beneficiary.


```solidity
event TokensReleased(uint256 indexed amount);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of tokens released.|

