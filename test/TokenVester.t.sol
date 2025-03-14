// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@contracts/TokenVester.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor() ERC20("Mock Token", "MOCK") {}
    
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

contract TokenVesterTest is Test {
    MockERC20 public token;
    TokenVester public vesting;

    uint256 public constant CLIFF_DURATION = 365 days;
    uint256 public constant INITIAL_RELEASE = 1e18; // 1 token
    uint256 public constant TOTAL_ALLOCATION = 10e18; // 10 tokens
    uint256 public constant VESTING_DURATION = 2 * 365 days;

    address public owner = address(0x1);
    address public nonOwner = address(0x2);

    function setUp() public {
        // Set up the environment
        vm.startPrank(owner);
        
        // Deploy contracts
        token = new MockERC20();
        vesting = new TokenVester(
            token,
            CLIFF_DURATION,
            INITIAL_RELEASE,
            TOTAL_ALLOCATION,
            VESTING_DURATION,
            owner
        );

        // Mint tokens to the vesting contract
        token.mint(address(vesting), TOTAL_ALLOCATION);
        
        vm.stopPrank();
    }

    // Test 1: Verify initial setup
    function testInitialSetup() public {
        assertEq(address(vesting.token()), address(token));
        assertEq(vesting.start(), block.timestamp);
        assertEq(vesting.cliffDuration(), CLIFF_DURATION);
        assertEq(vesting.initialRelease(), INITIAL_RELEASE);
        assertEq(vesting.totalAllocation(), TOTAL_ALLOCATION);
        assertEq(vesting.vestingDuration(), VESTING_DURATION);
    }

    // Test 2: Before cliff - no tokens released
    function testBeforeCliff() public {
        vm.warp(vesting.start() + CLIFF_DURATION - 1);
        assertEq(vesting.calculateVestedAmount(), 0);
    }

    // Test 3: Release immediately after cliff
    function testAtCliff() public {
        vm.warp(vesting.start() + CLIFF_DURATION);
        assertEq(vesting.calculateVestedAmount(), INITIAL_RELEASE);
    }

    // Test 4: Partial release during vesting
    function testDuringVesting() public {
        uint256 halfVesting = CLIFF_DURATION + (VESTING_DURATION / 2);
        vm.warp(vesting.start() + halfVesting);
        
        uint256 expected = INITIAL_RELEASE + 
            (TOTAL_ALLOCATION - INITIAL_RELEASE) * 
            (halfVesting - CLIFF_DURATION) / 
            VESTING_DURATION;
            
        assertEq(vesting.calculateVestedAmount(), expected);
    }

    // Test 5: After the entire vesting period
    function testAfterVesting() public {
        vm.warp(vesting.start() + CLIFF_DURATION + VESTING_DURATION + 1);
        assertEq(vesting.calculateVestedAmount(), TOTAL_ALLOCATION);
    }

    // Test 6: Release tokens
    function testRelease() public {
        vm.warp(vesting.start() + CLIFF_DURATION + VESTING_DURATION);
        
        uint256 ownerBalanceBefore = token.balanceOf(owner);
        vm.prank(owner);
        vesting.release();
        
        assertEq(token.balanceOf(owner), ownerBalanceBefore + TOTAL_ALLOCATION);
        assertEq(vesting.released(), TOTAL_ALLOCATION);
    }

    // Test 7: Multiple releases
    function testMultipleReleases() public {
        // First release (50% of the period)
        vm.warp(vesting.start() + CLIFF_DURATION + (VESTING_DURATION / 2));
        vm.prank(owner);
        vesting.release();
        
        uint256 firstRelease = INITIAL_RELEASE + 
            (TOTAL_ALLOCATION - INITIAL_RELEASE) * 
            (VESTING_DURATION / 2) / 
            VESTING_DURATION;

        // Second release (100% of the period)
        vm.warp(vesting.start() + CLIFF_DURATION + VESTING_DURATION);
        vm.prank(owner);
        vesting.release();
        
        assertEq(vesting.released(), TOTAL_ALLOCATION);
        assertEq(token.balanceOf(owner), firstRelease + (TOTAL_ALLOCATION - firstRelease));
    }

    // Test 8: Only the owner can release tokens
    function testOnlyOwnerCanRelease() public {
        vm.warp(vesting.start() + CLIFF_DURATION);
        vm.prank(nonOwner);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", nonOwner));
        vesting.release();
    }

    // Test 9: Cannot release without available tokens
    function testNothingToRelease() public {
        vm.warp(vesting.start() + CLIFF_DURATION);
        vm.prank(owner);
        vesting.release(); // Release the first portion
        
        vm.prank(owner);
        vm.expectRevert("No tokens to release");
        vesting.release(); // Try to release again without time change
    }
}