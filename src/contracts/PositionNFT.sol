// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "forge-std/console.sol";


contract PositionNFT is ERC721, Ownable {

    struct Position {
        uint256 liquidity;
        int24 lowerTick;
        int24 upperTick;
    }

    mapping(uint256 => Position) public positions;
    uint256 public nextTokenId;

    constructor(address initialOwner)
        ERC721("Nebula LP Position", "NBLP")
        Ownable(initialOwner)
    {}
    
    function mint(address to, uint256 liquidity, int24 lowerTick, int24 upperTick) external onlyOwner returns (uint256 tokenId) {
        tokenId = nextTokenId++;
        positions[tokenId] = Position(liquidity, lowerTick, upperTick);
        _safeMint(to, tokenId);
    }

    function burn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
        delete positions[tokenId];
    }
}