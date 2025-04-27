// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@nebular/contracts/peripherals/NebularFlashCallee.sol";
import "@nebular/interfaces/callback/INebularFlashCallback.sol";
import "@nebular/libraries/Errors.sol";

contract MockERC20 {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    function mint(address to, uint256 amt) external { balanceOf[to] += amt; }
    function transfer(address to, uint256 amt) external returns (bool) {
        balanceOf[msg.sender]-=amt; balanceOf[to]+=amt; return true;
    }
    function approve(address s,uint256 a) external returns(bool){allowance[msg.sender][s]=a;return true;}
    function transferFrom(address f,address t,uint256 a) external returns(bool){
        require(allowance[f][msg.sender]>=a,"allow");
        allowance[f][msg.sender]-=a; balanceOf[f]-=a; balanceOf[t]+=a; return true;
    }
}

contract MockPoolFlash {
    address public immutable factory;
    address public immutable token0;
    address public immutable token1;
    uint256 public constant FEE_BPS = 100; // 1 %

    constructor(address _fac,address _t0,address _t1){factory=_fac;token0=_t0;token1=_t1;}

    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external {
        // send the borrowed amounts to the recipient
        if (amount0 > 0) MockERC20(token0).transfer(recipient, amount0);
        if (amount1 > 0) MockERC20(token1).transfer(recipient, amount1);

        // compute fees and ask caller to repay
        uint256 fee0 = amount0 * FEE_BPS / 10_000;
        uint256 fee1 = amount1 * FEE_BPS / 10_000;

        INebularFlashCallback(msg.sender).nebularFlashCallback(fee0, fee1, data);
    }
}

contract NebularFlashCalleeTest is Test {
    /* ─────────── fixtures ─────────── */

    MockERC20           token0;
    MockERC20           token1;
    NebularFlashCallee  callee;
    MockPoolFlash       pool;
    address constant    FACTORY = address(uint160(uint256(keccak256("neb_factory"))));

    function setUp() public {
        token0 = new MockERC20();
        token1 = new MockERC20();

        callee = new NebularFlashCallee(address(this), FACTORY);
        pool   = new MockPoolFlash(FACTORY, address(token0), address(token1));

        // fund payer (this contract)
        token0.mint(address(this), 1e24);
        token1.mint(address(this), 1e24);

        // approvals
        token0.approve(address(callee), type(uint256).max);  // callee pulls principal
        token1.approve(address(callee), type(uint256).max);

        token0.approve(address(pool),   type(uint256).max);  // pool pulls repayment+fee
        token1.approve(address(pool),   type(uint256).max);
    }

    /* ─────────── tests ─────────── */

    function testFlashBorrowRepaysPrincipalAndFee() public {
        uint256 amt0 = 1e18;
        uint256 amt1 = 2e18;
        uint256 fee0 = amt0 * pool.FEE_BPS() / 10_000;
        uint256 fee1 = amt1 * pool.FEE_BPS() / 10_000;

        uint256 balBefore0 = token0.balanceOf(address(pool));
        uint256 balBefore1 = token1.balanceOf(address(pool));

        callee.flashBorrow(
            address(pool),
            address(this),
            amt0,
            amt1,
            address(token0),
            address(token1)
        );

        assertEq(
            token0.balanceOf(address(pool)),
            balBefore0 + amt0 + fee0,
            "pool should have principal+fee for token0"
        );
        assertEq(
            token1.balanceOf(address(pool)),
            balBefore1 + amt1 + fee1,
            "pool should have principal+fee for token1"
        );
    }

    function testCallbackRevertsForInvalidPool() public {
        MockPoolFlash bad = new MockPoolFlash(address(0xbeef), address(token0), address(token1));
        bytes memory data = abi.encode(address(token0), address(token1), 0, 0, address(this));
        vm.expectRevert(InvalidPool.selector);
        vm.prank(address(bad));
        callee.nebularFlashCallback(0, 0, data);
    }
}
