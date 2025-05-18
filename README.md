# King of the Hill Smart Contracts

Smart contracts for the King of the Hill DApp. This repository contains the upgradeable contracts that power the game mechanics.

## Technologies
- Solidity ^0.8.20
- OpenZeppelin Contracts (Upgradeable)
- Foundry/Forge

## Prerequisites
- Foundry (for smart contracts)

## RPC URL Configuration

You must specify the Ethereum RPC URL for your target network. There are two ways to do this:

1. **Via `foundry.toml`:**  
   Add the following line to your `foundry.toml` (do NOT commit private URLs or API keys to public repos!):
   ```toml
   eth-rpc-url = "YOUR_RPC_URL"
   ```

2. **Via command line:**  
   Pass the URL directly to forge/cast/anvil commands:
   ```bash
   forge script ... --rpc-url YOUR_RPC_URL
   cast call ... --rpc-url YOUR_RPC_URL
   ```

## Contract Versions

### KingImplementationV1
- Basic king game functionality
- Users can claim the throne by sending more ETH than the current prize
- Previous king receives the funds

### KingImplementationV2
- Extends V1 with fee mechanism
- Adds claim tracking
- 5% fee on each claim
- Tracks total claims and claims per user

## Setup

1. Install Foundry:
```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

2. Install contract dependencies:
```bash
forge install
```

3. Create `.env` in the root directory:
```env
PRIVATE_KEY=your_private_key
```

## Development

1. Run tests:
```bash
forge test
```

2. Clean and rebuild:
```bash
forge clean
forge build
```

## Deployment

1. Deploy the initial contract:
```bash
forge script script/Deploy.s.sol:Deploy --rpc-url $YOUR_RPC_URL --broadcast --verify
```

2. Add king proxy address to .env file:
```env
KING_PROXY_ADDRESS=deployed_proxy_address
```

3. Upgrade to V2:
```bash
forge script script/Upgrade.s.sol:Upgrade --rpc-url $YOUR_RPC_URL --broadcast --verify
```

3. Check status:
```bash
forge script script/KingStatus.s.sol:Status --rpc-url $YOUR_RPC_URL
```
## Important Notes

- The contract is upgradeable, allowing for future improvements
- Fee percentage is capped at 10%
- Contract ownership is properly managed
