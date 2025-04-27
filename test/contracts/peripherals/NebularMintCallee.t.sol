// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@nebular/contracts/peripherals/NebularMintCallee.sol";
import "@nebular/interfaces/callback/INebularMintCallback.sol";
import "@nebular/libraries/Errors.sol";

contract MockERC20 {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    function mint(address to, uint256 amt) external { balanceOf[to] += amt; }
    function transfer(address to, uint256 amt) external returns (bool) {
        balanceOf[msg.sender] -= amt; balanceOf[to] += amt; return true;
    }
    function approve(address s, uint256 a) external returns (bool) { allowance[msg.sender][s] = a; return true; }
    function transferFrom(address f,address t,uint256 a) external returns(bool){
        require(allowance[f][msg.sender] >= a, "allow");
        allowance[f][msg.sender]-=a; balanceOf[f]-=a; balanceOf[t]+=a; return true;
    }
}

contract MockPoolMint {
    address public immutable factory;
    address public immutable token0;
    address public immutable token1;
    uint256 public constant AMOUNT0 = 5e17;
    uint256 public constant AMOUNT1 = 2e17;

    constructor(address _fac,address _t0,address _t1){factory=_fac;token0=_t0;token1=_t1;}

    function mint(
        address /*recipient*/,
        int24 /*tickLower*/,
        int24 /*tickUpper*/,
        uint128 /*amount*/,
        bytes calldata data
    ) external returns (uint256, uint256) {
        // request owed tokens
        INebularMintCallback(msg.sender).nebularMintCallback(AMOUNT0, AMOUNT1, data);
        return (AMOUNT0, AMOUNT1);
    }
}

contract NebularMintCalleeTest is Test {
    /* ─────────── mocks ─────────── */

    MockERC20         token0;
    MockERC20         token1;
    NebularMintCallee callee;
    MockPoolMint      pool;
    address constant  FACTORY = address(uint160(uint256(keccak256("neb_factory"))));

    function setUp() public {
        token0 = new MockERC20();
        token1 = new MockERC20();

        callee = new NebularMintCallee(address(this), FACTORY);
        pool   = new MockPoolMint(FACTORY, address(token0), address(token1));

        // fund callee so it can repay
        token0.mint(address(callee), 1e18);
        token1.mint(address(callee), 1e18);
    }

    function testAddLiquidityPaysOwedAmounts() public {
        uint256 b0before = token0.balanceOf(address(pool));
        uint256 b1before = token1.balanceOf(address(pool));

        callee.addLiquidity(
            address(pool),
            address(this),
            -10,
            10,
            1000,
            address(token0),
            address(token1)
        );

        assertEq(token0.balanceOf(address(pool)) - b0before, pool.AMOUNT0(), "paid token0");
        assertEq(token1.balanceOf(address(pool)) - b1before, pool.AMOUNT1(), "paid token1");
    }

    function testCallbackRevertsForInvalidPool() public {
        MockPoolMint bad = new MockPoolMint(address(0xbeef), address(token0), address(token1));
        bytes memory data = abi.encode(address(token0), address(token1));
        vm.expectRevert(InvalidPool.selector);
        vm.prank(address(bad));
        callee.nebularMintCallback(1, 1, data);
    }
}
