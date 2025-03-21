# Nebular Finances Smart Contracts

This repository contains the implementation of the smart contracts that comprise the Nebular Finances system, covering governance, liquidity, rewards, vesting, and price oracle modules. The architecture leverages OpenZeppelin standards and libraries, with integrations using Chainlink and governance mechanisms inspired by OpenZeppelin's Governor.

[![Nebular Main CI/CD](https://github.com/jeffersson-abreu/nebular_contracts/actions/workflows/main.yml/badge.svg?branch=main)](https://github.com/jeffersson-abreu/nebular_contracts/actions/workflows/main.yml)

[![Nebular Develop CI/CD](https://github.com/jeffersson-abreu/nebular_contracts/actions/workflows/main.yml/badge.svg?branch=develop)](https://github.com/jeffersson-abreu/nebular_contracts/actions/workflows/main.yml)

---

## Overview

The application is divided into several key modules:

- **Governance**  
  - **GovernanceDAO**: Manages proposals, voting, and the execution of critical updates and parameters.  
  - **GovernanceToken**: A governance token with voting and permit capabilities, used for delegating votes and participating in decision-making.

- **Liquidity**  
  - **LiquidityPool**: An Automated Market Maker (AMM) that enables token swaps and liquidity provision by users.  
  - **PriceOracleTWAP**: A price oracle that aggregates multiple data sources with fallback and consensus mechanisms to provide a reliable price for the AMM.

- **Rewards**  
  - **RewardSystem**: Distributes rewards based on liquidity snapshots and multipliers (boosters).  
  - **TokenVester**: Manages the gradual release of tokens according to a vesting schedule with a cliff and progressive release.

---

## Architecture and Interactions

The system is composed of different modules that interact with each other:

- **Governance**:  
  The DAO creates and manages proposals, controls the execution of updates, and sets critical parameters. The GovernanceToken is used to delegate votes and participate in governance decisions.

- **Liquidity**:  
  The LiquidityPool allows users to provide liquidity and perform swaps, generating fees that may be redistributed via governance. The PriceOracleTWAP provides the necessary price data for pool operations.

- **Rewards**:  
  The RewardSystem calculates and distributes rewards based on snapshots of the LiquidityPool. The TokenVester manages the token release according to a defined vesting schedule.

---

## Prerequisites

- [Foundry](https://getfoundry.sh/) – a tool for developing, testing, and deploying Solidity contracts  
- [Git](https://git-scm.com/)  
- [Anvil](https://book.getfoundry.sh/reference/anvil) – Foundry's local Ethereum node

---

## Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/jeffersson-abreu/nebula_contracts.git
   cd nebula_contracts
   ```

2. Ensure you have Foundry installed and updated:

   ```bash
   forge --version
   ```

3. Start a local Anvil node:

   ```bash
   anvil
   ```

---

## Environment Configuration

Before running tests or deploying contracts, set up a .env file in the root directory based on the .env-example file. If you need assistance filling in the keys, contact your supervisor.

### `.env-example`

```ini
RPC_URL="https://eth-mainnet.alchemyapi.io/v2/YOUR_API_KEY"
PRIVATE_KEY="YOUR_WALLET_PRIVATE_KEY"
ETHERSCAN_API_KEY="YOUR_ETHERSCAN_API_KEY"
...
```

---

## Running Tests

The tests are written using Foundry's testing framework. To run the tests:

1. Compile the contracts:

   ```bash
   forge build
   ```

2. Run the tests:

   ```bash
   forge test
   ```

Ensure that all tests pass before proceeding with deployment.

---

## Contract Deployment

Deployment is handled via Foundry scripts located in the `scripts` folder. The main deploy script is `Deploy.s.sol`.

To deploy the contracts on a local network using Anvil:

1. Compile the contracts (if not already compiled):

   ```bash
   forge build
   ```

2. Run the deploy script using Anvil as your local RPC:

   ```bash
   forge script scripts/Deploy.s.sol --fork-url http://127.0.0.1:8545 --broadcast
   ```

   - Replace the RPC URL if necessary.
   - The `--broadcast` flag sends transactions to the network.

Review the contents of `Deploy.s.sol` for details on the deployment order and parameters used for each contract.

---

## Contributing

Feel free to submit pull requests with improvements, bug fixes, or new features.  
Please open an issue before making significant changes to discuss their impact.

---

## License

This project is licensed under the [MIT License](LICENSE).

---

If you have any questions or need further information, please contact us!
