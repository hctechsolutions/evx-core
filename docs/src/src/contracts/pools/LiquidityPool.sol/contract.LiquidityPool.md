# LiquidityPool
[Git Source](https://github.com/jeffersson-abreu/nebula_contracts/blob/ec613b8e4edfc995d98c4c7aaaac9edf0c72aed1/src/contracts/pools/LiquidityPool.sol)

**Inherits:**
ReentrancyGuard

Automated Market Maker (AMM) with Concentrated Liquidity (simplified and optimized version)

*Inspired by Uniswap V3, it allows liquidity providers to add liquidity within specific price ranges.*


## State Variables
### positions

```solidity
mapping(uint256 => Position) public positions;
```


### feeGrowthGlobalToken0

```solidity
uint256 public feeGrowthGlobalToken0;
```


### feeGrowthGlobalToken1

```solidity
uint256 public feeGrowthGlobalToken1;
```


### totalLiquidity

```solidity
uint256 public totalLiquidity;
```


### positionNFT

```solidity
PositionNFT public positionNFT;
```


### token0

```solidity
address public immutable token0;
```


### token1

```solidity
address public immutable token1;
```


### oracle

```solidity
IPriceOracle public oracle;
```


### fee

```solidity
uint256 public fee = 3;
```


## Functions
### constructor

Initializes the liquidity pool with two tokens and an oracle.


```solidity
constructor(address _token0, address _token1, IPriceOracle _oracle);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_token0`|`address`|Address of the first token in the pair.|
|`_token1`|`address`|Address of the second token in the pair.|
|`_oracle`|`IPriceOracle`|Address of the price oracle.|


### calculateTokenAmounts

Calculates token amounts based on liquidity, price, and tick limits.
- If the normalized price (price/WAD) is ≤ lowerTick, all liquidity is converted to token0.
- If it is ≥ upperTick, all liquidity is converted to token1.
- Otherwise, the calculation follows:
token0 = (liquidity * WAD) / (price + WAD)
token1 = liquidity - token0


```solidity
function calculateTokenAmounts(uint256 liquidity, uint256 price, int24 lowerTick, int24 upperTick)
    internal
    pure
    returns (uint256 amountToken0, uint256 amountToken1);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`liquidity`|`uint256`|The amount of liquidity provided.|
|`price`|`uint256`|The current price from the oracle.|
|`lowerTick`|`int24`|The lower tick boundary of the position.|
|`upperTick`|`int24`|The upper tick boundary of the position.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`amountToken0`|`uint256`|The calculated amount of token0.|
|`amountToken1`|`uint256`|The calculated amount of token1.|


### claimFees


```solidity
function claimFees(uint256 tokenId) external nonReentrant;
```

### addLiquidity

Adds liquidity to the pool and mints an NFT representing the position.


```solidity
function addLiquidity(uint256 liquidity, int24 lowerTick, int24 upperTick)
    external
    nonReentrant
    returns (uint256 tokenId);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`liquidity`|`uint256`|The amount of liquidity to add.|
|`lowerTick`|`int24`|The lower tick boundary of the position.|
|`upperTick`|`int24`|The upper tick boundary of the position.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`tokenId`|`uint256`|The unique identifier of the newly created position.|


### removeLiquidity

Removes liquidity from the pool and burns the position NFT.


```solidity
function removeLiquidity(uint256 tokenId) external nonReentrant;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenId`|`uint256`|The unique identifier of the liquidity position.|


### removeLiquidityPartial

Partially removes liquidity from a position.


```solidity
function removeLiquidityPartial(uint256 tokenId, uint256 liquidityAmount) external nonReentrant;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenId`|`uint256`|The unique identifier of the liquidity position.|
|`liquidityAmount`|`uint256`|The amount of liquidity to remove.|


### swap

Swaps tokens within the pool.


```solidity
function swap(address tokenIn, uint256 amountIn) external nonReentrant returns (uint256 amountOut);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenIn`|`address`|The token being exchanged.|
|`amountIn`|`uint256`|The amount of tokenIn being swapped.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`amountOut`|`uint256`|The amount of tokenOut received.|


## Events
### LiquidityAdded
Emitted when liquidity is added to the pool.


```solidity
event LiquidityAdded(address indexed user, uint256 tokenId, uint256 liquidity, int24 lowerTick, int24 upperTick);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|The address adding liquidity.|
|`tokenId`|`uint256`|The ID of the newly created position.|
|`liquidity`|`uint256`|The amount of liquidity added.|
|`lowerTick`|`int24`|The lower tick boundary of the position.|
|`upperTick`|`int24`|The upper tick boundary of the position.|

### LiquidityRemoved
Emitted when liquidity is removed from the pool.


```solidity
event LiquidityRemoved(address indexed user, uint256 tokenId, uint256 liquidity);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|The address removing liquidity.|
|`tokenId`|`uint256`|The ID of the position being removed.|
|`liquidity`|`uint256`|The amount of liquidity removed.|

### Swap
Emitted when a token swap occurs.


```solidity
event Swap(address indexed user, address tokenIn, uint256 amountIn, uint256 amountOut);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|The address executing the swap.|
|`tokenIn`|`address`|The token being swapped in.|
|`amountIn`|`uint256`|The amount of tokenIn provided.|
|`amountOut`|`uint256`|The amount of tokenOut received.|

## Structs
### Position
*Represents a liquidity position within the pool.
- `liquidity`: The amount of liquidity provided.
- `lowerTick`: The lower price tick at which liquidity is active.
- `upperTick`: The upper price tick at which liquidity is active.
- `entryPrice`: The price at the moment liquidity was added.
- `feeGrowthInsideToken0`: The accumulated fee growth for token0 within the position.
- `feeGrowthInsideToken1`: The accumulated fee growth for token1 within the position.*


```solidity
struct Position {
    uint256 liquidity;
    int24 lowerTick;
    int24 upperTick;
    uint256 entryPrice;
    uint256 feeGrowthInsideToken0;
    uint256 feeGrowthInsideToken1;
}
```

