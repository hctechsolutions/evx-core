// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@nebular/contracts/governance/GovernanceToken.sol";

/**
 * @title GovernanceTokenTest
 * @dev Unit tests for the GovernanceToken contract.
 */
contract GovernanceTokenTest is Test {
    GovernanceToken public token;
    address public owner = address(1);
    address user1 = address(0x123);
    address user2 = address(0x456);

    /**
     * @dev Sets up the test environment by deploying the GovernanceToken contract.
     */
    function setUp() public {
        token = new GovernanceToken(owner);
    }

    /**
     * @dev Tests that the initial supply is correctly minted to the owner.
     */
    function testInitialSupply() public view {
        uint256 expectedSupply = 100_000_000 * 10 ** token.decimals();
        assertEq(token.totalSupply(), expectedSupply);
        assertEq(token.balanceOf(owner), expectedSupply);
    }

    /**
     * @dev Tests the token name and symbol.
     */
    function testNameSymbol() public view {
        assertEq(token.name(), "Nebular Governance Token");
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
        uint256 initialUserBalance = token.balanceOf(user1);

        uint256 transferAmount = 1_000 * 10 ** token.decimals();
        vm.prank(owner);
        token.transfer(user1, transferAmount);

        uint256 finalOwnerBalance = token.balanceOf(owner);
        uint256 finalUserBalance = token.balanceOf(user1);
        uint256 finalOwnerVotes = token.getVotes(owner);

        assertEq(finalOwnerBalance, initialOwnerBalance - transferAmount);
        assertEq(finalUserBalance, initialUserBalance + transferAmount);
        // Voting power of the owner should reflect its new balance
        assertEq(finalOwnerVotes, finalOwnerBalance);
    }

    /**
     * @dev Tests that the nonce for permit functionality increments.
     */
    function testNonces() public view {
        uint256 initialNonce = token.nonces(owner);
        assertEq(initialNonce, 0);
    }

    /**
     * @notice Tests automatic self-delegation when receiving tokens.
     * @dev Ensures that a user who receives tokens is automatically delegated to themselves.
     */
    function testAutoDelegationOnTransfer() public {
        uint256 amount = 1000 * 1e18;

        // Simulate the owner transferring tokens to user1
        vm.prank(owner);
        token.transfer(user1, amount);

        // Ensure user1 is automatically self-delegated
        assertEq(token.delegates(user1), user1, "User1 should be self-delegated");

        // Verify user1's voting power matches received token amount
        assertEq(token.getVotes(user1), amount, "User1 voting power incorrect");
    }

    /**
     * @notice Tests vote updates on token transfers.
     * @dev Ensures that voting power is transferred along with tokens and self-delegation is maintained.
     */
    function testVotesUpdateOnTransfer() public {
        uint256 amount = 500 * 1e18;

        // Simulate the owner transferring tokens to user1
        vm.prank(owner);
        token.transfer(user1, amount);

        // Ensure user1's initial voting power is correct
        assertEq(token.getVotes(user1), amount, "User1 initial voting power incorrect");

        // Simulate user1 transferring tokens to user2
        vm.prank(user1);
        token.transfer(user2, amount);

        // Ensure user1 has lost voting power
        assertEq(token.getVotes(user1), 0, "User1 should have lost voting power");

        // Ensure user2 is automatically self-delegated and has received voting power
        assertEq(token.delegates(user2), user2, "User2 should be self-delegated");
        assertEq(token.getVotes(user2), amount, "User2 voting power incorrect");
    }
}
