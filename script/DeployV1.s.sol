// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.20;

// import { TimelockController } from "@openzeppelin/contracts/governance/TimelockController.sol";
// import { LiquidityPoolFactoryV1 } from "@nebular/contracts/pools/LiquidityPoolFactoryV1.sol";
// import { GovernanceToken } from "@nebular/contracts/governance/GovernanceToken.sol";
// import { GovernanceDAO } from "@nebular/contracts/governance/GovernanceDAO.sol";
// import { TokenVester } from "@nebular/contracts/governance/TokenVester.sol";
// import { Script } from "forge-std/Script.sol";
// import "forge-std/console.sol";

// /**
//  * @title DeployV1
//  * @notice Comprehensive deployment script for the Nebular ecosystem
//  * @dev Deploys:
//  *      1. Governance token (NBL)
//  *      2. Vesting contracts
//  *      3. Timelock controller
//  *      4. Governance DAO
//  *      5. Liquidity pool factory
//  */
// contract DeployV1 is Script {
//     /// @notice Private keys for wallet addresses
//     uint256 private marketingPrivateKey = vm.envUint("MARKETING_PRIVATE_KEY");
//     uint256 private treasuryPrivateKey = vm.envUint("TREASURY_PRIVATE_KEY");
//     uint256 private partnersPrivateKey = vm.envUint("PARTNERS_PRIVATE_KEY");
//     uint256 private deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
//     uint256 private teamPrivateKey = vm.envUint("TEAM_PRIVATE_KEY");
//     uint256 private seedPrivateKey = vm.envUint("SEED_PRIVATE_KEY");

//     /// @notice Wallet addresses
//     address public MARKETING_WALLET = vm.addr(marketingPrivateKey);
//     address public TREASURY_WALLET = vm.addr(treasuryPrivateKey);
//     address public PARTNERS_WALLET = vm.addr(partnersPrivateKey);
//     address public DEPLOYER_WALLET = vm.addr(deployerPrivateKey);
//     address public TEAM_WALLET = vm.addr(teamPrivateKey);
//     address public SEED_WALLET = vm.addr(seedPrivateKey);


//     /// @notice DAO parameters
//     uint256 public constant MIN_DELAY = 2 minutes;
//     uint256 public constant PROPOSERS_COUNT = 5;
//     uint256 public constant EXECUTORS_COUNT = 5;

//     function run() external {
//         vm.startBroadcast(deployerPrivateKey);

//         // // ======================
//         // // 1. Deploy Governance Token
//         // // ======================
//         // console.log("\nDeploying GovernanceToken...");
//         // GovernanceToken nbl = new GovernanceToken(DEPLOYER_WALLET);
//         // console.log("GovernanceToken deployed at:", address(nbl));

//         // // ======================
//         // // 2. Deploy Timelock Controller
//         // // ======================
//         // console.log("\nDeploying TimelockController...");
        
//         // address[] memory proposers = new address[](PROPOSERS_COUNT);
//         // address[] memory executors = new address[](EXECUTORS_COUNT);
        
//         // for (uint i = 0; i < PROPOSERS_COUNT; i++) {
//         //     proposers[i] = DEPLOYER_WALLET;
//         // }
        
//         // for (uint i = 0; i < EXECUTORS_COUNT; i++) {
//         //     executors[i] = DEPLOYER_WALLET;
//         // }
        
//         // TimelockController timelock = new TimelockController(
//         //     MIN_DELAY,
//         //     proposers,
//         //     executors,
//         //     DEPLOYER_WALLET
//         // );

//         // console.log("TimelockController deployed at:", address(timelock));

//         // // ======================
//         // // 3. Deploy Vesting Contracts
//         // // ======================
//         // console.log("\nDeploying Vesting Contracts...");
        
//         // // Deploy the vesting contracts for different allocations
//         // TokenVester liquidityVester = new TokenVester(
//         //     nbl,
//         //     0,                  // Cliff: 0
//         //     0,                  // Initial release: 0
//         //     20_000_000e18,      // Total allocation: 40M tokens
//         //     4 * 365 days,       // Vesting duration: 4 years
//         //     TREASURY_WALLET,    // Beneficiary: Treasury
//         //     TREASURY_WALLET     // The address that will own the vesting contract
//         // );

