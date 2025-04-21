// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@nebular/contracts/NebularFactory.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @dev Test Suite Summary:
/// - constructor: owner initialization & default fee tiers
/// - createPool: success, revert on invalid input, event emission, token ordering, duplicate prevention
/// - setOwner: success, unauthorized revert, transfer flow
/// - enableFeeAmount: success, revert on invalid fee/tickSpacing, edge boundary tests
/// - noDelegateCall: delegatecall guard protection

/// @title Mock ERC20 for testing
contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 1e24);
    }
}

/// @title Helper to test delegatecall protection
contract DelegateCall {
    function callCreatePool(
        address factory,
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool) {
        (bool success, bytes memory data) =
            factory.delegatecall(
                abi.encodeWithSelector(
                    NebularFactory.createPool.selector,
                    tokenA,
                    tokenB,
                    fee
                )
            );
        // bubble revert if delegatecall fails
        if (!success) {
            assembly { revert(add(data, 0x20), mload(data)) }
        }
        pool = abi.decode(data, (address));
    }
}

/// @title Tests for NebularFactory
contract NebularFactoryTest is Test {
    NebularFactory public factory;
    address public owner;
    MockERC20 public tokenA;
    MockERC20 public tokenB;

    // Mirror events for expectEmit
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);
    event PoolCreated(address indexed token0, address indexed token1, uint24 indexed fee, int24 tickSpacing, address pool);

    function setUp() public {
        factory = new NebularFactory();
        owner = address(this);
        tokenA = new MockERC20("TokenA", "TKA");
        tokenB = new MockERC20("TokenB", "TKB");
    }

    function testConstructorSetsOwnerAndFees() public {
        assertEq(factory.owner(), owner);
        assertEq(factory.feeAmountTickSpacing(500), 10);
        assertEq(factory.feeAmountTickSpacing(3000), 60);
        assertEq(factory.feeAmountTickSpacing(10000), 200);
    }

    function testCreatePoolSuccess() public {
        uint24 fee = 500;
        address pool = factory.createPool(address(tokenA), address(tokenB), fee);
        (address token0, address token1) = address(tokenA) < address(tokenB)
            ? (address(tokenA), address(tokenB))
            : (address(tokenB), address(tokenA));
        assertEq(factory.getPool(token0, token1, fee), pool);
        assertEq(factory.getPool(token1, token0, fee), pool);
    }

    function testCreatePoolRevertsForSameToken() public {
        vm.expectRevert();
        factory.createPool(address(tokenA), address(tokenA), 500);
    }

    function testCreatePoolRevertsForZeroAddress() public {
        vm.expectRevert();
        factory.createPool(address(0), address(tokenB), 500);
    }

    function testCreatePoolRevertsForUnknownFee() public {
        vm.expectRevert();
        factory.createPool(address(tokenA), address(tokenB), 999);
    }

    function testCreatePoolRevertsForDuplicatePool() public {
        uint24 fee = 500;
        factory.createPool(address(tokenA), address(tokenB), fee);
        vm.expectRevert();
        factory.createPool(address(tokenA), address(tokenB), fee);
    }

    function testCreatePoolEmitsEvent() public {
        uint24 fee = 500;
        (address token0, address token1) = address(tokenA) < address(tokenB)
            ? (address(tokenA), address(tokenB))
            : (address(tokenB), address(tokenA));
        vm.expectEmit(true, true, true, false);
        emit PoolCreated(token0, token1, fee, int24(factory.feeAmountTickSpacing(fee)), address(0));
        factory.createPool(address(tokenA), address(tokenB), fee);
    }

    function testCreatePoolOrdering() public {
        uint24 fee = 500;
        address a = address(tokenA);
        address b = address(tokenB);
        (address tokenLow, address tokenHigh) = a < b ? (a, b) : (b, a);
        // pass in reverse order
        address pool = factory.createPool(tokenHigh, tokenLow, fee);
        assertEq(factory.getPool(tokenLow, tokenHigh, fee), pool);
    }

    function testSetOwnerSuccess() public {
        address newOwner = address(0x123);
        vm.expectEmit(true, true, false, true);
        emit OwnerChanged(owner, newOwner);
        factory.setOwner(newOwner);
        assertEq(factory.owner(), newOwner);
    }

    function testSetOwnerRevertsForNonOwner() public {
        vm.prank(address(0x456));
        vm.expectRevert();
        factory.setOwner(address(0x789));
    }

    function testSetOwnerChain() public {
        address newOwner = address(0xABC);
        factory.setOwner(newOwner);
        // old owner no longer able to set
        vm.prank(owner);
        vm.expectRevert();
        factory.setOwner(address(0xDEF));
        // new owner can set again
        vm.prank(newOwner);
        vm.expectEmit(true, true, false, true);
        emit OwnerChanged(newOwner, address(0xDEF));
        factory.setOwner(address(0xDEF));
        assertEq(factory.owner(), address(0xDEF));
    }

    function testEnableFeeAmountSuccess() public {
        uint24 fee = 1000;
        int24 spacing = 20;
        vm.expectEmit(true, true, false, true);
        emit FeeAmountEnabled(fee, spacing);
        factory.enableFeeAmount(fee, spacing);
        assertEq(factory.feeAmountTickSpacing(fee), spacing);
    }

    function testEnableFeeAmountEdgeValues() public {
        uint24 feeMin = 1;
        int24 spaceMin = 1;
        vm.expectEmit(true, true, false, true);
        emit FeeAmountEnabled(feeMin, spaceMin);
        factory.enableFeeAmount(feeMin, spaceMin);
        assertEq(factory.feeAmountTickSpacing(feeMin), spaceMin);

        uint24 feeMax = 999999;
        int24 spaceMax = 16383;
        vm.expectEmit(true, true, false, true);
        emit FeeAmountEnabled(feeMax, spaceMax);
        factory.enableFeeAmount(feeMax, spaceMax);
        assertEq(factory.feeAmountTickSpacing(feeMax), spaceMax);
    }

    function testEnableFeeAmountRevertsForNonOwner() public {
        vm.prank(address(0x456));
        vm.expectRevert();
        factory.enableFeeAmount(2000, 40);
    }

    function testEnableFeeAmountRevertsForInvalidFee() public {
        vm.expectRevert();
        factory.enableFeeAmount(1000000, 10);
    }

    function testEnableFeeAmountRevertsForInvalidTickSpacing() public {
        vm.expectRevert();
        factory.enableFeeAmount(2000, 0);
        vm.expectRevert();
        factory.enableFeeAmount(2000, 16384);
    }

    function testEnableFeeAmountRevertsForDuplicateFee() public {
        vm.expectRevert();
        factory.enableFeeAmount(500, 15);
    }

    function testNoDelegateCallCreatePool() public {
        DelegateCall dc = new DelegateCall();
        vm.expectRevert();
        dc.callCreatePool(address(factory), address(tokenA), address(tokenB), 500);
    }
}
