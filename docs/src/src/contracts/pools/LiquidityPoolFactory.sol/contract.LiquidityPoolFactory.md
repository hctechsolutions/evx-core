# LiquidityPoolFactory
[Git Source](https://github.com/jeffersson-abreu/nebula_contracts/blob/8c0ed3db7d893c386ed8057ac0f00d846f64b26e/src/contracts/pools/LiquidityPoolFactory.sol)

Factory contract for creating and managing LiquidityPool instances

*Handles the creation of liquidity pools with integrated oracle support*


## State Variables
### liquidityPools
Array of all created liquidity pools


```solidity
LiquidityPool[] public liquidityPools;
```


### getPool
Mapping from token pairs to their respective pool addresses


```solidity
mapping(address => mapping(address => address)) public getPool;
```


## Functions
### createLiquidityPool

Creates a new LiquidityPool with oracle support

*Deploys a complete oracle stack (Chainlink -> Uniswap -> Nebular fallback)*

**Notes:**
- validation: 
- Ensures token addresses are valid (non-zero)
- Ensures tokens are different
- Validates oracle addresses
- Checks for existing pools

- oracle-stack: 
1. ChainlinkOracle: Primary price source
2. UniswapOracle: Secondary price source
3. TWAP: Fallback mechanism


```solidity
function createLiquidityPool(address _token0, address _token1, address _chainLinkPriceFeed, address _uniSwapPoolAddress)
    external
    returns (LiquidityPool pool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_token0`|`address`|First token in the pair|
|`_token1`|`address`|Second token in the pair|
|`_chainLinkPriceFeed`|`address`|Chainlink price feed address|
|`_uniSwapPoolAddress`|`address`|Uniswap V3 pool address|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`pool`|`LiquidityPool`|The created LiquidityPool instance|


### getLiquidityPoolCount

Gets the total number of created pools

*Useful for enumeration and monitoring pool creation activity*


```solidity
function getLiquidityPoolCount() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The current count of liquidity pools|


### poolExists

Checks for existence of a pool for given token pair

*Checks both token orderings (tokenA-tokenB and tokenB-tokenA)*

**Note:**
note: Returns false for zero address inputs


```solidity
function poolExists(address tokenA, address tokenB) external view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenA`|`address`|First token address|
|`tokenB`|`address`|Second token address|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|bool True if pool exists, false otherwise|


## Events
### LiquidityPoolCreated
Emitted when a new liquidity pool is created


```solidity
event LiquidityPoolCreated(address indexed pool, address token0, address token1);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`pool`|`address`|The address of the newly created pool|
|`token0`|`address`|The first token in the pair|
|`token1`|`address`|The second token in the pair|

## Errors
### InvalidTokenAddresses
Error thrown when token addresses are invalid (zero address)


```solidity
error InvalidTokenAddresses();
```

### IdenticalTokens
Error thrown when both tokens in a pair are identical


```solidity
error IdenticalTokens();
```

### InvalidChainlinkFeed
Error thrown when Chainlink price feed address is invalid


```solidity
error InvalidChainlinkFeed();
```

### InvalidUniswapPool
Error thrown when Uniswap pool address is invalid


```solidity
error InvalidUniswapPool();
```

### PoolAlreadyExists
Error thrown when attempting to create an existing pool


```solidity
error PoolAlreadyExists();
```

### ChainlinkOracleCreationFailed
Error thrown when Chainlink oracle creation fails


```solidity
error ChainlinkOracleCreationFailed();
```

### UniswapOracleCreationFailed
Error thrown when Uniswap oracle creation fails


```solidity
error UniswapOracleCreationFailed();
```

