// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@nebular/contracts/pools/PositionNFT.sol";
import "@nebular/interfaces/IGovernanceToken.sol";

contract RewardSystem {
    IGovernanceToken public rewardToken;
    PositionNFT public positionNFT;

    event RewardsClaimed(address indexed user, uint256 amount);

    constructor(address _rewardToken, address _positionNFT) {
        rewardToken = IGovernanceToken(_rewardToken);
        positionNFT = PositionNFT(_positionNFT);
    }

    function claimRewards(uint256 tokenId) external {
        require(positionNFT.ownerOf(tokenId) == msg.sender, "Not the owner");
        // Cálculo das recompensas baseado na liquidez fornecida na faixa específica
        emit RewardsClaimed(msg.sender, 0); // TODO: implementar cálculo real
    }
}
