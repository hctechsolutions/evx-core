# LiquidityPoolFactory
[Git Source](https://github.com/jeffersson-abreu/nebula_contracts/blob/ec613b8e4edfc995d98c4c7aaaac9edf0c72aed1/src/contracts/pools/LiquidityPoolFactory.sol)

Factory contract for deploying LiquidityPool instances.

*This contract allows the creation and tracking of deployed liquidity pools.*


## State Variables
### liquidityPools
*Stores all deployed LiquidityPool instances.*


```solidity
LiquidityPool[] public liquidityPools;
```


## Functions
### createLiquidityPool

Creates a new LiquidityPool contract.

*Deploys a new LiquidityPool instance and stores its reference.*


```solidity
function createLiquidityPool(address _token0, address _token1, address _oracle) external returns (LiquidityPool pool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_token0`|`address`|The address of the first token in the pool.|
|`_token1`|`address`|The address of the second token in the pool.|
|`_oracle`|`address`|The address of the price oracle for the pool.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`pool`|`LiquidityPool`|The address of the newly created LiquidityPool.|


### getLiquidityPoolCount

Returns the total number of deployed LiquidityPools.


```solidity
function getLiquidityPoolCount() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The count of LiquidityPool instances created by this factory.|


## Events
### LiquidityPoolCreated
Emitted when a new LiquidityPool is created.


```solidity
event LiquidityPoolCreated(address indexed pool, address token0, address token1);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`pool`|`address`|The address of the newly deployed liquidity pool.|
|`token0`|`address`|The first token in the liquidity pair.|
|`token1`|`address`|The second token in the liquidity pair.|

