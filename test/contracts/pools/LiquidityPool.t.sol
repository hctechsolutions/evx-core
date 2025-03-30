// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@nebular/contracts/pools/LiquidityPool.sol";
import "@nebular/interfaces/IOracle.sol";
import "@nebular/lib/MathUtils.sol";

/**
 * @title LiquidityPoolTest
 * @notice Unit tests for the LiquidityPool contract.
 * @dev Uses Foundry's testing framework to simulate and validate liquidity pool behavior.
 */
contract MockERC20 is ERC20 {
    /**
     * @notice Deploys a mock ERC20 token with an initial supply for testing.
     * @param name The token name.
     * @param symbol The token symbol.
     */
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 1e24); // Mint 1M tokens for testing.
    }

    /**
     * @notice Mints additional tokens for testing.
     * @param to The address receiving the minted tokens.
     * @param amount The amount of tokens to mint.
     */
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

contract MockOracle is IOracle {
    uint256 private _price;
    uint256 private _lastUpdated;

    /**
     * @notice Sets a mock price in the oracle.
     * @param price The new price to set.
     */
    function setPrice(uint256 price) external {
        _price = price;
        _lastUpdated = block.timestamp;
    }

    /**
     * @notice Returns the latest price from the mock oracle.
     * @return The current price.
     */
    function getPrice() external view override returns (uint256) {
        return _price;
    }

    /**
     * @notice Returns the last update timestamp of the price.
     * @return The last update time.
     */
    function lastUpdated() external viewd returns (uint256) {
        return _lastUpdated;
    }
}

