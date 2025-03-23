// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title PositionNFT
 * @notice ERC721 token representing a liquidity position in a decentralized exchange.
 * @dev Each NFT corresponds to a liquidity position with specific price range (ticks).
 */
contract PositionNFT is ERC721, Ownable {
    /// @dev Represents a liquidity position with its parameters.
    struct Position {
        uint256 liquidity; // Amount of liquidity provided
        int24 lowerTick; // Lower bound of the price range
        int24 upperTick; // Upper bound of the price range
    }

    /// @dev Mapping from token ID to liquidity position details.
    mapping(uint256 => Position) public positions;

    /// @dev Counter for the next token ID to be minted.
    uint256 public nextTokenId;

    /**
     * @notice Deploys the PositionNFT contract.
     * @param initialOwner Address that will initially own the contract.
     */
    constructor(address initialOwner) ERC721("Nebular LP Position", "NBLP") Ownable(initialOwner) {}

    /**
     * @notice Mints a new PositionNFT representing a liquidity position.
     * @dev Only the contract owner can mint new positions.
     * @param to The address that will receive the NFT.
     * @param liquidity The amount of liquidity allocated to the position.
     * @param lowerTick The lower bound of the liquidity range.
     * @param upperTick The upper bound of the liquidity range.
     * @return tokenId The ID of the newly minted NFT.
     */
    function mint(address to, uint256 liquidity, int24 lowerTick, int24 upperTick)
        external
        onlyOwner
        returns (uint256 tokenId)
    {
        tokenId = nextTokenId++;
        positions[tokenId] = Position(liquidity, lowerTick, upperTick);
        _safeMint(to, tokenId);
    }

    /**
     * @notice Burns a PositionNFT, removing the liquidity position.
     * @dev Only the contract owner can burn positions.
     * @param tokenId The ID of the NFT to be burned.
     */
    function burn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
        delete positions[tokenId];
    }
}
