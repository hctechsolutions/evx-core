# GovernanceToken
[Git Source](https://github.com/jeffersson-abreu/nebula_contracts/blob/ec613b8e4edfc995d98c4c7aaaac9edf0c72aed1/src/contracts/governance/GovernanceToken.sol)

**Inherits:**
ERC20, ERC20Votes, ERC20Permit, Ownable, [IGovernanceToken](/src/interfaces/IGovernanceToken.sol/interface.IGovernanceToken.md)

Governance token with voting and permit capabilities

*Extends OpenZeppelin's ERC20, ERC20Votes, ERC20Permit, and Ownable*


## Functions
### constructor

Initializes the Nebula Governance Token


```solidity
constructor(address initialOwner)
    ERC20("Nebula Governance Token", "NBL")
    ERC20Permit("Nebula Governance Token")
    Ownable(initialOwner);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`initialOwner`|`address`|Address that will receive the initial supply|


### _update

Internal function to handle token transfers

*Ensures proper update of voting power and nonces*


```solidity
function _update(address from, address to, uint256 amount) internal override(ERC20, ERC20Votes);
```

### nonces

Returns the number of permits (nonces) used by an address


```solidity
function nonces(address owner) public view override(ERC20Permit, Nonces) returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`owner`|`address`|Address of the token holder|


### getPastVotes

Returns past voting power of an account at a specific block


```solidity
function getPastVotes(address account, uint256 blockNumber)
    public
    view
    override(IGovernanceToken, Votes)
    returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`address`|Address of the token holder|
|`blockNumber`|`uint256`|Block number for historical voting power lookup|


