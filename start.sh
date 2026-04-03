#!/bin/bash
# ATLAS Agent — Launch autonomous DeFi trading agent
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo ""
echo "  ┌─────────────────────────────────┐"
echo "  │         ATLAS Agent             │"
echo "  │   Autonomous DeFi Orchestrator  │"
echo "  └─────────────────────────────────┘"
echo ""

# ── Preflight checks ──

check() {
  if command -v "$1" &>/dev/null || [ -f "$HOME/.ows/bin/$1" ]; then
    echo "  [OK] $1"
    return 0
  else
    echo "  [!!] $1 not found"
    return 1
  fi
}

MISSING=0
check ows     || MISSING=1
check perp    || MISSING=1
check nanobot || MISSING=1

if [ "$MISSING" -eq 1 ]; then
  echo ""
  echo "  Missing dependencies. Run:"
  echo "    docker compose up       # Docker (recommended)"
  echo ""
  echo "  Or install manually:"
  echo "    curl -fsSL https://docs.openwallet.sh/install.sh | bash"
  echo "    npm install -g perp-cli"
  echo "    pip install nanobot-ai"
  echo ""
  exit 1
fi

# ── Setup workspace ──

WORKSPACE="$HOME/.atlas-agent"
if [ ! -f "$WORKSPACE/SOUL.md" ]; then
  echo "  Setting up workspace..."
  bash "$SCRIPT_DIR/setup-workspace.sh" "$WORKSPACE"
fi

# ── Check OWS wallet ──

WALLET="${ATLAS_WALLET:-main}"
echo ""
echo "  Wallet: $WALLET"

if ! perp ows info "$WALLET" &>/dev/null; then
  echo "  No OWS wallet '$WALLET' found. Creating..."
  perp ows setup --name "$WALLET"
fi

EQUITY=$(perp --ows "$WALLET" -e hl --json account balance 2>/dev/null | node -e "const d=JSON.parse(require('fs').readFileSync('/dev/stdin','utf8'));console.log(d.data?.perp?.equity||'0')" 2>/dev/null || echo "0")
echo "  HL Equity: \$$EQUITY"
echo ""

# ── Check API key ──

if [ -z "$ANTHROPIC_API_KEY" ]; then
  echo "  [!!] ANTHROPIC_API_KEY not set"
  echo "  Export your API key: export ANTHROPIC_API_KEY=sk-ant-..."
  echo ""
  exit 1
fi

# ── Launch nanobot with ATLAS config ──

echo "  Starting ATLAS agent..."
echo ""
echo "  MCP Servers:"
echo "    - perp-mcp (perpetual futures: HL, Pacifica, Lighter)"
echo "    - ows (wallet management, signing, policy)"
echo ""
echo "  Guardrail: \$1000/tx, \$5000/day, approve() blocked"
echo "  ─────────────────────────────────────────────────"
echo ""

export PATH="$HOME/.ows/bin:$PATH"

nanobot --config "$SCRIPT_DIR/config.json"
