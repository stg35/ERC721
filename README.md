### NFT Contract

This project contains a Solidity smart contract for a non-fungible token (NFT) implemented on the Ethereum blockchain. The contract is designed to manage the minting and ownership of unique digital assets represented as ERC721 tokens.

#### Features

- **Minting**: Users can mint individual tokens or complete sets of tokens by paying the required Ether amount.
- **Ownership**: Each token is owned by a specific Ethereum address and can be transferred between addresses.
- **Signed Minting**: The contract owner can mint tokens on behalf of users using a cryptographic signature, providing a secure and efficient minting process.
- **Set Minting**: Users can mint a predefined set of tokens, ensuring a complete collection with a single transaction.

#### Contract Details

- **Name**: MyToken
- **Symbol**: MTK
- **Maximum Supply**: 1000 tokens
- **Maximum Mint Amount per Transaction**: 3 tokens
- **Price per Token**: 0.01 Ether
- **Price per Set**: 0.02 Ether
- **Tokens per Set**: 6 tokens
- **Maximum Tokens per Wallet**: 6 tokens

#### Usage

1. **Minting Tokens**: Users can mint individual tokens by sending the required Ether amount to the contract.
2. **Minting Sets**: Users can mint a complete set of tokens by sending the required Ether amount to the contract.
3. **Signed Minting**: Contract owner can mint tokens on behalf of users by providing a cryptographic signature along with the minting request.
4. **Withdrawing Ether**: Contract owner can withdraw accumulated Ether balance from the contract.

#### Getting Started

To deploy the contract locally for development or testing purposes, follow these steps:

1. Clone this repository to your local machine.
2. Install dependencies using `npm install`.
3. Run Hardhat test network using `npx hardhat node`.
4. Deploy the contract to the local network using `npx hardhat ignition deploy ./ignition/modules/NFT.ts --network localhost`.
5. Interact with the deployed contract using a wallet or Ethereum development environment.

#### Testing

Unit tests for the contract functionalities are provided in the `test` directory. You can run the tests using `npx hardhat test`.
