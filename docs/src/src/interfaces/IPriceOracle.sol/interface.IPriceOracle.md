# IPriceOracle
[Git Source](https://github.com/jeffersson-abreu/nebula_contracts/blob/ec613b8e4edfc995d98c4c7aaaac9edf0c72aed1/src/interfaces/IPriceOracle.sol)

Provides asset price data with redundancy and validation


## Functions
### consult

Fetches the current price of the asset

*Implements multi-source consensus and fallback logic*


```solidity
function consult() external returns (uint256 price);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`price`|`uint256`|Normalized price (18 decimals)|


### lastUpdated

Returns timestamp of last valid price update


```solidity
function lastUpdated() external view returns (uint256);
```

## Events
### FallbackTriggered
Event emitted when oracle consensus fails


```solidity
event FallbackTriggered(string reason);
```

