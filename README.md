# Impossibl Protocol

A tournament protocol built on Worldchain and Celo, enabling users to create and participate in competitive tournaments with flexible prize distribution mechanisms.

## Overview

Impossibl Protocol allows users to create two types of tournaments: **Global** and **Group**. Participants can join tournaments by paying a buy-in amount in either ETH or ERC20 tokens. The protocol supports flexible winner determination: Group tournaments have a single winner set by the owner, while Global tournaments use Merkle proofs to enable multiple winners with verifiable prize claims. All prize pools are automatically managed and distributed by the smart contract.

## Contracts

### ImpossiblProtocol

The main contract that manages all tournament operations. Key features:

- **Dual Tournament Types**:

  - **Group Tournaments**: Single winner determined by the owner, with automatic prize distribution
  - **Global Tournaments**: Multiple winners verified via Merkle proofs, enabling decentralized prize claims

- **Flexible Payment Options**: Supports both ETH and ERC20 token buy-ins and prize distributions

- **Merkle Proof Verification**: Global tournaments use cryptographic Merkle proofs to verify winner eligibility and prize amounts

- **Access Control**: Uses OpenZeppelin's Ownable pattern for secure tournament management

- **Automatic Prize Distribution**: Group tournaments automatically transfer prizes to winners upon completion

## Key Features

- **Multi-Chain Deployment**: Native deployment on both Worldchain (Chain ID: 480) and Celo (Chain ID: 42220) networks

- **OpenZeppelin Integration**: Built on battle-tested OpenZeppelin contracts for security and reliability

- **Merkle Proof System**: Efficient and verifiable winner determination for large-scale tournaments

- **Multi-Token Support**: Accepts both native ETH and any ERC20 token for buy-ins and prizes

- **Gas Efficient**: Optimized for cost-effective operations on both networks

## Contract Addresses

### Worldchain Mainnet

- **ImpossiblProtocol**: `0x20c3adEFd4E604fdA12297a05B6099546677e4FB`

### Celo Mainnet

- **ImpossiblProtocol**: `0xbA75a319e118da7C95f57E35B926107253150332`

## Celo ETHGlobal Buenos Aires Submission

### Celo Integration

Impossibl Protocol is deployed on Celo and leverages Celo's low-cost, fast finality blockchain infrastructure for efficient tournament operations. The protocol supports both native CELO and ERC20 tokens (including Celo's stablecoins like cUSD and cEUR) for tournament buy-ins and prize distributions. All tournament operations utilize Celo's gas-efficient network, making it accessible for users worldwide to participate in competitive tournaments.

### Project Description

Impossibl Protocol is a decentralized tournament platform that enables users to create and participate in competitive tournaments with flexible prize distribution mechanisms. The protocol supports two tournament types: Group tournaments with a single winner and automatic prize distribution, and Global tournaments that use Merkle proofs to enable multiple winners with verifiable, decentralized prize claims. Participants can join tournaments using either native CELO or any ERC20 token, making it accessible and flexible for various use cases.

### Team

The team is made by:

- Frank: product and fullstack developer. Worked on contracts, design and webapp developement. X: @frankc_eth, Farcaster:@frankk
- Bianc8: fullstack developer. Worked on backend and webapp developement. X: @bianc8_eth, Farcaster: @bianc8
- Caso: fullstack developer. Worked on backend developement. Farcaster: @0xcaso

## Development

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Node.js (for ABI extraction, if needed)

### Build

```bash
forge build
```

### Test

```bash
forge test
```

### Format

```bash
forge fmt
```

### Gas Snapshots

```bash
forge snapshot
```

### Deploy

Deploy the ImpossiblProtocol contract to Worldchain or Celo:

**Deploy to Worldchain:**

```bash
export PRIVATE_KEY=your_private_key_here
export DEPLOY_CHAIN=worldchain
export EXPLORER_SCAN=https://worldscan.io  # Optional

forge script script/DeployImpossibl.s.sol:DeployImpossibl \
  --rpc-url worldchain \
  --broadcast \
  --verify \
  -vvvv
```

**Deploy to Celo:**

```bash
export PRIVATE_KEY=your_private_key_here
export DEPLOY_CHAIN=celo
export EXPLORER_SCAN=https://celoscan.io  # Optional

forge script script/DeployImpossibl.s.sol:DeployImpossibl \
  --rpc-url celo \
  --broadcast \
  --verify \
  -vvvv
```

The deployment script supports both networks. RPC endpoints are hardcoded in `foundry.toml` as public endpoints. Set the `DEPLOY_CHAIN` environment variable to specify the target chain, and use the corresponding `--rpc-url` flag.

### Generate ABI

Extract the contract ABI to a separate file:

```bash
forge build && jq '.abi' out/Impossibl.sol/ImpossiblProtocol.json > Impossibl.abi.json
```

### Local Development

Start a local Anvil node for testing:

```bash
anvil
```
