// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {GovernanceToken} from "@nebular/contracts/governance/GovernanceToken.sol";
import {TokenVester} from "@nebular/contracts/governance/TokenVester.sol";
import "forge-std/console.sol";

/**
 * @title DeployNBL
 * @notice A deployment script for the Nebular (NBL) governance token and its associated vesting contracts.
 * @dev This script deploys the governance token and multiple vesting contracts, 
 *      and then distributes the tokens accordingly.
 */
contract DeployNBL is Script {
    /// @notice Private keys used to derive the wallet addresses for token distribution.
    uint256 private marketingPrivateKey = vm.envUint("MARKETING_PRIVATE_KEY");
    uint256 private treasuryPrivateKey = vm.envUint("TREASURY_PRIVATE_KEY");
    uint256 private partnersPrivateKey = vm.envUint("PARTNERS_PRIVATE_KEY");
    uint256 private teamPrivateKey = vm.envUint("TEAM_PRIVATE_KEY");
    uint256 private seedPrivateKey = vm.envUint("SEED_PRIVATE_KEY");

    /// @notice Wallet addresses used for token allocation.
    address public MARKETING_WALLET = vm.addr(marketingPrivateKey);
    address public TREASURY_WALLET = vm.addr(treasuryPrivateKey);
    address public PARTNERS_WALLET = vm.addr(partnersPrivateKey);
    address public TEAM_WALLET = vm.addr(teamPrivateKey);
    address public SEED_WALLET = vm.addr(seedPrivateKey);

    /**
     * @notice Deploys the NBL governance token and vesting contracts, then distributes tokens.
     * @dev Uses `forge script` to execute the deployment on a live blockchain or fork.
     */
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        /// @notice Address of the deployer, who initially holds the governance token.
        address deployerAddress = vm.addr(deployerPrivateKey);

        // Deploy the NBL governance token
        GovernanceToken nbl = new GovernanceToken(deployerAddress);

        // Deploy the vesting contracts for different allocations
        TokenVester liquidityVester = new TokenVester(
            nbl,
            0, // Cliff: 0 (immediate release)
            0, // Initial release: 0
            40_000_000e18, // Total allocation: 40M tokens
            4 * 365 days, // Vesting duration: 4 years
            TREASURY_WALLET // Beneficiary: Treasury
        );

        TokenVester teamVester = new TokenVester(
            nbl,
            1 * 365 days, // Cliff: 1 year
            0, // Initial release: 0
            15_000_000e18, // Total allocation: 15M tokens
            3 * 365 days, // Vesting duration: 3 years
            TEAM_WALLET // Beneficiary: Team
        );

        TokenVester seedVester = new TokenVester(
            nbl,
            180 days, // Cliff: 6 months
            0, // Initial release: 0
            10_000_000e18, // Total allocation: 10M tokens
            2 * 365 days, // Vesting duration: 2 years
            SEED_WALLET // Beneficiary: Seed investors
        );

        TokenVester marketingVester = new TokenVester(
            nbl,
            0, // Cliff: 0
            3_000_000e18, // Initial release: 3M tokens (30%)
            10_000_000e18, // Total allocation: 10M tokens
            2 * 365 days, // Vesting duration: 2 years
            MARKETING_WALLET // Beneficiary: Marketing
        );

        // Distribute tokens to vesting contracts and other wallets
        nbl.transfer(address(liquidityVester), 40_000_000e18);
        nbl.transfer(address(teamVester), 15_000_000e18);
        nbl.transfer(address(seedVester), 10_000_000e18);
        nbl.transfer(address(marketingVester), 10_000_000e18);
        nbl.transfer(TREASURY_WALLET, 20_000_000e18); // Treasury allocation
        nbl.transfer(PARTNERS_WALLET, 5_000_000e18); // Partners allocation

        vm.stopBroadcast();
    }
}
