# PositionNFT
[Git Source](https://github.com/jeffersson-abreu/nebula_contracts/blob/5cae3cf31fffc063887e8ff58da33da2f0e0820b/src/contracts/pools/PositionNFT.sol)

**Inherits:**
ERC721, Ownable

ERC721 token representing a liquidity position in a decentralized exchange.

*Each NFT corresponds to a liquidity position with specific price range (ticks).*


## State Variables
### positions
*Mapping from token ID to liquidity position details.*


```solidity
mapping(uint256 => Position) public positions;
```


### nextTokenId
*Counter for the next token ID to be minted.*


```solidity
uint256 public nextTokenId;
```


## Functions
### constructor

Deploys the PositionNFT contract.


```solidity
constructor(address initialOwner) ERC721("Nebula LP Position", "NBLP") Ownable(initialOwner);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`initialOwner`|`address`|Address that will initially own the contract.|


### mint

Mints a new PositionNFT representing a liquidity position.

*Only the contract owner can mint new positions.*


```solidity
function mint(address to, uint256 liquidity, int24 lowerTick, int24 upperTick)
    external
    onlyOwner
    returns (uint256 tokenId);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`to`|`address`|The address that will receive the NFT.|
|`liquidity`|`uint256`|The amount of liquidity allocated to the position.|
|`lowerTick`|`int24`|The lower bound of the liquidity range.|
|`upperTick`|`int24`|The upper bound of the liquidity range.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`tokenId`|`uint256`|The ID of the newly minted NFT.|


### burn

Burns a PositionNFT, removing the liquidity position.

*Only the contract owner can burn positions.*


```solidity
function burn(uint256 tokenId) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenId`|`uint256`|The ID of the NFT to be burned.|


## Structs
### Position
*Represents a liquidity position with its parameters.*


```solidity
struct Position {
    uint256 liquidity;
    int24 lowerTick;
    int24 upperTick;
}
```

