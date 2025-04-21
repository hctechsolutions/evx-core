// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./BitMath.sol";

/// @title Packed tick initialized state library
/// @notice Stores a packed mapping of tick index to its initialized state
/// @dev The mapping uses int16 for keys since ticks are represented as int24 and there are 256 (2^8) values per word.
library TickBitmap {
    /// @notice Computes the position in the mapping where the initialized bit for a tick lives
    function position(int24 tick) private pure returns (int16 wordPos, uint8 bitPos) {
        wordPos = int16(tick >> 8);
        bitPos = uint8(uint24(tick));
    }

    /// @notice Flips the initialized state for a given tick
    function flipTick(
        mapping(int16 => uint256) storage self,
        int24 tick,
        int24 tickSpacing
    ) internal {
        require(tick % tickSpacing == 0, "TickBitmap: unspaced tick");
        (int16 wordPos, uint8 bitPos) = position(tick / tickSpacing);
        self[wordPos] ^= (uint256(1) << bitPos);
    }

    /// @notice Returns the next initialized tick within one 256-tick word
    function nextInitializedTickWithinOneWord(
        mapping(int16 => uint256) storage self,
        int24 tick,
        int24 tickSpacing,
        bool  lte
    ) internal view returns (int24 next, bool initialized) {
        int24 compressed = tick / tickSpacing;
        if (tick < 0 && tick % tickSpacing != 0) compressed--; // floor toward −∞

        if (lte) {
            (int16 wordPos, uint8 bitPos) = position(compressed);
            uint256 mask   = (uint256(1) << bitPos) + ((uint256(1) << bitPos) - 1);
            uint256 masked = self[wordPos] & mask;

            initialized = masked != 0;
            if (initialized) {
                uint256 msb = BitMath.mostSignificantBit(masked);
                int256  diff = int256(uint256(bitPos)) - int256(msb);
                next = (compressed - int24(diff)) * tickSpacing;
            } else {
                int256 diff = int256(uint256(bitPos));
                next = (compressed - int24(diff)) * tickSpacing;
            }
        } else {
            (int16 wordPos, uint8 bitPos) = position(compressed + 1);
            uint256 mask   = ~((uint256(1) << bitPos) - 1);
            uint256 masked = self[wordPos] & mask;

            initialized = masked != 0;
            if (initialized) {
                uint256 lsb = BitMath.leastSignificantBit(masked);
                int256  diff = int256(lsb) - int256(uint256(bitPos));
                next = (compressed + 1 + int24(diff)) * tickSpacing;
            } else {
                int256 diff = int256(uint256(type(uint8).max)) - int256(uint256(bitPos));
                next = (compressed + 1 + int24(diff)) * tickSpacing;
            }
        }
    }
}
