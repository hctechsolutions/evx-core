// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { TimelockController } from "@openzeppelin/contracts/governance/TimelockController.sol";
import { NebularTokenVester } from "@nebular/contracts/governance/NebularTokenVester.sol";
import { NebularGovernance } from "@nebular/contracts/governance/NebularGovernance.sol";
import { NebularToken } from "@nebular/contracts/governance/NebularToken.sol";

import { NebularFactory } from "@nebular/contracts/NebularFactory.sol";
import { NebularPool } from "@nebular/contracts/NebularPool.sol";

import { Script } from "forge-std/Script.sol";
import "forge-std/console.sol";

/**
 * @title DeployV1
 * @notice Comprehensive deployment script for the Nebular ecosystem
 * @dev Deploys:
 *      1. Governance token (NBL)
 *      2. Vesting contracts
 *      3. Timelock controller
 *      4. Governance DAO
 *      5. Pool Implementation
 *      6. Pool factory implementing pools in standard EIP-1967 (Minimal proxy)
 */
contract DeployV1 is Script {
    // /// @notice Private keys for wallet addresses
    uint256 private marketingPrivateKey = vm.envUint("MARKETING_PRIVATE_KEY");
    uint256 private treasuryPrivateKey = vm.envUint("TREASURY_PRIVATE_KEY");
    uint256 private partnersPrivateKey = vm.envUint("PARTNERS_PRIVATE_KEY");
    uint256 private deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
    uint256 private teamPrivateKey = vm.envUint("TEAM_PRIVATE_KEY");
    uint256 private seedPrivateKey = vm.envUint("SEED_PRIVATE_KEY");

    /// @notice Wallet addresses
    address public MARKETING_WALLET = vm.addr(marketingPrivateKey);
    address public TREASURY_WALLET = vm.addr(treasuryPrivateKey);
    address public PARTNERS_WALLET = vm.addr(partnersPrivateKey);
    address public DEPLOYER_WALLET = vm.addr(deployerPrivateKey);
    address public TEAM_WALLET = vm.addr(teamPrivateKey);
    address public SEED_WALLET = vm.addr(seedPrivateKey);


    /// @notice DAO parameters
    uint256 public constant MIN_DELAY = 2 minutes;
    uint256 public constant PROPOSERS_COUNT = 5;
    uint256 public constant EXECUTORS_COUNT = 5;

    function run() external {
        console.log("Deploying from", msg.sender);
        vm.startBroadcast(deployerPrivateKey);

        // ======================
        // Deploy Governance Token
        // ======================
        console.log("\nDeploying NebularToken...");
        NebularToken nbl = new NebularToken(DEPLOYER_WALLET);
        console.log("NebularToken deployed at:", address(nbl));

        // ======================
        // Deploy Timelock Controller
        // ======================
        console.log("\nDeploying TimelockController...");
        
        address[] memory proposers = new address[](PROPOSERS_COUNT);
        address[] memory executors = new address[](EXECUTORS_COUNT);
        
        for (uint i = 0; i < PROPOSERS_COUNT; i++) {
            proposers[i] = DEPLOYER_WALLET;
        }
        
        for (uint i = 0; i < EXECUTORS_COUNT; i++) {
            executors[i] = DEPLOYER_WALLET;
        }
        
        TimelockController timelock = new TimelockController(
            MIN_DELAY,
            proposers,
            executors,
            DEPLOYER_WALLET
        );

        console.log("TimelockController deployed at:", address(timelock));

        // ======================
        // Deploy Vesting Contracts
        // ======================
        console.log("\nDeploying Vesting Contracts...");
        
        // Deploy the vesting contracts for different allocations
        NebularTokenVester liquidityVester = new NebularTokenVester(
            nbl,
            0,                  // Cliff: 0
            0,                  // Initial release: 0
            20_000_000e18,      // Total allocation: 40M tokens
            4 * 365 days,       // Vesting duration: 4 years
            TREASURY_WALLET,    // Beneficiary: Treasury
            TREASURY_WALLET     // The address that will own the vesting contract
        );

        console.log("Liquidity Vester deployed at:", address(liquidityVester));

        NebularTokenVester teamVester = new NebularTokenVester(
            nbl,
            1 * 365 days,       // Cliff: 1 year
            0,                  // Initial release: 0
            15_000_000e18,      // Total allocation: 15M tokens
            3 * 365 days,       // Vesting duration: 3 years
            TEAM_WALLET,        // Beneficiary: Team 
            address(timelock)   // The address that will own the vesting contract
        );

        console.log("Team Vester deployed at:", address(teamVester));

        NebularTokenVester seedVester = new NebularTokenVester(
            nbl,
            180 days,           // Cliff: 6 months
            0,                  // Initial release: 0
            10_000_000e18,      // Total allocation: 10M tokens
            2 * 365 days,       // Vesting duration: 2 years
            SEED_WALLET,        // Beneficiary: Seed investors
            SEED_WALLET         // The address that will own the vesting contract
        );

        console.log("Seed Vester deployed at:", address(seedVester));

        NebularTokenVester marketingVester = new NebularTokenVester(
            nbl,
            0,                  // Cliff: 0
            3_000_000e18,       // Initial release: 3M tokens (30%)
            10_000_000e18,      // Total allocation: 10M tokens
            2 * 365 days,       // Vesting duration: 2 years
            MARKETING_WALLET,   // Beneficiary: Marketing
            address(timelock)   // The address that will own the vesting contract
        );

        console.log("Marketing Vester deployed at:", address(marketingVester));

        // ======================
        // Distribute Tokens
        // ======================
        console.log("\nDistributing tokens...");
        nbl.transfer(address(liquidityVester), 20_000_000e18);
        nbl.transfer(address(teamVester), 15_000_000e18);
        nbl.transfer(address(seedVester), 10_000_000e18);
        nbl.transfer(address(marketingVester), 10_000_000e18);
        nbl.transfer(TREASURY_WALLET, 40_000_000e18);
        nbl.transfer(PARTNERS_WALLET, 5_000_000e18);
        console.log("Token distribution completed");

        // ======================
        // Deploy Governance DAO
        // ======================
        console.log("\nDeploying NebularGovernance...");
        NebularGovernance dao = new NebularGovernance(nbl, timelock);
        console.log("NebularGovernance deployed at:", address(dao));

        // ======================
        // Post-Deployment Setup
        // ======================
        console.log("\nConfiguring permissions...");
        
        // Transfer timelock admin to Nebular DAO
        timelock.grantRole(timelock.PROPOSER_ROLE(), address(dao));
        timelock.grantRole(timelock.EXECUTOR_ROLE(), address(dao));
        timelock.grantRole(timelock.CANCELLER_ROLE(), address(dao));
        timelock.revokeRole(timelock.DEFAULT_ADMIN_ROLE(), DEPLOYER_WALLET);
        
        console.log("Timelock permissions transferred to DAO");

        // ======================
        // Deploy Nebular Pool and Factory
        // ======================

        NebularPool poolImplementation = new NebularPool();
        console.log("NebularPool implementation deployed at:", address(poolImplementation));

        NebularFactory factory = new NebularFactory(address(poolImplementation));
        console.log("Factory deployed at:", address(factory));

        factory.setOwner(address(dao));
        console.log("Nebular factory transferred to DAO");

        console.log("======== DEPLOYMENT ENVIRONMENT ========");
        console.log(string.concat("NEBULAR_TOKEN_ADDR=", vm.toString(address(nbl))));
        console.log(string.concat("NEBULAR_DAO_ADDR=", vm.toString(address(dao))));
        console.log(string.concat("DAO_TIMELOCK_ADDR=", vm.toString(address(timelock))));
        console.log(string.concat("NEBULAR_FACTORY_ADDR=", vm.toString(address(factory))));
        console.log(string.concat("LIQUIDITY_VESTER_ADDR=", vm.toString(address(liquidityVester))));
        console.log(string.concat("TEAM_VESTER_ADDR=", vm.toString(address(teamVester))));
        console.log(string.concat("SEED_VESTER_ADDR=", vm.toString(address(seedVester))));
        console.log(string.concat("MARKETING_VESTER_ADDR=", vm.toString(address(marketingVester))));
        console.log("===================================");

        vm.stopBroadcast();
    }
}