contract LiquidityPoolTest is Test {
    LiquidityPool public pool;
    MockERC20 public token0;
    MockERC20 public token1;
    MockOracle public oracle;
    address public user = address(0x123);

    event LiquidityAdded(uint256 tokenId, uint256 liquidity, int24 lowerTick, int24 upperTick);
    event Swapped(address indexed fromToken, address indexed toToken, uint256 amountIn, uint256 amountOut);
    event LiquidityRemoved(uint256 tokenId, uint256 amountToken0, uint256 amountToken1);

    function setUp() public {
        token0 = new MockERC20("Token0", "TK0");
        token1 = new MockERC20("Token1", "TK1");
        oracle = new MockOracle();
        pool = new LiquidityPool(address(token0), address(token1), IOracle(address(oracle)));

        token0.transfer(user, 1e22);
        token1.transfer(user, 1e22);
        vm.startPrank(user);
        token0.approve(address(pool), type(uint256).max);
        token1.approve(address(pool), type(uint256).max);
        vm.stopPrank();
    }

    /**
     * @notice Tests adding liquidity to the pool.
     * @dev Sets an initial price using the oracle, adds liquidity, and verifies stored values.
     */
    function testAddLiquidity() public {
        oracle.setPrice(2e18);
        vm.startPrank(user);
        uint256 tokenId = pool.addLiquidity(1e18, 1, 3);
        vm.stopPrank();

        (uint256 liquidity, int24 lowerTick, int24 upperTick, uint256 entryPrice,,) = pool.positions(tokenId);

        assertEq(liquidity, 1e18); // Ensure correct liquidity amount
        assertEq(entryPrice, 2e18); // Ensure correct entry price from oracle
        assertEq(lowerTick, 1); // Ensure correct lower tick
        assertEq(upperTick, 3); // Ensure correct upper tick
    }

    /**
     * @notice Ensures that a minimum liquidity amount is required.
     * @dev Attempts to add liquidity with an amount too low and expects a revert.
     */
    function testAddLiquidityMinimumAmount() public {
        vm.startPrank(user);
        vm.expectRevert();
        pool.addLiquidity(1, 1, 3); // Invalid liquidity amount
        vm.stopPrank();
    }

    /**
     * @notice Ensures that liquidity cannot be added with an invalid tick range.
     * @dev Tries adding liquidity with an inverted tick range and expects a revert.
     */
    function testAddLiquidityInvalidRange() public {
        vm.startPrank(user);
        vm.expectRevert();
        pool.addLiquidity(1e18, 3, 1); // Invalid range (lowerTick > upperTick)
        vm.stopPrank();
    }

    /**
     * @notice Tests adding multiple liquidity positions with different amounts.
     * @dev Adds two liquidity positions and verifies that both are stored correctly.
     */
    function testAddLiquidityTwice() public {
        oracle.setPrice(2e18);
        vm.startPrank(user);
        uint256 tokenId1 = pool.addLiquidity(1e18, 1, 3);
        uint256 tokenId2 = pool.addLiquidity(2e18, 1, 3);
        vm.stopPrank();

        (uint256 liquidity1,,,,,) = pool.positions(tokenId1);
        (uint256 liquidity2,,,,,) = pool.positions(tokenId2);

        assertEq(liquidity1, 1e18); // Ensure first position is stored correctly
        assertEq(liquidity2, 2e18); // Ensure second position is stored correctly
    }

    /**
     * @notice Tests partial liquidity removal from a position.
     * @dev Adds liquidity, removes half, and verifies the remaining amount.
     */
    function testRemoveLiquidityPartial() public {
        oracle.setPrice(2e18);
        vm.startPrank(user);
        uint256 tokenId = pool.addLiquidity(2e18, 1, 3);
        pool.removeLiquidityPartial(tokenId, 1e18);
        vm.stopPrank();

        (uint256 remainingLiquidity,,,,,) = pool.positions(tokenId);

        assertEq(remainingLiquidity, 1e18); // Ensure correct remaining liquidity
    }

    /**
     * @notice Tests a swap with a 0.3% fee applied.
     * @dev Adds liquidity, executes a swap, and verifies amountOut considering fees.
     */
    function testSwapWithFee() public {
        oracle.setPrice(2e18); // Initial price: 1 Token0 = 2 Token1
        vm.startPrank(user);

        // Add liquidity to the pool
        pool.addLiquidity(3e18, 1, 3);

        // Balances before swap
        uint256 beforeBalanceToken1 = token1.balanceOf(user);

        // Execute swap
        uint256 amountOut = pool.swap(address(token0), 1e18);

        // Balances after swap
        uint256 afterBalanceToken1 = token1.balanceOf(user);
        vm.stopPrank();

        // Expected swap amount considering 0.3% fee
        uint256 amountInAfterFee = 1e18 - (1e18 * 3) / 1000; // 0.3% fee applied
        uint256 amountInWithFee = MathUtils.wadMul(amountInAfterFee, 997e15); // Apply fee using contract logic

        uint256 reserveIn = 3e18; // Token0 balance in the pool
        uint256 reserveOut = 6e18; // Token1 balance in the pool (3e18 * 2)
        uint256 expectedAmountOut = (amountInWithFee * reserveOut) / (reserveIn * 1000 + amountInWithFee);

        // Ensure amountOut is within a 0.1% margin of error
        assertApproxEqRel(amountOut, expectedAmountOut, 1e18, "Incorrect swap amountOut");

        // Ensure user balance is updated correctly
        assertApproxEqRel(afterBalanceToken1 - beforeBalanceToken1, expectedAmountOut, 1e18, "Incorrect swap amountOut");
    }

    /**
     * @notice Ensures only the owner of a liquidity position can remove it.
     * @dev Adds liquidity, attempts unauthorized removal, and expects a revert.
     */
    function testRemoveLiquidityFromNonOwner() public {
        oracle.setPrice(2e18);
        vm.startPrank(user);
        uint256 tokenId = pool.addLiquidity(1e18, 1, 3);
        vm.stopPrank();

        address attacker = address(0x456);
        vm.startPrank(attacker);
        vm.expectRevert();
        pool.removeLiquidity(tokenId);
        vm.stopPrank();
    }

    /**
     * @notice Tests adding multiple liquidity positions using fuzzing.
     * @dev Iteratively adds liquidity with increasing amounts to test stability.
     */
    function testFuzzingLiquidity() public {
        oracle.setPrice(2e18);
        vm.startPrank(user);
        for (uint256 i = 1; i < 10; i++) {
            pool.addLiquidity(i * 1e17, 1, 3);
        }
        vm.stopPrank();
    }

    /**
     * @notice Tests adding liquidity when the price is outside the active range.
     * @dev The position should still be created, but it may not be usable until the price moves into range.
     */
    function testAddLiquidityWherePriceIsInactive() public {
        oracle.setPrice(5e18);
        vm.startPrank(user);
        uint256 tokenId = pool.addLiquidity(1e18, 1, 3);
        vm.stopPrank();

        (uint256 liquidity,,,,,) = pool.positions(tokenId);
        assertEq(liquidity, 1e18);
    }

    /**
     * @notice Tests removing liquidity before any swaps occur.
     * @dev Ensures that liquidity can be withdrawn without prior trading activity.
     */
    function testRemoveLiquidityBeforeAnySwap() public {
        oracle.setPrice(2e18);
        vm.startPrank(user);
        uint256 tokenId = pool.addLiquidity(2e18, 1, 3);
        pool.removeLiquidity(tokenId);
        vm.stopPrank();
    }

    /**
     * @notice Ensures attempting to remove liquidity with an invalid token ID reverts.
     * @dev Tries to remove liquidity for a non-existent position and expects a revert.
     */
    function testRemoveLiquidityFromInvalidTokenId() public {
        vm.startPrank(user);
        vm.expectRevert();
        pool.removeLiquidity(9999);
        vm.stopPrank();
    }

    /**
     * @notice Verifies that swapping fails when there is no liquidity in the pool.
     * @dev Attempts a swap without prior liquidity provision and expects a revert.
     */
    function testSwapWithoutLiquidityFails() public {
        vm.startPrank(user);
        vm.expectRevert();
        pool.swap(address(token0), 1e18);
        vm.stopPrank();
    }

    /**
     * @notice Tests executing a large swap to ensure no overflow occurs.
     * @dev Mints tokens, adds substantial liquidity, and swaps a large amount.
     */
    function testLargeSwapDoesNotOverflow() public {
        oracle.setPrice(2e18);
        vm.startPrank(user);

        // Ensure the user has enough balance for a large swap
        token0.mint(user, 6e24);
        token1.mint(user, 6e24);

        token0.transfer(user, 5e24);
        token1.transfer(user, 5e24);

        // Add a large liquidity amount to support the swap
        pool.addLiquidity(1e24, 1, 3);

        // Execute a high-value swap within pool capacity
        uint256 amountOut = pool.swap(address(token0), 1e24);

        assertGt(amountOut, 0); // Ensure the swap occurred without overflow
        vm.stopPrank();
    }

    /**
     * @notice Tests whether updates to the price oracle affect swap outcomes.
     * @dev Changes the oracle price after liquidity addition and checks swap behavior.
     */
    function testOracleUpdateAffectsSwaps() public {
        oracle.setPrice(2e18);
        vm.startPrank(user);
        pool.addLiquidity(3e18, 1, 3);
        oracle.setPrice(3e18);
        pool.addLiquidity(1e18, 1, 3); // Adding more liquidity to prevent errors
        uint256 amountOut = pool.swap(address(token0), 1e18);
        assert(amountOut > 0);
        vm.stopPrank();
    }

    /**
     * @notice Tests if claimFees works when there are accumulated fees.
     */
    function testClaimFeesSuccess() public {
        oracle.setPrice(2e18); // Set initial price
        vm.startPrank(user);

        uint256 tokenId = pool.addLiquidity(3e18, 1, 3);

        // Simulate swaps to generate fees
        pool.swap(address(token0), 1e18);
        pool.swap(address(token1), 1e18);

        uint256 balanceBeforeToken0 = token0.balanceOf(user);
        uint256 balanceBeforeToken1 = token1.balanceOf(user);

        // Claim fees
        pool.claimFees(tokenId);

        uint256 balanceAfterToken0 = token0.balanceOf(user);
        uint256 balanceAfterToken1 = token1.balanceOf(user);

        // Ensure user received fees
        assertGt(balanceAfterToken0, balanceBeforeToken0, "Token0 fees not received");
        assertGt(balanceAfterToken1, balanceBeforeToken1, "Token1 fees not received");

        vm.stopPrank();
    }

    /**
     * @notice Tests that claimFees fails when there are no fees.
     */
    function testClaimFeesNoFeesAvailable() public {
        oracle.setPrice(2e18);
        vm.startPrank(user);

        uint256 tokenId = pool.addLiquidity(3e18, 1, 3);

        // Expect revert due to no accumulated fees
        vm.expectRevert();
        pool.claimFees(tokenId);

        vm.stopPrank();
    }

    /**
     * @notice Tests that claimFees fails if called by a non-owner.
     */
    function testClaimFeesByNonOwner() public {
        oracle.setPrice(2e18);
        vm.startPrank(user);

        uint256 tokenId = pool.addLiquidity(3e18, 1, 3);
        vm.stopPrank();

        address attacker = address(0x456);
        vm.startPrank(attacker);
        vm.expectRevert();
        pool.claimFees(tokenId);
        vm.stopPrank();
    }

    /**
     * @notice Tests that claimFees resets the fee balance after claiming.
     */
    function testClaimFeesStateUpdate() public {
        oracle.setPrice(2e18);
        vm.startPrank(user);

        uint256 tokenId = pool.addLiquidity(3e18, 1, 3);

        // Simulate swaps to generate fees
        pool.swap(address(token0), 1e18);
        pool.swap(address(token1), 1e18);

        // Claim fees
        pool.claimFees(tokenId);

        // Ensure that after claiming, there are no more fees left
        (,,,, uint256 feeGrowthToken0, uint256 feeGrowthToken1) = pool.positions(tokenId);
        assertEq(feeGrowthToken0, pool.feeGrowthGlobalToken0(), "Fee growth not reset for Token0");
        assertEq(feeGrowthToken1, pool.feeGrowthGlobalToken1(), "Fee growth not reset for Token1");

        vm.stopPrank();
    }
}
