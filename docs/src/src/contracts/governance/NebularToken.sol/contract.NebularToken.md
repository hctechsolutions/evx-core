# NebularToken
[Git Source](https://github.com/jeffersson-abreu/nebula_contracts/blob/b75b76e73206eb62056b1782781cf7d34ff74fa2/src/contracts/governance/NebularToken.sol)

**Inherits:**
ERC20, ERC20Votes, ERC20Permit, Ownable, [INebularToken](/src/contracts/governance/interfaces/INebularToken.sol/interface.INebularToken.md)

Governance token with voting and permit capabilities

*Extends OpenZeppelin's ERC20, ERC20Votes, ERC20Permit, and Ownable*


## Functions
### constructor

Initializes the Nebular Governance Token


```solidity
constructor(address initialOwner)
    ERC20("Nebular Governance Token", "NBL")
    ERC20Permit("Nebular Governance Token")
    Ownable(initialOwner);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`initialOwner`|`address`|Address that will receive the initial supply|


### _update

Internal function to handle token transfers and voting power

*Ensures proper update of voting power and nonces*


```solidity
function _update(address from, address to, uint256 amount) internal override(ERC20, ERC20Votes);
```

### nonces

Returns the current nonce for an owner, required for permit signatures.


```solidity
function nonces(address owner) public view override(INebularToken, ERC20Permit, Nonces) returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`owner`|`address`|The address to query.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The next valid nonce for the owner.|


### getPastVotes

Returns the past voting power of an account at a specific block number.


```solidity
function getPastVotes(address account, uint256 blockNumber)
    public
    view
    override(INebularToken, Votes)
    returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`address`|The address of the token holder.|
|`blockNumber`|`uint256`|The block number at which to retrieve the voting power.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The voting power of the account at the given block.|


