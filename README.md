# ATLAS Agent

**Autonomous DeFi Agent Orchestrator** — AI agents that trade perpetual futures, optimize yield across 5 chains, and bridge assets autonomously. All secured by OWS policy guardrails.

> OWS Hackathon 2026 | Track 02: Agent Spend Governance | Track 04: Multi-Agent Systems

## What is this?

ATLAS gives AI agents the ability to execute real DeFi strategies across multiple chains and protocols — with policy-enforced spending limits, contract whitelists, and revocable access keys. The agent holds an OWS wallet, not a raw private key.

```
perp ows setup
# => Wallet created, guardrail policy active, agent API key issued.
# => The agent can now trade on 3 perp DEXes and 5 DeFi chains.
# => It cannot exceed $1000/tx, $5000/day, or call approve().
```

## Architecture

```
                    ┌─────────────────────────────────┐
                    │      AI Agent (Claude Code)      │
                    │   MCP Server A    MCP Server B   │
                    └────────┬──────────────┬──────────┘
                             │              │
                    ┌────────▼──────┐ ┌─────▼────────┐
                    │   perp-cli    │ │   defi-cli   │
                    │ 3 Perp DEXes  │ │ 5 Chain DeFi │
                    │               │ │              │
                    │ • Hyperliquid │ │ • DEX Swap   │
                    │ • Pacifica    │ │ • Lending    │
                    │ • Lighter     │ │ • LP / Gauge │
                    │ • Arb Engine  │ │ • Yield Scan │
                    │ • Bot Engine  │ │ • Bridge     │
                    └────────┬──────┘ └─────┬────────┘
                             │              │
                    ┌────────▼──────────────▼──────────┐
                    │        OWS Wallet (shared)        │
                    │                                   │
                    │  EVM: 0x9A65...FdEe (all EVM)    │
                    │  SOL: F4VJnv...G11j (Solana)     │
                    │                                   │
                    │  ┌─────────────────────────────┐ │
                    │  │    perp-guardrail (policy)   │ │
                    │  │                              │ │
                    │  │  Contract whitelist (DEX)    │ │
                    │  │  $1000/tx limit              │ │
                    │  │  $5000/day limit             │ │
                    │  │  $500/withdrawal limit       │ │
                    │  │  approve() blocked           │ │
                    │  └─────────────────────────────┘ │
                    │                                   │
                    │  Bridge: CCTP V2 (free USDC)     │
                    │  Fund: MoonPay (4-chain deposit)  │
                    │  Pay: x402 (auto USDC payment)    │
                    └───────────────────────────────────┘
```

## Features

### Agent Spend Governance (Track 02)

| Feature | Description |
|---------|-------------|
| **Policy Guardrail** | Custom OWS executable that whitelists DEX contracts, enforces per-tx/daily USD limits, blocks dangerous functions |
| **Scoped API Keys** | Each agent gets its own `ows_key_...` token with specific wallet + policy bindings |
| **One-Click Setup** | `perp ows setup` creates wallet + policy + API key in one command |
| **Revocable Access** | `perp ows key revoke` instantly kills agent access |
| **Multi-Account** | Multiple OWS wallets, switch with `perp wallet use` or `--ows` per-command |

### Multi-Agent DeFi (Track 04)

| Feature | Description |
|---------|-------------|
| **3 Perp DEXes** | Hyperliquid, Pacifica, Lighter — funding rate arb, delta-neutral, grid, DCA |
| **5 Chain DeFi** | DEX swap, lending, LP positions, yield scanning across Base, Arbitrum, BNB, Polygon, Ethereum |
| **Cross-Chain Bridge** | Circle CCTP V2 — free USDC bridging between Solana, Arbitrum, Base, HyperCore |
| **MoonPay On-Ramp** | 4-chain deposit addresses, auto-convert to USDC |
| **x402 Payments** | Auto USDC micropayments for data services |
| **19 Bot Strategies** | TWAP, VWAP, grid, DCA, momentum, mean-reversion, delta-neutral, and more |

## Quick Start

```bash
# 1. Install
npm install -g perp-cli @hypurrquant/defi-cli
curl -fsSL https://docs.openwallet.sh/install.sh | bash

# 2. One-click setup (wallet + guardrail + agent key)
perp ows setup
# => Wallet: perp-trading (EVM + Solana)
# => Policy: perp-guardrail ($1000/tx, $5000/day, approve blocked)
# => Agent Token: ows_key_a1b2c3... (save this!)

# 3. Fund the wallet
perp ows fund deposit perp-trading --for hl    # Arbitrum USDC
perp ows fund deposit perp-trading --for pac   # Solana USDC

# 4. Agent trades (policy enforced)
perp --ows perp-trading --ows-key ows_key_a1b2c3 -e hl trade buy ETH 0.1

# 5. Owner trades (no limits)
perp --ows perp-trading -e hl trade buy ETH 10.0
```

## Demo: Agent Spend Governance

