// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {PositionNFT} from "@nebula/contracts/pools/PositionNFT.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract PositionNFTTest is Test {
    PositionNFT public positionNFT;
    address public owner = address(0x123);
    address public user = address(0x456);

    function setUp() public {
        // Deploy the PositionNFT contract with the owner address
        positionNFT = new PositionNFT(owner);
    }

    /**
     * @dev Tests that the NFT is minted correctly.
     */
    function testMintNFT() public {
        // Parameters for the new position
        uint256 liquidity = 1000;
        int24 lowerTick = -100;
        int24 upperTick = 100;

        // Mint the NFT as the owner
        vm.prank(owner);
        uint256 tokenId = positionNFT.mint(user, liquidity, lowerTick, upperTick);

        // Verify the token ID
        assertEq(tokenId, 0, "Token ID should be 0");

        // Verify the position data
        (uint256 posLiquidity, int24 posLowerTick, int24 posUpperTick) = positionNFT.positions(tokenId);
        assertEq(posLiquidity, liquidity, "Liquidity mismatch");
        assertEq(posLowerTick, lowerTick, "Lower tick mismatch");
        assertEq(posUpperTick, upperTick, "Upper tick mismatch");

        // Verify the owner of the NFT
        assertEq(positionNFT.ownerOf(tokenId), user, "NFT owner mismatch");

        // Verify the nextTokenId is incremented
        assertEq(positionNFT.nextTokenId(), 1, "nextTokenId should be 1");
    }

    /**
     * @dev Tests that only the owner can mint NFTs.
     */
    function testOnlyOwnerCanMint() public {
        // Attempt to mint as a non-owner
        vm.prank(user);
        vm.expectRevert();
        positionNFT.mint(user, 1000, -100, 100);
    }

    /**
     * @dev Tests that the NFT is burned correctly.
     */
    function testBurnNFT() public {
        // Mint an NFT first
        vm.prank(owner);
        uint256 tokenId = positionNFT.mint(user, 1000, -100, 100);

        // Burn the NFT as the owner
        vm.prank(owner);
        positionNFT.burn(tokenId);

        // Verify the NFT is burned
        vm.expectRevert();
        positionNFT.ownerOf(tokenId);

        // Verify the position data is deleted
        (uint256 posLiquidity, int24 posLowerTick, int24 posUpperTick) = positionNFT.positions(tokenId);
        assertEq(posLiquidity, 0, "Liquidity should be 0 after burn");
        assertEq(posLowerTick, 0, "Lower tick should be 0 after burn");
        assertEq(posUpperTick, 0, "Upper tick should be 0 after burn");
    }

    /**
     * @dev Tests that only the owner can burn NFTs.
     */
    function testOnlyOwnerCanBurn() public {
        // Mint an NFT first
        vm.prank(owner);
        uint256 tokenId = positionNFT.mint(user, 1000, -100, 100);

        // Attempt to burn as a non-owner
        vm.prank(user);
        vm.expectRevert();
        positionNFT.burn(tokenId);
    }

    /**
     * @dev Tests that the Transfer event is emitted on mint.
     */
    function testEmitTransferEventOnMint() public {
        // Expect the Transfer event to be emitted
        vm.expectEmit(true, true, true, true);
        emit IERC721.Transfer(address(0), user, 0);

        // Mint the NFT as the owner
        vm.prank(owner);
        positionNFT.mint(user, 1000, -100, 100);
    }

    /**
     * @dev Tests that the Transfer event is emitted on burn.
     */
    function testEmitTransferEventOnBurn() public {
        // Mint an NFT first
        vm.prank(owner);
        uint256 tokenId = positionNFT.mint(user, 1000, -100, 100);

        // Expect the Transfer event to be emitted
        vm.expectEmit(true, true, true, true);
        emit IERC721.Transfer(user, address(0), tokenId);

        // Burn the NFT as the owner
        vm.prank(owner);
        positionNFT.burn(tokenId);
    }
}