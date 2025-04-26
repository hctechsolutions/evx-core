// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { TimelockController } from "@openzeppelin/contracts/governance/TimelockController.sol";
import { NebularTokenVester } from "@nebular/contracts/governance/NebularTokenVester.sol";
import { NebularGovernance } from "@nebular/contracts/governance/NebularGovernance.sol";
import { NebularToken } from "@nebular/contracts/governance/NebularToken.sol";
import { NebularFactory } from "@nebular/contracts/NebularFactory.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@nebular/contracts/NebularPool.sol";
import { Script } from "forge-std/Script.sol";
import "forge-std/console.sol";

/**
 * @title DeployV1
 * @notice Comprehensive deployment script for the Nebular ecosystem
 */
contract DeployV1 is Script {
    uint256 private deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
    address public DEPLOYER_ADDRESS = vm.addr(deployerPrivateKey);

    function run() external {
        vm.startBroadcast(deployerPrivateKey);

        NebularPool poolImplementation = new NebularPool();
        console.log("NebularPool implementation deployed at:", address(poolImplementation));

        NebularFactory factory = new NebularFactory(address(poolImplementation));
        console.log("Factory deployed at:", address(factory));

        vm.stopBroadcast();
    }
}