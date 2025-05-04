// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { TimelockController } from "@openzeppelin/contracts/governance/TimelockController.sol";
import { NebularTokenVester } from "@nebular/contracts/governance/NebularTokenVester.sol";
import { NebularGovernance } from "@nebular/contracts/governance/NebularGovernance.sol";
import { NebularToken } from "@nebular/contracts/governance/NebularToken.sol";

import { NebularFactory } from "@nebular/contracts/NebularFactory.sol";
import { NebularPool } from "@nebular/contracts/NebularPool.sol";

import { MockToken } from './MockToken.sol';

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
    uint256 private deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
    address public DEPLOYER_WALLET = vm.addr(deployerPrivateKey);

    function run() external {
        vm.startBroadcast(deployerPrivateKey);
        console.log("Deploying from", msg.sender);

        // ======================
        // Deploy Nebular Pool and Factory
        // ======================

        NebularPool poolImplementation = new NebularPool();
        console.log("NebularPool implementation deployed at:", address(poolImplementation));

        NebularFactory factory = new NebularFactory(address(poolImplementation));
        console.log("Factory deployed at:", address(factory));

        address dao = address(0x989d22A5092f64AB894FBE4C2Aa4270a877b9Ad0);

        factory.setOwner(dao);
        console.log("Nebular factory transferred to DAO");

        // ======================
        // Deploy Peripherals
        // ======================

        // MockToken weth = new MockToken("Wrapped ETH", "wETH");
        // MockToken link = new MockToken("Chainlink", "LINK");

        console.log("======== DEPLOYMENT ENVIRONMENT ========");
        console.log(string.concat("NEBULAR_FACTORY_ADDR=", vm.toString(address(factory))));
        // console.log(string.concat("WETH_ADDR=", vm.toString(address(weth))));
        // console.log(string.concat("LINK_ADDR=", vm.toString(address(link))));
        console.log("===================================");
        vm.stopBroadcast();
    }
}