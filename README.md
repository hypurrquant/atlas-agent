# ATLAS Agent

**Autonomous DeFi Trading Agent** — powered by [nanobot](https://github.com/HKUDS/nanobot) + [OWS](https://openwallet.sh). Trades perpetual futures across 3 DEXes, optimizes yield across 5 chains, bridges assets — all from one encrypted wallet with policy guardrails.

> OWS Hackathon 2026 | Track 02: Agent Spend Governance | Track 04: Multi-Agent Systems

## How It Works

ATLAS is a fully autonomous AI agent that:
1. **Monitors** funding rates, prices, and yields across exchanges
2. **Analyzes** arbitrage opportunities and risk/reward
3. **Executes** trades via OWS-secured signing (agent never sees raw keys)
4. **Respects** policy guardrails — max $1000/tx, $5000/day, approve() blocked

```
┌─────────────────────────────────────────────┐
│            nanobot (AI Engine)               │
│                                             │
│  System Prompt: ATLAS trading strategy      │
│  Provider: Claude / GPT / any LLM           │
│                                             │
│  ┌─────────────┐    ┌───────────────┐       │
│  │  perp-mcp   │    │   ows mcp     │       │
│  │  (MCP)      │    │   (MCP)       │       │
│  └──────┬──────┘    └───────┬───────┘       │
└─────────┼───────────────────┼───────────────┘
          │                   │
  ┌───────▼───────┐   ┌──────▼──────┐
  │   perp-cli    │   │    OWS      │
  │               │   │             │
  │ • Hyperliquid │   │ • Wallet    │
  │ • Pacifica    │   │ • Signing   │
  │ • Lighter     │   │ • Policy    │
  │ • Arb Engine  │   │ • Guardrail │
  │ • 19 Bots     │   │ • MoonPay   │
  └───────┬───────┘   │ • x402      │
          │           └──────┬──────┘
          └────────┬─────────┘
                   │
          ┌────────▼────────┐
          │   OWS Wallet    │
          │  (AES-256-GCM)  │
          │                 │
          │  EVM + Solana   │
          │  Policy Engine  │
          │  perp-guardrail │
          └─────────────────┘
```

## Quick Start (Docker)

```bash
git clone https://github.com/hypurrquant/atlas-agent
cd atlas-agent

# Set your API key
export ANTHROPIC_API_KEY=sk-ant-...

# Launch (builds image with all dependencies)
docker compose up
```

Docker mounts `~/.ows` and `~/.perp` from host, so the agent shares your OWS wallet.

## Quick Start (Manual)

```bash
# 1. Install dependencies
pip install nanobot-ai                          # AI agent engine
npm install -g perp-cli                         # perp trading CLI (v0.11.0+)
curl -fsSL https://docs.openwallet.sh/install.sh | bash  # OWS wallet

# 2. Setup OWS wallet + guardrail + agent key
perp ows setup

# 3. Set your LLM API key
export ANTHROPIC_API_KEY=sk-ant-...

# 4. Launch ATLAS
./start.sh
```

## What ATLAS Does

### Autonomous Trading Loop

```
Every cycle:
  1. perp arb scan           → Find funding rate spreads
  2. perp account balance    → Check available capital
  3. Evaluate risk/reward    → AI decides strategy
  4. perp trade buy/sell     → Execute (OWS signs, guardrail validates)
  5. perp account positions  → Verify execution
  6. Report P&L              → Log results
```

### Real Example

```
ATLAS: Scanning funding rates...

  ETH funding: Hyperliquid +0.042%, Pacifica -0.018%
  Spread: 0.060% (annualized 21.9%)
  
  Action: Short 0.05 ETH on HL, Long 0.05 ETH on Pacifica
  
  Executing:
  > perp --ows main -e hl trade sell ETH 0.05
  > perp --ows main-sol -e pac trade buy ETH 0.05
  
  [OWS] Policy check: ALLOW (tx value $175 < limit $1000)
  
  Result: Positions opened. Collecting funding spread.
```

## Agent Spend Governance (Track 02)

ATLAS demonstrates how to give an AI agent real financial autonomy with safety:

| Layer | What It Does |
|-------|-------------|
| **OWS Wallet** | Agent holds encrypted wallet, never sees raw keys |
| **API Key** | Scoped `ows_key_...` token — revocable, per-wallet |
| **perp-guardrail** | Custom policy executable validates every signature |
| **Policy Config** | $1000/tx, $5000/day, approve() blocked, DEX contracts only |
| **Kill Switch** | `perp ows key revoke` → instant access termination |

### Guardrail in Action

```
Agent tries $5000 trade     → DENIED: tx value exceeds limit $1000
Agent tries approve()       → DENIED: function approve is blocked
Agent tries unknown contract → DENIED: contract not whitelisted
Agent tries $500 trade      → ALLOWED → OWS signs → exchange executes
```

## Multi-Agent Systems (Track 04)

ATLAS coordinates across multiple execution domains:

| Agent Domain | Tool | Chain |
|-------------|------|-------|
| Perp Trading | perp-cli | Arbitrum, Solana, ETH L2 |
| DeFi Yield | defi-cli | Base, Arbitrum, BNB, Polygon, ETH |
| Bridging | CCTP V2 | Cross-chain (free USDC) |
| Funding | MoonPay | 4-chain auto-convert deposit |
| Data | x402 | Pay-per-call market intelligence |

## Configuration

### config.json

```json
{
  "agents": {
    "defaults": {
      "model": "claude-sonnet-4-20250514",
      "provider": "anthropic"
    }
  },
  "tools": {
    "mcpServers": {
      "perp-cli": {
        "command": "perp-mcp",
        "args": []
      },
      "ows": {
        "command": "ows",
        "args": ["mcp"]
      }
    }
  }
}
```

### Policy Presets

| Preset | Per-TX | Daily | Withdraw | approve() |
|--------|--------|-------|----------|-----------|
| `conservative.json` | $500 | $2,000 | $200 | Blocked |
| `aggressive.json` | $5,000 | $20,000 | $2,000 | Blocked |

```bash
# Apply a policy preset
ows policy create --file policies/conservative.json
```

## Security Model

```
Owner (passphrase)  →  Full access, no limits
ATLAS (ows_key_...) →  Policy-gated: guardrail checks BEFORE key decryption
                       Denied? Key material NEVER touched.
                       Revoked? Encrypted copy deleted, token useless.
```

## Repository Structure

```
atlas-agent/
├── README.md              # This file
├── config.json            # nanobot + MCP server config
├── system-prompt.md       # ATLAS agent persona and strategy
├── start.sh               # Launch script (preflight + nanobot)
├── setup.sh               # One-click install (OWS + perp-cli + nanobot)
├── demo.sh                # Demo: balances, guardrail, MoonPay, arb scan
└── policies/
    ├── conservative.json  # $500/tx, $2000/day
    └── aggressive.json    # $5000/tx, $20000/day
```

## Links

- **perp-cli v0.11.0**: [npm](https://npmjs.com/package/perp-cli) | [github](https://github.com/hypurrquant/perp-cli)
- **defi-cli v0.4.1**: [npm](https://npmjs.com/package/@hypurrquant/defi-cli) | [github](https://github.com/hypurrquant/defi-cli)
- **nanobot**: [github](https://github.com/HKUDS/nanobot) | [pypi](https://pypi.org/project/nanobot-ai/)
- **OWS**: [spec](https://openwallet.sh) | [docs](https://docs.openwallet.sh)

## Built With

- [nanobot](https://github.com/HKUDS/nanobot) — Ultra-lightweight AI agent engine (MCP, cron, channels)
- [Open Wallet Standard](https://openwallet.sh) — Encrypted wallet + policy engine + agent access
- [MoonPay](https://moonpay.com) — Fiat on-ramp + multi-chain deposit
- [x402](https://x402.org) — HTTP micropayments (USDC)
- [Circle CCTP V2](https://circle.com/cctp) — Free cross-chain USDC bridging

## License

MIT