```bash
# Setup with conservative limits
perp ows setup --name demo --max-tx-usd 100 --max-daily-usd 500

# Agent tries small trade => ALLOWED
perp --ows demo --ows-key $TOKEN -e hl trade buy ETH 0.01

# Agent tries large trade => BLOCKED by guardrail
perp --ows demo --ows-key $TOKEN -e hl trade buy ETH 10.0
# => POLICY_DENIED: tx value exceeds limit $100

# Agent tries approve() => BLOCKED
# => POLICY_DENIED: function approve is blocked by policy

# Owner revokes agent access
perp ows key revoke $KEY_ID
# => Token is permanently useless
```

## Demo: Cross-Chain Arbitrage Agent

```bash
# Scan funding rates across 3 DEXes
perp arb scan

# Agent finds: HL ETH funding +0.05%, Pacifica ETH funding -0.02%
# Strategy: Long on Pacifica, Short on Hyperliquid => collect spread

# Execute with policy limits
perp --ows-key $TOKEN -e hl trade sell ETH 0.1
perp --ows-key $TOKEN -e pac trade buy ETH 0.1

# Bridge USDC between exchanges (free via CCTP V2)
perp bridge sol-to-arb 50
```

## Demo: Yield Optimization (perp-cli + defi-cli)

```bash
# Scan yields across 5 chains
defi yield scan

# Found: Base WETH/USDC LP at 58% APR
# Hedge: Short ETH on Hyperliquid to go delta-neutral

defi --ows demo -c base lp add WETH/USDC 500     # LP on Base
perp --ows demo -e hl trade sell ETH 0.15         # Hedge on HL

# Net: ~58% APR yield, delta-neutral
# Guardrail ensures max exposure $1000
```

## Guardrail Policy

```json
{
  "id": "perp-guardrail",
  "executable": "perp-guardrail",
  "config": {
    "max_tx_usd": 1000,
    "max_daily_usd": 5000,
    "max_withdraw_usd": 500,
    "max_daily_withdraw_usd": 2000,
    "block_selectors": ["0x095ea7b3", "0x23b872dd"]
  },
  "action": "deny"
}
```

| Check | Default | Configurable |
|-------|---------|-------------|
| Chain whitelist | All perp-cli chains | `--chains` |
| Contract whitelist | DEX contracts only | `allowed_contracts` |
| Per-tx limit | $1,000 | `--max-tx-usd` |
| Daily limit | $5,000 | `--max-daily-usd` |
| Withdrawal limit | $500/tx, $2,000/day | `--max-withdraw-usd` |
| Blocked functions | approve(), transferFrom() | `--block-approve` |
| Policy expiry | None | `--expires` |

## Security Model

```
Owner (passphrase)  =>  Full access, no policy checks
Agent (ows_key_...) =>  Policy evaluated BEFORE key decryption
                        Denied? Key material NEVER touched.
```

- Keys encrypted at rest (AES-256-GCM + scrypt)
- Agent tokens use HKDF-SHA256 for independent encryption
- Revoking a key = deleting encrypted copy (token becomes useless)
- Guardrail: 5-second timeout, fail-closed (deny on error)

## OWS Integration

| OWS Feature | Command | Method |
|-------------|---------|--------|
| Wallet CRUD | `perp ows create/list/info/delete` | NAPI |
| Signing (EVM) | `perp --ows <n> -e hl trade ...` | NAPI |
| Signing (Solana) | `perp --ows <n> -e pac trade ...` | NAPI |
| Policy Engine | `perp ows policy create/list/show/delete` | NAPI |
| Guardrail | `perp-guardrail` executable | stdin/stdout |
| API Keys | `perp ows key create/list/revoke` | NAPI |
| Fund Balance | `perp ows fund balance` | RPC |
| Fund Deposit | `perp ows fund deposit --for hl` | OWS CLI |
| x402 Payment | `perp ows pay <url>` | OWS CLI |
| Backup/Restore | `perp ows backup/restore` | OWS CLI |
| Key Rotation | `perp ows rotate` | OWS CLI |
| Service Discovery | `perp ows discover` | OWS CLI |

## Links

- **perp-cli**: [github.com/hypurrquant/perp-cli](https://github.com/hypurrquant/perp-cli/tree/feat/ows-v2)
- **defi-cli**: [github.com/hypurrquant/defi-cli](https://github.com/hypurrquant/defi-cli)
- **OWS**: [openwallet.sh](https://openwallet.sh)

## Built With

- [Open Wallet Standard](https://openwallet.sh) — Encrypted wallet + policy engine + agent access
- [MoonPay](https://moonpay.com) — Fiat on-ramp + multi-chain deposit
- [x402](https://x402.org) — HTTP micropayments (USDC)
- [Circle CCTP V2](https://circle.com/cctp) — Free cross-chain USDC bridging
- [Hyperliquid](https://hyperliquid.xyz), [Pacifica](https://pacifica.fi), [Lighter](https://lighter.xyz)

## License

MIT
