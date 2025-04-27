// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@nebular/contracts/peripherals/NebularSwapCallee.sol";
import "@nebular/interfaces/callback/INebularSwapCallback.sol";
import "@nebular/libraries/Errors.sol";

contract MockERC20 {
    string public name;
    string public symbol;
    uint8  public constant decimals = 18;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(string memory _n, string memory _s) { name = _n; symbol = _s; }

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

contract MockPoolSwap {
    address public immutable factory;
    address public immutable token0;
    address public immutable token1;

    constructor(address _factory, address _t0, address _t1) {
        factory = _factory;
        token0  = _t0;
        token1  = _t1;
    }

    // signature matches INebularPoolActions
    function swap(
        address /*recipient*/,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 /*sqrtPriceLimitX96*/,
        bytes calldata data
    )
        external
        returns (int256 amount0, int256 amount1)
    {
        // pool wants the exact input token;
        uint256 amt = uint256(amountSpecified);
        if (zeroForOne) {
            amount0 = int256(amt);  // owed token0
            amount1 = 0;
        } else {
            amount0 = 0;
            amount1 = int256(amt);  // owed token1
        }

        // Ask caller (NebularSwapCallee) to pay the delta
        INebularSwapCallback(msg.sender).nebularSwapCallback(
            amount0 > 0 ? amount0 : int256(0),
            amount1 > 0 ? amount1 : int256(0),
            data
        );
    }
}


contract NebularSwapCalleeTest is Test {
    /* ─────────── fixtures ─────────── */

    MockERC20           token0;
    MockERC20           token1;
    NebularSwapCallee   callee;
    MockPoolSwap        pool;
    address             constant FACTORY = address(uint160(uint256(keccak256("neb_factory"))));

    function setUp() public {
        token0 = new MockERC20("Token0", "TK0");
        token1 = new MockERC20("Token1", "TK1");

        callee = new NebularSwapCallee(address(this), FACTORY);
        pool   = new MockPoolSwap(FACTORY, address(token0), address(token1));

        // fund & approve
        token0.mint(address(this), 1e24);
        token0.approve(address(callee), type(uint256).max);
    }

    /* ─────────── tests ─────────── */

    function testSwapExactInputTransfersTokens() public {
        uint256 amountIn = 1e18;

        uint256 balBeforeCallee = token0.balanceOf(address(callee));
        uint256 balBeforePool   = token0.balanceOf(address(pool));

        callee.swapExactInput(
            address(pool),
            address(this),
            true,                // zeroForOne
            amountIn,
            0,                   // sqrtPriceLimitX96 (ignored by mock)
            address(token0),
            address(token1)
        );

        assertEq(token0.balanceOf(address(callee)), balBeforeCallee, "callee balance unchanged");
        assertEq(token0.balanceOf(address(pool)),   balBeforePool   + amountIn, "pool received in");
    }

    function testCallbackRevertsForInvalidPool() public {
        MockPoolSwap bad = new MockPoolSwap(address(0xbeef), address(token0), address(token1));

        bytes memory data = abi.encode(address(token0), address(token1));
        vm.expectRevert(InvalidPool.selector);
        vm.prank(address(bad));
        callee.nebularSwapCallback(int256(1), int256(0), data);
    }
}
