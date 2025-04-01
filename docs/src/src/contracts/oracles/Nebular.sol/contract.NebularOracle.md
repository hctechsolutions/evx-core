# NebularOracle
[Git Source](https://github.com/jeffersson-abreu/nebula_contracts/blob/8c0ed3db7d893c386ed8057ac0f00d846f64b26e/src/contracts/oracles/Nebular.sol)

**Inherits:**
[IOracle](/src/interfaces/IOracle.sol/interface.IOracle.md)

Manages price updates using Uniswap, Chainlink, and historical averages as fallback.

*Ensures that price updates follow a defined interval and slippage constraints.*


## State Variables
### MAX_SLIPPAGE

```solidity
uint256 public constant MAX_SLIPPAGE = 5e16;
```


### UPDATE_INTERVAL

```solidity
uint32 public constant UPDATE_INTERVAL = 300;
```


### PRICE_HISTORY_SIZE

```solidity
uint256 public constant PRICE_HISTORY_SIZE = 10;
```


### uniswapOracle

```solidity
UniswapOracle public immutable uniswapOracle;
```


### chainlinkOracle

```solidity
ChainlinkOracle public immutable chainlinkOracle;
```


### _historyIndex

```solidity
uint256 private _historyIndex;
```


### _priceHistory

```solidity
PriceData[PRICE_HISTORY_SIZE] private _priceHistory;
```


### lastValidPrice

```solidity
uint256 public lastValidPrice;
```


### lastUpdate

```solidity
uint256 public lastUpdate;
```


## Functions
### constructor

Initializes the NebularOracle with Uniswap and Chainlink oracles.


```solidity
constructor(address _uniswapOracle, address _chainlinkOracle);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_uniswapOracle`|`address`|Address of the Uniswap oracle contract.|
|`_chainlinkOracle`|`address`|Address of the Chainlink oracle contract.|


### updatePrice

Attempts to update the price using Uniswap, Chainlink, or historical average fallback.

*Requires an update interval before fetching new prices.*


```solidity
function updatePrice() external;
```

### priceHistoryLength

Returns the fixed size of the price history array.


```solidity
function priceHistoryLength() external pure returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|PRICE_HISTORY_SIZE The maximum number of historical price records stored.|


### lastUpdated

Returns the last updated time


```solidity
function lastUpdated() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|lastUpdate A timestamp of the last price update|


### priceHistory

Fetches a specific price history entry.


```solidity
function priceHistory(uint256 index) public view returns (uint256 price, uint256 timestamp);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`index`|`uint256`|Index of the historical price entry.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`price`|`uint256`|The price recorded at the given index.|
|`timestamp`|`uint256`|The timestamp of the recorded price.|


### getPrice

Retrieves the latest valid price.


```solidity
function getPrice() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|lastValidPrice The most recent valid price recorded.|


### _updatePrice

Updates the last valid price and maintains a rolling price history.

*Shifts the historical prices left and inserts the new price at the last position.
Emits the PriceUpdated event after updating the state.*


```solidity
function _updatePrice(uint256 newPrice, address source) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newPrice`|`uint256`|The new valid price to be stored.|
|`source`|`address`|The address of the price source (Uniswap, Chainlink, or fallback).|


### tryUniswapPrice


```solidity
function tryUniswapPrice() internal view returns (uint256, bool);
```

### tryChainlinkPrice

Tries to fetch the latest price from Chainlink.


```solidity
function tryChainlinkPrice() internal view returns (uint256, bool);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|price The fetched price.|
|`<none>`|`bool`|valid True if the price is within the allowed slippage range, false otherwise.|


### _isPriceValid

Validates whether the new price is within the allowed slippage range.


```solidity
function _isPriceValid(uint256 newPrice, uint256 referencePrice) internal pure returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newPrice`|`uint256`|The new price being evaluated.|
|`referencePrice`|`uint256`|The last valid price for comparison.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|isValid True if the price is within the acceptable range, false otherwise.|


### calculateHistoricalAverage

Calculates the historical average price from valid recent entries.


```solidity
function calculateHistoricalAverage() internal view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|average The computed average price based on historical data.|


## Events
### PriceUpdated

```solidity
event PriceUpdated(uint256 price, address source, uint256 timestamp);
```

### FallbackUsed

```solidity
event FallbackUsed(address fallbackSource, uint256 timestamp);
```

## Structs
### PriceData

```solidity
struct PriceData {
    uint256 price;
    uint256 timestamp;
}
```

