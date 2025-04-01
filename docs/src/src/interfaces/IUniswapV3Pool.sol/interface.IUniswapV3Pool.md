# IUniswapV3Pool
[Git Source](https://github.com/jeffersson-abreu/nebula_contracts/blob/8c0ed3db7d893c386ed8057ac0f00d846f64b26e/src/interfaces/IUniswapV3Pool.sol)

Interface for interacting with Uniswap V3 pools.


## Functions
### token0

Returns the address of token0 in the Uniswap V3 pool.

*token0 is the first token in the pair, ordered by address sorting.*


```solidity
function token0() external view returns (address);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|token0 The address of the first token in the pool.|


### token1

Returns the address of token1 in the Uniswap V3 pool.

*token1 is the second token in the pair, ordered by address sorting.*


```solidity
function token1() external view returns (address);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|token1 The address of the second token in the pool.|


### slot0

Returns the slot0 state of the pool, containing multiple values.


```solidity
function slot0()
    external
    view
    returns (
        uint160 sqrtPriceX96,
        int24 tick,
        uint16 observationIndex,
        uint16 observationCardinality,
        uint16 observationCardinalityNext,
        uint8 feeProtocol,
        bool unlocked
    );
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`sqrtPriceX96`|`uint160`|The current sqrt price of the pool as a Q64.96 value.|
|`tick`|`int24`|The current tick of the pool.|
|`observationIndex`|`uint16`|The index of the last oracle observation.|
|`observationCardinality`|`uint16`|The number of observations stored in the pool.|
|`observationCardinalityNext`|`uint16`|The next cardinality to be increased.|
|`feeProtocol`|`uint8`|The protocol fee for both tokens.|
|`unlocked`|`bool`|Whether the pool is currently locked.|


### liquidity

Returns the liquidity available in the pool.


```solidity
function liquidity() external view returns (uint128);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint128`|The available liquidity.|


### fee

Returns the fee amount of the pool.


```solidity
function fee() external view returns (uint24);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint24`|The pool's fee in hundredths of a bip (e.g., 3000 = 0.3%).|


### observe

Fetches historical tick data from the Uniswap V3 oracle.

*This function returns the cumulative tick values for the given time intervals.*


```solidity
function observe(uint32[] calldata secondsAgos)
    external
    view
    returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`secondsAgos`|`uint32[]`|Array of timestamps to fetch tick data for, relative to the current block timestamp.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`tickCumulatives`|`int56[]`|The cumulative tick values at the given timestamps.|
|`secondsPerLiquidityCumulativeX128`|`uint160[]`|Not used in this implementation, but returned for compatibility.|


