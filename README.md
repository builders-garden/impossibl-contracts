# Impossibl Protocol

A tournament protocol built on Worldchain, enabling users to create and participate in competitive tournaments with flexible prize distribution mechanisms.

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

- **Worldchain Deployment**: Native deployment on Worldchain network (Chain ID: 480)

- **OpenZeppelin Integration**: Built on battle-tested OpenZeppelin contracts for security and reliability

- **Merkle Proof System**: Efficient and verifiable winner determination for large-scale tournaments

- **Multi-Token Support**: Accepts both native ETH and any ERC20 token for buy-ins and prizes

- **Gas Efficient**: Optimized for cost-effective operations on Worldchain

## Contract Addresses

### Worldchain Mainnet

- **ImpossiblProtocol**: `0x20c3adEFd4E604fdA12297a05B6099546677e4FB`

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

Deploy the ImpossiblProtocol contract to Worldchain:

```bash
export PRIVATE_KEY=your_private_key_here
export EXPLORER_SCAN=https://worldscan.io  # Optional

forge script script/DeployImpossibl.s.sol:DeployImpossibl \
  --rpc-url worldchain \
  --broadcast \
  --verify \
  -vvvv
```

The deployment script is configured to use the public Worldchain RPC endpoint (hardcoded in `foundry.toml`). The `--rpc-url worldchain` flag uses this pre-configured endpoint.

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
