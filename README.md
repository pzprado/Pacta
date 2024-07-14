# Pacta

Institutional grade Shareholders Agreement onchain. A Shotgun Clause empowers a world of RWA, Tradfi Institutions and Crypto Native Institutions to coordinate and resolve disputes onchain.

This repository contains the implementation of a general-purpose Shotgun Clause smart contract on the Ethereum blockchain. The contract facilitates the buyout of shares between shareholders using ERC20 tokens. It implements the core functionalities for a transaction between two parties, ensuring transparency, security, and automation in the M&A process.

## Overview

A Shotgun Clause is a mechanism used in shareholder agreements to handle buyout situations, typically in case of a deadlock or dispute. This smart contract allows any ERC20 token holder to participate in a Shotgun Clause process, enabling seamless and automated execution of offers, counter-offers, and buyouts.

## Features

- **General-Purpose**: Supports any ERC20 token by specifying the token address during the offer.
- **Automated Execution**: Facilitates the automated transfer of shares and funds using ERC20 `approve` and `transferFrom` methods.
- **Secure and Transparent**: Ensures all actions are transparent and traceable on the blockchain.
- **Gas Optimized**: Avoids the use of modifiers to reduce gas costs.

## Contract Details

### ShotgunClause Contract

The main contract that manages the Shotgun Clause process.

#### Functions

- `makeOffer(address token, uint256 price, uint256 shares, uint256 duration)`: Initiates an offer with the specified token, price per share, number of shares, and duration.
- `acceptOffer()`: Allows the offeree to accept the offer and sell their shares to the offeror.
- `counterOffer()`: Allows the offeree to counter the offer and buy out the offeror’s shares.
- `expireOffer()`: Marks the offer as expired if no action is taken before the expiry time.

#### Events

- `OfferMade(address indexed offeror, address token, uint256 price, uint256 shares, uint256 expiry)`: Emitted when an offer is made.
- `OfferAccepted(address indexed offeree)`: Emitted when an offer is accepted.
- `CounterOfferMade(address indexed counterOfferor)`: Emitted when a counter-offer is made.
- `OfferExpired()`: Emitted when an offer expires.

## Installation

1. **Clone the Repository**

    ```sh
    git clone https://github.com/yourusername/shotgun-clause.git
    cd shotgun-clause
    ```

2. **Install Foundry**

    Follow the instructions to install Foundry from the [official repository](https://github.com/gakonst/foundry).

3. **Install Dependencies**

    ```sh
    forge install
    ```

4. **Compile the Smart Contracts**

    ```sh
    forge build
    ```

5. **Deploy the Smart Contracts**

    Deploy the contracts to a local or test network:

    ```sh
    forge script scripts/Deploy.s.sol --rpc-url <YOUR_RPC_URL> --private-key <YOUR_PRIVATE_KEY>
    ```

## Usage

1. **Make an Offer**

    The offeror initiates an offer by specifying the ERC20 token address, price per share, number of shares, and duration.

    ```solidity
    makeOffer(tokenAddress, price, shares, duration);
    ```

2. **Accept an Offer**

    The offeree accepts the offer and transfers their shares to the offeror.

    ```solidity
    acceptOffer();
    ```

3. **Counter an Offer**

    The offeree counters the offer by sending the required amount of ETH to buy out the offeror’s shares.

    ```solidity
    counterOffer();
    ```

4. **Expire an Offer**

    Mark the offer as expired if no action is taken before the expiry time.

    ```solidity
    expireOffer();
    ```
    
## Scenarios Matrix

| Scenario            | Party A Action              | Party A Outcome                                  | Party B Action              | Party B Outcome                                  |
|---------------------|-----------------------------|--------------------------------------------------|-----------------------------|--------------------------------------------------|
| **Create Agreement**| Propose agreement           | Agreement terms set; awaits Party B's approval   | Approve or reject agreement | If approved, agreement is established            |
| **Make Offer**      | Make an offer               | Stakes payment token; initiates offer            | Review offer                | Can accept, counter, or ignore the offer         |
| **Accept Offer**    | Wait for acceptance         | Receives target tokens if offer accepted         | Accept offer                | Receives payment tokens; transfers target tokens |
| **Counter Offer**   | Review counter offer        | Can accept or reject counter offer               | Make counter offer          | Stakes payment token; proposes new terms         |
| **Expire Offer**    | Offer not accepted in time  | Original offer expired; gets back staked tokens  | Offer not accepted in time  | Original offer expired; no changes in holdings   |

## Chronicle Integration
Pacta uses Chronicle oracles to fetch real-time data for offer valuations. The oracles ensure that the offer prices are accurate and up-to-date, providing a fair and transparent mechanism for all parties involved.

### Using Chronicle:
- Ensure the smart contract address is whitelisted by the Chronicle's SelfKisser contract.
- Use the `getOfferValuation` function to fetch the current oracle price and compare it with the offered price.



## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.
