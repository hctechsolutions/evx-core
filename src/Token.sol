// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract NBLToken is ERC20 {
    constructor(address initialHolder) ERC20("NBL", "NBL") {
        _mint(initialHolder, 100_000_000 * 10**decimals());
    }
}