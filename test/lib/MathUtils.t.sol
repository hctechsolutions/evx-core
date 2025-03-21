// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@nebula/lib/MathUtils.sol";

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
        assertEq(MathUtils.sqrt(8), 2);  // Floor(2.82) = 2
        assertEq(MathUtils.sqrt(18), 4); // Floor(4.24) = 4

        // Large numbers
        assertEq(MathUtils.sqrt(1e36), 1e18);
        assertEq(MathUtils.sqrt(4e36), 2e18);
        assertEq(MathUtils.sqrt(9e36), 3e18);

        // Square root of 0 should return 0
        assertEq(MathUtils.sqrt(0), 0);
    }
}
