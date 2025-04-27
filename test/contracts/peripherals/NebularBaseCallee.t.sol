// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@nebular/contracts/peripherals/NebularCalleeBase.sol";
import "@nebular/libraries/Errors.sol";

contract MockERC20 {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function mint(address to, uint256 amt) external { balanceOf[to] += amt; }

    function transfer(address to, uint256 amt) external returns (bool) {
        balanceOf[msg.sender] -= amt;
        balanceOf[to] += amt;
        return true;
    }

    function approve(address spender, uint256 amt) external returns (bool) {
        allowance[msg.sender][spender] = amt;
        return true;
    }

    function transferFrom(address from, address to, uint256 amt) external returns (bool) {
        require(allowance[from][msg.sender] >= amt, "allow");
        allowance[from][msg.sender] -= amt;
        balanceOf[from] -= amt;
        balanceOf[to] += amt;
        return true;
    }
}

contract MockPool {
    address public immutable factory;
    constructor(address _factory) { factory = _factory; }
}

/* ─────────── callee (exposes verify) ─────────── */

contract ExposedCallee is NebularCalleeBase {
    constructor(address owner_, address fac_) NebularCalleeBase(owner_, fac_) {}
    function exposedVerify() external view { _verifyPool(); }
    // helper to receive native in tests
    function deposit() external payable {}
}

contract NebularCalleeBaseTest is Test {
    address              constant FACTORY = address(uint160(uint256(keccak256("neb_factory"))));
    ExposedCallee        callee;
    MockERC20            token;
    address              user   = address(0xBEEF);
    address              other  = address(0xCAFE);

    function setUp() public {
        callee = new ExposedCallee(address(this), FACTORY);
        token  = new MockERC20();
    }

    function testSweepTokenHappyPath() public {
        token.mint(address(callee), 1e18);
        uint256 before = token.balanceOf(user);

        callee.sweepToken(address(token), user, 1e18);

        assertEq(token.balanceOf(user) - before, 1e18);
        assertEq(token.balanceOf(address(callee)), 0);
    }

    function testSweepTokenZeroAddressReverts() public {
        vm.expectRevert(ZeroAddress.selector);
        callee.sweepToken(address(token), address(0), 1);
    }

    function testSweepTokenNonOwnerReverts() public {
        vm.prank(other);
        vm.expectRevert();
        callee.sweepToken(address(token), user, 1);
    }

    /* ─────────── sweepNative ─────────── */

    function testSweepNativeHappyPath() public {
        // deposite 1 ether na callee
        vm.deal(address(this), 2 ether);
        callee.deposit{value: 1 ether}();

        uint256 balBefore = user.balance;

        callee.sweepNative(user, 1 ether);

        assertEq(user.balance - balBefore, 1 ether);
        assertEq(address(callee).balance, 0);
    }

    function testSweepNativeZeroAddressReverts() public {
        vm.expectRevert(ZeroAddress.selector);
        callee.sweepNative(address(0), 1);
    }

    function testSweepNativeNonOwnerReverts() public {
        vm.prank(other);
        vm.expectRevert();
        callee.sweepNative(user, 1);
    }

    /* ─────────── _verifyPool ─────────── */

    function testVerifyPoolAcceptsValidPool() public {
        MockPool pool = new MockPool(FACTORY);
        vm.prank(address(pool));
        callee.exposedVerify(); // should NOT revert
    }

    function testVerifyPoolRejectsInvalidPool() public {
        MockPool bad = new MockPool(address(0xDEAD));
        vm.prank(address(bad));
        vm.expectRevert(InvalidPool.selector);
        callee.exposedVerify();
    }
}
