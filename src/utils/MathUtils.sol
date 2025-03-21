// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/console.sol";


/**
 * @title MathUtils
 * @dev Library for common mathematical operations used in DeFi protocols.
 */
library MathUtils {
    /// @dev Standard scaling factor (1e18) used for fixed-point arithmetic.
    uint256 internal constant WAD = 1e18;

    /**
     * @notice Multiplies two WAD-scaled numbers with correct rounding.
     * @dev Performs fixed-point multiplication using WAD (1e18 scaling) and applies rounding adjustment.
     *      The formula used is: `(x * y + WAD / 2) / WAD`, which ensures proper rounding.
     * @param x The first operand, scaled to WAD precision (1e18).
     * @param y The second operand, scaled to WAD precision (1e18).
     * @return The product of `x` and `y`, scaled back to WAD precision.
     */
    function wadMul(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x * y + WAD / 2) / WAD;
    }

    /**
     * @notice Divides two numbers while maintaining WAD precision.
     * @dev Performs fixed-point division using WAD (1e18 scaling) with proper rounding.
     *      The formula used is: `(a * WAD + b / 2) / b`, which ensures accurate results.
     * @param a The numerator, expected to be scaled to WAD precision (1e18).
     * @param b The denominator, must be greater than zero.
     * @return The quotient of `a / b`, scaled to WAD precision.
     */
    function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "Division by zero");
        return (a * WAD + b / 2) / b;
    }

    /**
     * @notice Computes the square root of a given number.
     * @dev Uses the Babylonian method for calculating square roots.
     * @param x The number to compute the square root of.
     * @return The square root of x.
     */
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }
}
