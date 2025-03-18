// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Script } from "forge-std/Script.sol";
import { NBLToken } from "@nebula/contracts/Token.sol";
import { TokenVester } from "@nebula/contracts/TokenVester.sol";
import "forge-std/console.sol";

contract DeployNBL is Script {
    // Define the beneficiary addresses (mocked)
    uint256 private treasuryPrivateKey = vm.envUint("TREASURY_PRIVATE_KEY");
    uint256 private partnersPrivateKey = vm.envUint("PARTNERS_PRIVATE_KEY");
    uint256 private teamPrivateKey = vm.envUint("TEAM_PRIVATE_KEY");
    uint256 private seedPrivateKey = vm.envUint("SEED_PRIVATE_KEY");
    uint256 private marketingPrivateKey = vm.envUint("MARKETING_PRIVATE_KEY");

    address public TREASURY_WALLET = vm.addr(treasuryPrivateKey);
    address public PARTNERS_WALLET = vm.addr(partnersPrivateKey);
    address public TEAM_WALLET = vm.addr(teamPrivateKey);
    address public SEED_WALLET = vm.addr(seedPrivateKey);
    address public MARKETING_WALLET = vm.addr(marketingPrivateKey);

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy the NBL Token
        address deployerAddress = vm.addr(deployerPrivateKey);
        NBLToken nbl = new NBLToken(deployerAddress); // Deployer is the initialHolder

        // 2. Deploy the Vesting contracts
        TokenVester liquidityVester = new TokenVester(
            nbl,
            0,              // Cliff: 0 (no waiting period)
            0,              // Initial release: 0
            40_000_000e18,  // 40M tokens
            4 * 365 days,   // 4 years
            TREASURY_WALLET // Owner (e.g., DAO)
        );

        TokenVester teamVester = new TokenVester(
            nbl,
            1 * 365 days,   // Cliff: 1 year
            0,              // Initial release: 0
            15_000_000e18,  // 15M tokens
            3 * 365 days,   // 3 years
            TEAM_WALLET
        );

        TokenVester seedVester = new TokenVester(
            nbl,
            180 days,       // Cliff: 6 months
            0,              // Initial release: 0
            10_000_000e18,  // 10M tokens
            2 * 365 days,   // 2 years
            SEED_WALLET
        );

        TokenVester marketingVester = new TokenVester(
            nbl,
            0,              // Cliff: 0
            3_000_000e18,   // 3M tokens initially released (30%)
            10_000_000e18,  // Total: 10M tokens
            2 * 365 days,   // 2 years
            MARKETING_WALLET
        );

        // 3. Transfer tokens to the Vesting contracts and wallets
        nbl.transfer(address(liquidityVester), 40_000_000e18);
        nbl.transfer(address(teamVester), 15_000_000e18);
        nbl.transfer(address(seedVester), 10_000_000e18);
        nbl.transfer(address(marketingVester), 10_000_000e18);
        nbl.transfer(TREASURY_WALLET, 20_000_000e18); // Treasury
        nbl.transfer(PARTNERS_WALLET, 5_000_000e18);  // Partners

        vm.stopBroadcast();
    }
}
