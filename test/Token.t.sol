// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@nebula/contracts/GovernanceToken.sol";

/**
 * @title GovernanceTokenTest
 * @dev Unit tests for the GovernanceToken contract.
 */
contract GovernanceTokenTest is Test {
    GovernanceToken public token;
    address public owner = address(1);
    address public user = address(2);

    /**
     * @dev Sets up the test environment by deploying the GovernanceToken contract.
     */
    function setUp() public {
        token = new GovernanceToken(owner);
    }

    /**
     * @dev Tests that the initial supply is correctly minted to the owner.
     */
    function testInitialSupply() public {
        uint256 expectedSupply = 100_000_000 * 10 ** token.decimals();
        assertEq(token.totalSupply(), expectedSupply);
        assertEq(token.balanceOf(owner), expectedSupply);
    }

    /**
     * @dev Tests the token name and symbol.
     */
    function testNameSymbol() public {
        assertEq(token.name(), "Nebula Governance Token");
        assertEq(token.symbol(), "NBL");
    }

    /**
     * @dev Tests the delegation functionality and verifies voting power.
     */
    function testDelegate() public {
        vm.prank(owner);
        token.delegate(owner);
        uint256 ownerVotes = token.getVotes(owner);
        uint256 ownerBalance = token.balanceOf(owner);
        assertEq(ownerVotes, ownerBalance);
    }

    /**
     * @dev Tests that token transfers update voting power accordingly.
     */
    function testTransferUpdatesVotes() public {
        // Owner delegates to itself
        vm.prank(owner);
        token.delegate(owner);

        uint256 initialOwnerBalance = token.balanceOf(owner);
        uint256 initialUserBalance = token.balanceOf(user);
        uint256 initialOwnerVotes = token.getVotes(owner);

        uint256 transferAmount = 1_000 * 10 ** token.decimals();
        vm.prank(owner);
        token.transfer(user, transferAmount);

        uint256 finalOwnerBalance = token.balanceOf(owner);
        uint256 finalUserBalance = token.balanceOf(user);
        uint256 finalOwnerVotes = token.getVotes(owner);

        assertEq(finalOwnerBalance, initialOwnerBalance - transferAmount);
        assertEq(finalUserBalance, initialUserBalance + transferAmount);
        // Voting power of the owner should reflect its new balance
        assertEq(finalOwnerVotes, finalOwnerBalance);
    }

    /**
     * @dev Tests that the nonce for permit functionality increments.
     */
    function testNonces() public {
        uint256 initialNonce = token.nonces(owner);
        assertEq(initialNonce, 0);
    }

}
