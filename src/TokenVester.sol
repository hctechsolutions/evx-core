// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract TokenVester is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public immutable token;
    uint256 public immutable start;
    uint256 public immutable cliffDuration;
    uint256 public immutable initialRelease;
    uint256 public immutable totalAllocation;
    uint256 public immutable vestingDuration;

    uint256 public released;

    event TokensReleased(uint256 amount);

    constructor(
        IERC20 _token,
        uint256 _cliffDuration,
        uint256 _initialRelease,
        uint256 _totalAllocation,
        uint256 _vestingDuration,
        address _owner
    ) Ownable(_owner) {
        require(_totalAllocation > _initialRelease, "Invalid allocation");
        
        token = _token;
        start = block.timestamp;
        cliffDuration = _cliffDuration;
        initialRelease = _initialRelease;
        totalAllocation = _totalAllocation;
        vestingDuration = _vestingDuration;
    }

    function release() external onlyOwner {
        uint256 vested = calculateVestedAmount();
        require(vested > released, "No tokens to release");

        uint256 amount = vested - released;
        released = vested;

        token.safeTransfer(owner(), amount);
        emit TokensReleased(amount);
    }

    function calculateVestedAmount() public view returns (uint256) {
        if (block.timestamp < start + cliffDuration) {
            return 0;
        }

        uint256 elapsed = block.timestamp - (start + cliffDuration);
        uint256 vestingAmount = totalAllocation - initialRelease;

        uint256 vestedFromVesting = vestingAmount * elapsed / vestingDuration;
        uint256 totalVested = initialRelease + vestedFromVesting;

        return totalVested > totalAllocation ? totalAllocation : totalVested;
    }
}