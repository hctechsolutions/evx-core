// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@nebula/contracts/LiquidityPool.sol";
import "@nebula/interfaces/IGovernanceToken.sol";

/**
 * @title Reward System
 * @notice Distributes rewards based on liquidity snapshots and multipliers
 */
contract RewardSystem is ReentrancyGuard {
    struct Snapshot {
        uint256 timestamp;
        uint256 totalLP;
    }

    mapping(address => mapping(uint256 => uint256)) public userSnapshots;
    Snapshot[] public poolSnapshots;
    LiquidityPool public pool;
    IGovernanceToken public rewardToken;

    uint256 public rewardRate = 1e18; // 1 token per block (adjustable)
    mapping(address => uint256) public boosters; // Example: ETH/USDC → 2x
    uint256 public constant MAX_BOOSTER = 3; // Maximum allowed booster multiplier

    event RewardsClaimed(address indexed user, uint256 amount);
    event BoosterUpdated(address indexed pair, uint256 multiplier);

    /**
     * @notice Initializes the reward system
     * @param _pool Address of the liquidity pool
     * @param _rewardToken Address of the reward token
     */
    constructor(address _pool, address _rewardToken) {
        pool = LiquidityPool(_pool);
        rewardToken = IGovernanceToken(_rewardToken);
    }

    /**
     * @notice Claims accumulated rewards
     */
    function claimRewards() external nonReentrant {
        uint256 reward = calculateRewards(msg.sender);
        require(reward > 0, "No rewards available");
        // TODO: Call vester to pay the rewards 
        emit RewardsClaimed(msg.sender, reward);
    }

    /**
     * @notice Calculates user rewards based on snapshots and boosters
     * @param user Address of the user
     * @return reward amount
     */
    function calculateRewards(address user) public view returns (uint256) {
        // Complex logic based on snapshots and time (to be implemented)
        return 0;
    }

    /**
     * @notice Sets a booster multiplier for a specific token pair
     * @dev Only callable by the DAO
     * @param pair Token pair address
     * @param multiplier Boost multiplier (capped at MAX_BOOSTER)
     */
    function setBooster(address pair, uint256 multiplier) external {
        require(msg.sender == pool.dao(), "Only DAO can set boosters");
        require(multiplier <= MAX_BOOSTER, "Max booster is 3x");
        boosters[pair] = multiplier;
        emit BoosterUpdated(pair, multiplier);
    }
}
