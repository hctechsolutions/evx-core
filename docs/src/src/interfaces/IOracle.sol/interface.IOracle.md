# IOracle
[Git Source](https://github.com/jeffersson-abreu/nebula_contracts/blob/8c0ed3db7d893c386ed8057ac0f00d846f64b26e/src/interfaces/IOracle.sol)

Interface for an oracle that provides asset price information.


## Functions
### getPrice

Returns the latest price from the oracle.

*The price is expected to be normalized to 18 decimals (WAD precision).*


```solidity
function getPrice() external view returns (uint256 price);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`price`|`uint256`|The latest asset price in WAD format.|


