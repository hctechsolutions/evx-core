// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@nebular/lib/MathUtils.sol";

/**
 * @title MathUtilsTest
 * @dev Unit tests for the MathUtils library.
 */
contract MathUtilsTest is Test {
    uint256 constant WAD = 1e18;

    /**
     * @notice Tests the wadMul function with various cases.
     */
    function testWadMul() public pure {
        // 2.5 * 3.2 = 8.0 (with WAD precision)
        assertEq(MathUtils.wadMul(2.5e18, 3.2e18), 8e18);

        // Multiplication by 1 WAD should return the same value
        assertEq(MathUtils.wadMul(5e18, WAD), 5e18);

        // Multiplication by 0 should always return 0
        assertEq(MathUtils.wadMul(10e18, 0), 0);
        assertEq(MathUtils.wadMul(0, 10e18), 0);

        // Large numbers multiplication (10^10 WAD * 10^10 WAD = 10^20 WAD)
        assertEq(MathUtils.wadMul(1e28, 1e28), 1e38);
    }

    /**
     * @notice Tests the wadDiv function with various cases.
     */
    /// forge-config: default.allow_internal_expect_revert = true
    function testWadDiv() public {
        // 9 / 3 = 3 (with WAD precision)
        assertEq(MathUtils.wadDiv(9e18, 3e18), 3e18);

        // Division by 1 WAD should return the same value
        assertEq(MathUtils.wadDiv(5e18, WAD), 5e18);

        // 5 / 10 = 0.5 (with WAD precision)
        assertEq(MathUtils.wadDiv(5e18, 10e18), 0.5e18);

        // Expect revert on division by zero
        vm.expectRevert();
        MathUtils.wadDiv(1e18, 0);
    }

    /**
     * @notice Tests the sqrt function with various cases.
     */
    function testSqrt() public pure {
        // Perfect squares
        assertEq(MathUtils.sqrt(1), 1);
        assertEq(MathUtils.sqrt(4), 2);
        assertEq(MathUtils.sqrt(9), 3);
        assertEq(MathUtils.sqrt(16), 4);
        assertEq(MathUtils.sqrt(25), 5);

        // Non-perfect square rounding
        assertEq(MathUtils.sqrt(8), 2); // Floor(2.82) = 2
        assertEq(MathUtils.sqrt(18), 4); // Floor(4.24) = 4

        // Large numbers
        assertEq(MathUtils.sqrt(1e36), 1e18);
        assertEq(MathUtils.sqrt(4e36), 2e18);
        assertEq(MathUtils.sqrt(9e36), 3e18);

        // Square root of 0 should return 0
        assertEq(MathUtils.sqrt(0), 0);
    }

        /**
     * @notice Tests the min function with various scenarios.
     */
    function testMin() public pure {
        // Basic comparisons
        assertEq(MathUtils.min(5, 10), 5);
        assertEq(MathUtils.min(10, 5), 5);
        assertEq(MathUtils.min(5, 5), 5);
        
        // Edge cases
        assertEq(MathUtils.min(0, 5), 0);
        assertEq(MathUtils.min(5, 0), 0);
        assertEq(MathUtils.min(type(uint256).max, 5), 5);
        assertEq(MathUtils.min(5, type(uint256).max), 5);
    }

    /**
     * @notice Tests the max function with various scenarios.
     */
    function testMax() public pure {
        // Basic comparisons
        assertEq(MathUtils.max(5, 10), 10);
        assertEq(MathUtils.max(10, 5), 10);
        assertEq(MathUtils.max(5, 5), 5);
        
        // Edge cases
        assertEq(MathUtils.max(0, 5), 5);
        assertEq(MathUtils.max(5, 0), 5);
        assertEq(MathUtils.max(type(uint256).max, 5), type(uint256).max);
        assertEq(MathUtils.max(5, type(uint256).max), type(uint256).max);
    }

    /**
     * @notice Tests the absDiff function with various scenarios.
     */
    function testAbsDiff() public pure {
        // Basic differences
        assertEq(MathUtils.absDiff(5, 3), 2);
        assertEq(MathUtils.absDiff(3, 5), 2);
        assertEq(MathUtils.absDiff(5, 5), 0);
        
        // Edge cases
        assertEq(MathUtils.absDiff(0, 5), 5);
        assertEq(MathUtils.absDiff(5, 0), 5);
        assertEq(MathUtils.absDiff(type(uint256).max, 0), type(uint256).max);
        assertEq(MathUtils.absDiff(0, type(uint256).max), type(uint256).max);
        assertEq(MathUtils.absDiff(type(uint256).max, type(uint256).max), 0);
    }
}
