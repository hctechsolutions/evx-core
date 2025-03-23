// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
// import "@nebular/UniOracle.sol";
// import "@nebular/LinkOracle.sol";

// /**
//  * @title DeploySimpleUniswapOracle
//  * @notice Deployment script for the SimpleUniswapOracle on a testnet.
//  */
// contract DeploySimpleUniswapOracle is Script {
//     function run() external {
//         vm.startBroadcast();

//         address poolAddress = 0x4e68Ccd3E89f51C3074ca5072bbAC773960dFa36;
//         SimpleUniswapOracle oracle = new SimpleUniswapOracle(poolAddress);
//         vm.stopBroadcast();
//         console.log("SimpleUniswapOracle deployed at:", address(oracle));

//         address poolAddress = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
//         SimpleChainlinkOracle oracle = new SimpleChainlinkOracle(poolAddress);
//         console.log("SimpleChainlinkOracle deployed at:", address(oracle));

//         vm.stopBroadcast();
//     }
// }
