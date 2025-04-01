# UniswapOracle
[Git Source](https://github.com/jeffersson-abreu/nebula_contracts/blob/8c0ed3db7d893c386ed8057ac0f00d846f64b26e/src/contracts/oracles/Uniswap.sol)

**Inherits:**
[IOracle](/src/interfaces/IOracle.sol/interface.IOracle.md)

Fetches and normalizes token pair prices from a Uniswap V3 pool using TWAP.

*Uses Uniswap V3's `observe` function to get a time-weighted average price (TWAP).*


## State Variables
### pool
Address of the Uniswap V3 pool.


```solidity
IUniswapV3Pool public immutable pool;
```


### token0Decimals
Decimals of token0 and token1.


```solidity
uint8 public immutable token0Decimals;
```


### token1Decimals

```solidity
uint8 public immutable token1Decimals;
```


### TWAP_INTERVAL
TWAP interval (in seconds) for price calculation.


```solidity
uint32 public constant TWAP_INTERVAL = 1800;
```


## Functions
### constructor

Initializes the oracle with a Uniswap V3 pool address.


```solidity
constructor(address _poolAddress);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_poolAddress`|`address`|The address of the Uniswap V3 pool.|


### getPrice

Returns the normalized price of token0 in terms of token1 using TWAP.

*Uses Uniswap V3's oracle to fetch a time-weighted average price (TWAP).*


```solidity
function getPrice() external view returns (uint256 price);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`price`|`uint256`|The price of token0 in token1, normalized to 18 decimals (WAD).|


### getSqrtPriceX96

Converts a tick value to sqrtPriceX96.

*Uses Uniswap V3 tick math to derive the price.*


```solidity
function getSqrtPriceX96(int24 tick) internal pure returns (uint160 sqrtPriceX96);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tick`|`int24`|The average tick value.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`sqrtPriceX96`|`uint160`|The sqrt price corresponding to the tick.|


### normalizePrice

Normalizes a raw price to 18 decimals (WAD).

*Adjusts for token decimals differences.*


```solidity
function normalizePrice(uint256 rawPrice) internal view returns (uint256 wadPrice);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`rawPrice`|`uint256`|The raw price computed from Uniswap V3.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`wadPrice`|`uint256`|The price scaled to 18 decimals.|


