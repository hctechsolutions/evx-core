# MathUtils
[Git Source](https://github.com/jeffersson-abreu/nebula_contracts/blob/ec613b8e4edfc995d98c4c7aaaac9edf0c72aed1/src/lib/MathUtils.sol)

*Library for common mathematical operations used in DeFi protocols.*


## State Variables
### WAD
*Standard scaling factor (1e18) used for fixed-point arithmetic.*


```solidity
uint256 internal constant WAD = 1e18;
```


## Functions
### wadMul

Multiplies two WAD-scaled numbers with correct rounding.

*Performs fixed-point multiplication using WAD (1e18 scaling) and applies rounding adjustment.
The formula used is: `(x * y + WAD / 2) / WAD`, which ensures proper rounding.*


```solidity
function wadMul(uint256 x, uint256 y) internal pure returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`x`|`uint256`|The first operand, scaled to WAD precision (1e18).|
|`y`|`uint256`|The second operand, scaled to WAD precision (1e18).|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The product of `x` and `y`, scaled back to WAD precision.|


### wadDiv

Divides two numbers while maintaining WAD precision.

*Performs fixed-point division using WAD (1e18 scaling) with proper rounding.
The formula used is: `(a * WAD + b / 2) / b`, which ensures accurate results.*


```solidity
function wadDiv(uint256 a, uint256 b) internal pure returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`a`|`uint256`|The numerator, expected to be scaled to WAD precision (1e18).|
|`b`|`uint256`|The denominator, must be greater than zero.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The quotient of `a / b`, scaled to WAD precision.|


### sqrt

Computes the square root of a given number.

*Uses the Babylonian method for calculating square roots.*


```solidity
function sqrt(uint256 x) internal pure returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`x`|`uint256`|The number to compute the square root of.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The square root of x.|


