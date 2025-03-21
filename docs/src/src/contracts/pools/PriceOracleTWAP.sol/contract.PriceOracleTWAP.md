# PriceOracleTWAP
[Git Source](https://github.com/jeffersson-abreu/nebula_contracts/blob/713b150e780334d0bd03d6604842282ffc694e40/src/contracts/pools/PriceOracleTWAP.sol)

**Inherits:**
[IPriceOracle](/src/interfaces/IPriceOracle.sol/interface.IPriceOracle.md), Ownable

Aggregates multiple data sources with fallback mechanisms

*Uses Chainlink, TWAP, and Band Protocol with a consensus mechanism*


## State Variables
### oracles

```solidity
OracleConfig[] public oracles;
```


### lastValidPrice

```solidity
uint256 public lastValidPrice;
```


### lastUpdated

```solidity
uint256 public lastUpdated;
```


## Functions
### constructor

Initializes the PriceOracleTWAP contract


```solidity
constructor(address initialOwner) Ownable(initialOwner);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`initialOwner`|`address`|The address that will be the initial owner of the contract|


### addOracle

Adds a new oracle configuration

*Only callable by the contract owner*


```solidity
function addOracle(address source, uint256 maxDeviationBps, uint256 heartbeat, uint8 decimals) external onlyOwner;
```

### consult

Fetches asset price using a consensus mechanism

*Implements 2/3 majority validation for reliability*


```solidity
function consult() external override returns (uint256);
```

### _isPriceValid

Validates if a price is within an acceptable deviation range

*Ensures price fluctuations remain within a 5% deviation from the last valid price*


```solidity
function _isPriceValid(uint256 price) internal view returns (bool);
```

## Events
### OracleFailure

```solidity
event OracleFailure(uint256 timestamp, string reason);
```

### OracleAdded

```solidity
event OracleAdded(address indexed source, uint256 maxDeviationBps, uint256 heartbeat, uint8 decimals);
```

## Structs
### OracleConfig

```solidity
struct OracleConfig {
    address source;
    uint256 maxDeviationBps;
    uint256 heartbeat;
    uint8 decimals;
}
```

