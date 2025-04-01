// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title TokenVester - Vesting contract with multiple release plans
 * @notice This contract handles token vesting with configurable cliff periods, initial releases, and gradual releases.
 * 
 * @dev This contract supports different vesting plans, such as:
 * - **Liquidity Vesting**: No cliff, tokens vest over 4 years.
 * - **Team Vesting**: 1-year cliff, tokens vest over 3 years.
 * - **Seed Investors Vesting**: 6-month cliff, tokens vest over 2 years.
 * - **Marketing Vesting**: Immediate 30% release, remaining tokens vest over 2 years.
 *
 * The contract ensures that tokens are released progressively based on the specified schedules.
 */
contract TokenVester is Ownable {
    using SafeERC20 for IERC20;

    /// @notice The ERC20 token being vested
    IERC20 public immutable token;

    /// @notice The timestamp when the vesting starts
    uint256 public immutable start;

    /// @notice The duration of the cliff period before vesting starts
    uint256 public immutable cliffDuration;

    /// @notice The initial amount of tokens released at the start
    uint256 public immutable initialRelease;

    /// @notice The total amount of tokens allocated for vesting
    uint256 public immutable totalAllocation;

    /// @notice The duration over which the remaining tokens vest linearly
    uint256 public immutable vestingDuration;

    /// @notice The amount of tokens that have been released
    uint256 public released;

    /// @notice Event emitted when tokens are released
    event TokensReleased(uint256 amount);

    /**
     * @notice Initializes the token vesting contract.
     * @dev Ensures valid allocation and vesting duration. Tokens are released gradually over time.
     * @param _token The ERC20 token that will be vested.
     * @param _cliffDuration The duration (in seconds) before vesting starts.
     * @param _initialRelease The number of tokens released immediately at the start.
     * @param _totalAllocation The total amount of tokens allocated for vesting.
     * @param _vestingDuration The duration (in seconds) over which the remaining tokens vest.
     * @param _owner The address that will own the vesting contract.
     */
    constructor(
        IERC20 _token,
        uint256 _cliffDuration,
        uint256 _initialRelease,
        uint256 _totalAllocation,
        uint256 _vestingDuration,
        address _owner
    ) Ownable(_owner) {
        require(_totalAllocation > _initialRelease, "Invalid allocation");
        require(_vestingDuration > 0, "Vesting duration must be greater than 0");

        token = _token;
        start = block.timestamp;
        cliffDuration = _cliffDuration;
        initialRelease = _initialRelease;
        totalAllocation = _totalAllocation;
        vestingDuration = _vestingDuration;
    }

    /**
     * @notice Releases vested tokens to the contract owner.
     * @dev Only the contract owner can call this function. It calculates the total vested tokens,
     * deducts any already released amounts, and transfers the remaining vested tokens.
     * @notice Reverts if no new tokens are available to release.
     */
    function release() external onlyOwner {
        uint256 vested = calculateVestedAmount();
        require(vested > released, "No tokens to release");

        uint256 amount = vested - released;
        released = vested;

        token.safeTransfer(owner(), amount);
        emit TokensReleased(amount);
    }

    /**
     * @notice Calculates the amount of tokens that have vested up to the current block timestamp.
     * @dev The function accounts for the initial release and linearly vests the remaining tokens.
     * If the vesting duration has passed, the full allocation is considered vested.
     * @return The total amount of vested tokens.
     */
    function calculateVestedAmount() public view returns (uint256) {
        if (block.timestamp < start + cliffDuration) {
            return 0; // No tokens are vested before the cliff period ends
        }

        uint256 elapsed = block.timestamp - (start + cliffDuration);
        uint256 vestingAmount = totalAllocation - initialRelease;

        uint256 vestedFromVesting = (vestingAmount * elapsed) / vestingDuration;
        uint256 totalVested = initialRelease + vestedFromVesting;

        return totalVested > totalAllocation ? totalAllocation : totalVested;
    }
}
