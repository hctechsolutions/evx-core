// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@nebular/lib/SafeMath.sol";

/**
 * @title SafeMathTest
 * @dev Unit tests for the SafeMath library.
 */
contract SafeMathTest is Test {
    uint256 constant WAD = 1e18;

    /**
     * @notice Tests the wadMul function with various cases.
     */
    function testWadMul() public pure {
        // 2.5 * 3.2 = 8.0 (with WAD precision)
        assertEq(SafeMath.wadMul(2.5e18, 3.2e18), 8e18);

        // Multiplication by 1 WAD should return the same value
        assertEq(SafeMath.wadMul(5e18, WAD), 5e18);

        // Multiplication by 0 should always return 0
        assertEq(SafeMath.wadMul(10e18, 0), 0);
        assertEq(SafeMath.wadMul(0, 10e18), 0);

        // Large numbers multiplication (10^10 WAD * 10^10 WAD = 10^20 WAD)
        assertEq(SafeMath.wadMul(1e28, 1e28), 1e38);
    }

    /**
     * @notice Tests the wadDiv function with various cases.
     */
    /// forge-config: default.allow_internal_expect_revert = true
    function testWadDiv() public {
        // 9 / 3 = 3 (with WAD precision)
        assertEq(SafeMath.wadDiv(9e18, 3e18), 3e18);

        // Division by 1 WAD should return the same value
        assertEq(SafeMath.wadDiv(5e18, WAD), 5e18);

        // 5 / 10 = 0.5 (with WAD precision)
        assertEq(SafeMath.wadDiv(5e18, 10e18), 0.5e18);

        // Expect revert on division by zero
        vm.expectRevert();
        SafeMath.wadDiv(1e18, 0);
    }

    /**
     * @notice Tests the sqrt function with various cases.
     */
    function testSqrt() public pure {
        // Perfect squares
        assertEq(SafeMath.sqrt(1), 1);
        assertEq(SafeMath.sqrt(4), 2);
        assertEq(SafeMath.sqrt(9), 3);
        assertEq(SafeMath.sqrt(16), 4);
        assertEq(SafeMath.sqrt(25), 5);

        // Non-perfect square rounding
        assertEq(SafeMath.sqrt(8), 2); // Floor(2.82) = 2
        assertEq(SafeMath.sqrt(18), 4); // Floor(4.24) = 4

        // Large numbers
        assertEq(SafeMath.sqrt(1e36), 1e18);
        assertEq(SafeMath.sqrt(4e36), 2e18);
        assertEq(SafeMath.sqrt(9e36), 3e18);

        // Square root of 0 should return 0
        assertEq(SafeMath.sqrt(0), 0);
    }

        /**
     * @notice Tests the min function with various scenarios.
     */
    function testMin() public pure {
        // Basic comparisons
        assertEq(SafeMath.min(5, 10), 5);
        assertEq(SafeMath.min(10, 5), 5);
        assertEq(SafeMath.min(5, 5), 5);
        
        // Edge cases
        assertEq(SafeMath.min(0, 5), 0);
        assertEq(SafeMath.min(5, 0), 0);
        assertEq(SafeMath.min(type(uint256).max, 5), 5);
        assertEq(SafeMath.min(5, type(uint256).max), 5);
    }

    /**
     * @notice Tests the max function with various scenarios.
     */
    function testMax() public pure {
        // Basic comparisons
        assertEq(SafeMath.max(5, 10), 10);
        assertEq(SafeMath.max(10, 5), 10);
        assertEq(SafeMath.max(5, 5), 5);
        
        // Edge cases
        assertEq(SafeMath.max(0, 5), 5);
        assertEq(SafeMath.max(5, 0), 5);
        assertEq(SafeMath.max(type(uint256).max, 5), type(uint256).max);
        assertEq(SafeMath.max(5, type(uint256).max), type(uint256).max);
    }

    /**
     * @notice Tests the absDiff function with various scenarios.
     */
    function testAbsDiff() public pure {
        // Basic differences
        assertEq(SafeMath.absDiff(5, 3), 2);
        assertEq(SafeMath.absDiff(3, 5), 2);
        assertEq(SafeMath.absDiff(5, 5), 0);
        
        // Edge cases
        assertEq(SafeMath.absDiff(0, 5), 5);
        assertEq(SafeMath.absDiff(5, 0), 5);
        assertEq(SafeMath.absDiff(type(uint256).max, 0), type(uint256).max);
        assertEq(SafeMath.absDiff(0, type(uint256).max), type(uint256).max);
        assertEq(SafeMath.absDiff(type(uint256).max, type(uint256).max), 0);
    }
}
