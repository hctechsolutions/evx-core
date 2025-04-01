# ChainlinkOracle
[Git Source](https://github.com/jeffersson-abreu/nebula_contracts/blob/8c0ed3db7d893c386ed8057ac0f00d846f64b26e/src/contracts/oracles/ChainLink.sol)

**Inherits:**
[IOracle](/src/interfaces/IOracle.sol/interface.IOracle.md)

Provides price feeds from Chainlink oracles, ensuring price normalization to WAD (1e18).


## State Variables
### priceFeed
Chainlink price feed contract


```solidity
AggregatorV3Interface public immutable priceFeed;
```


### chainlinkDecimals
Number of decimals provided by Chainlink price feed


```solidity
uint8 public immutable chainlinkDecimals;
```


## Functions
### constructor

Initializes the Chainlink oracle with a given price feed.


```solidity
constructor(address _priceFeed);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_priceFeed`|`address`|Address of the Chainlink price feed contract.|


### getPrice

Fetches the latest price from the Chainlink oracle.

*Normalizes the price to WAD (1e18) precision.*


```solidity
function getPrice() external view returns (uint256 price);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`price`|`uint256`|The latest price scaled to WAD.|


