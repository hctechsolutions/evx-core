// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Script } from "forge-std/Script.sol";
import { NBLToken } from "@contracts/Token.sol";
import { TokenVester } from "@contracts/TokenVester.sol";

contract DeployNBL is Script {
    // Defina os endereços dos beneficiários (mockados)
    address public TREASURY_WALLET;
    address public PARTNERS_WALLET;
    address public TEAM_WALLET;
    address public SEED_WALLET;
    address public MARKETING_WALLET;

    function run() external {
        // Gera endereços mockados
        TREASURY_WALLET = vm.addr(1);  // Tesouro & DAO
        PARTNERS_WALLET = vm.addr(2);  // Parceiros & CEX
        TEAM_WALLET = vm.addr(3);      // Equipe
        SEED_WALLET = vm.addr(4);      // Investidores Seed
        MARKETING_WALLET = vm.addr(5); // Marketing

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);


        // 1. Implante o Token NBL
        address deployerAddress = vm.addr(deployerPrivateKey);
        NBLToken nbl = new NBLToken(deployerAddress); // Deployer é o initialHolder

        // 2. Implante os contratos de Vesting
        TokenVester liquidityVester = new TokenVester(
            nbl,
            0,              // Cliff: 0 (sem espera)
            0,              // Liberação inicial: 0
            40_000_000e18,  // 40M tokens
            2 minutes,   // 4 anos
            TREASURY_WALLET // Dono (ex: DAO)
        );

        TokenVester teamVester = new TokenVester(
            nbl,
            1 * 365 days,   // Cliff: 1 ano
            0,              // Liberação inicial: 0
            15_000_000e18,  // 15M tokens
            3 * 365 days,   // 3 anos
            TEAM_WALLET
        );

        TokenVester seedVester = new TokenVester(
            nbl,
            180 days,       // Cliff: 6 meses
            0,              // Liberação inicial: 0
            10_000_000e18,  // 10M tokens
            2 * 365 days,   // 2 anos
            SEED_WALLET
        );

        TokenVester marketingVester = new TokenVester(
            nbl,
            0,              // Cliff: 0
            3_000_000e18,   // 3M tokens liberados inicialmente (30%)
            10_000_000e18,  // Total: 10M tokens
            2 * 365 days,   // 2 anos
            MARKETING_WALLET
        );

        // 3. Transfira os tokens para os contratos de Vesting e carteiras
        nbl.transfer(address(liquidityVester), 40_000_000e18);
        nbl.transfer(address(teamVester), 15_000_000e18);
        nbl.transfer(address(seedVester), 10_000_000e18);
        nbl.transfer(address(marketingVester), 10_000_000e18);
        nbl.transfer(TREASURY_WALLET, 20_000_000e18); // Tesouro
        nbl.transfer(PARTNERS_WALLET, 5_000_000e18);  // Parceiros

        vm.stopBroadcast();
    }
}