//         // console.log("Liquidity Vester deployed at:", address(liquidityVester));

//         // TokenVester teamVester = new TokenVester(
//         //     nbl,
//         //     1 * 365 days,       // Cliff: 1 year
//         //     0,                  // Initial release: 0
//         //     15_000_000e18,      // Total allocation: 15M tokens
//         //     3 * 365 days,       // Vesting duration: 3 years
//         //     TEAM_WALLET,        // Beneficiary: Team 
//         //     address(timelock)   // The address that will own the vesting contract
//         // );

//         // console.log("Team Vester deployed at:", address(teamVester));

//         // TokenVester seedVester = new TokenVester(
//         //     nbl,
//         //     180 days,           // Cliff: 6 months
//         //     0,                  // Initial release: 0
//         //     10_000_000e18,      // Total allocation: 10M tokens
//         //     2 * 365 days,       // Vesting duration: 2 years
//         //     SEED_WALLET,        // Beneficiary: Seed investors
//         //     SEED_WALLET         // The address that will own the vesting contract
//         // );

//         // console.log("Seed Vester deployed at:", address(seedVester));

//         // TokenVester marketingVester = new TokenVester(
//         //     nbl,
//         //     0,                  // Cliff: 0
//         //     3_000_000e18,       // Initial release: 3M tokens (30%)
//         //     10_000_000e18,      // Total allocation: 10M tokens
//         //     2 * 365 days,       // Vesting duration: 2 years
//         //     MARKETING_WALLET,   // Beneficiary: Marketing
//         //     address(timelock)   // The address that will own the vesting contract
//         // );

//         // console.log("Marketing Vester deployed at:", address(marketingVester));

//         // // ======================
//         // // 4. Distribute Tokens
//         // // ======================
//         // console.log("\nDistributing tokens...");
//         // nbl.transfer(address(liquidityVester), 20_000_000e18);
//         // nbl.transfer(address(teamVester), 15_000_000e18);
//         // nbl.transfer(address(seedVester), 10_000_000e18);
//         // nbl.transfer(address(marketingVester), 10_000_000e18);
//         // nbl.transfer(TREASURY_WALLET, 40_000_000e18);
//         // nbl.transfer(PARTNERS_WALLET, 5_000_000e18);
//         // console.log("Token distribution completed");

//         // // ======================
//         // // 5. Deploy Governance DAO
//         // // ======================
//         // console.log("\nDeploying GovernanceDAO...");
//         // GovernanceDAO dao = new GovernanceDAO(nbl, timelock);
//         // console.log("GovernanceDAO deployed at:", address(dao));

//         // // ======================
//         // // 6. Post-Deployment Setup
//         // // ======================
//         // console.log("\nConfiguring permissions...");
        
//         // // Transfer timelock admin to DAO
//         // timelock.grantRole(timelock.PROPOSER_ROLE(), address(dao));
//         // timelock.grantRole(timelock.EXECUTOR_ROLE(), address(dao));
//         // timelock.grantRole(timelock.CANCELLER_ROLE(), address(dao));
//         // timelock.revokeRole(timelock.DEFAULT_ADMIN_ROLE(), DEPLOYER_WALLET);
        
//         // console.log("Timelock permissions transferred to DAO");

//         // // ======================
//         // // 7. Deploy Liquidity Pool Factory
//         // // ======================
//         console.log("\nDeploying LiquidityPoolFactory...");
//         LiquidityPoolFactoryV1 poolFactory = new LiquidityPoolFactoryV1();
//         console.log("LiquidityPoolFactory deployed at:", address(poolFactory));

//         // // ======================
//         // // Deployment Summary
//         // // ======================
//         // console.log("\n======== DEPLOYMENT SUMMARY ========");
//         // console.log("Governance Token (NBL):", address(nbl));
//         // console.log("DAO:", address(dao));
//         // console.log("Timelock:", address(timelock));
//         // console.log("Liquidity Pool Factory:", address(poolFactory));
//         // console.log("Vesting Contracts:");
//         // console.log("  - Liquidity:", address(liquidityVester));
//         // console.log("  - Team:", address(teamVester));
//         // console.log("  - Seed:", address(seedVester));
//         // console.log("  - Marketing:", address(marketingVester));
//         // console.log("===================================");

//         vm.stopBroadcast();
//     }
// }
