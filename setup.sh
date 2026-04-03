#!/bin/bash
# ATLAS Agent — One-click setup
set -e

echo ""
echo "  ATLAS Agent Setup"
echo "  ==============="
echo ""

# 1. Check OWS CLI
if ! command -v ows &>/dev/null && [ ! -f "$HOME/.ows/bin/ows" ]; then
  echo "  Installing OWS CLI..."
  curl -fsSL https://docs.openwallet.sh/install.sh | bash
  export PATH="$HOME/.ows/bin:$PATH"
fi
echo "  [OK] OWS CLI"

# 2. Check perp-cli
if ! command -v perp &>/dev/null; then
  echo "  Installing perp-cli..."
  npm install -g perp-cli
fi
echo "  [OK] perp-cli"

# 3. Check defi-cli
if ! command -v defi &>/dev/null; then
  echo "  Installing defi-cli..."
  npm install -g defi-cli
fi
echo "  [OK] defi-cli"

# 4. Setup OWS wallet + guardrail + agent key
echo ""
echo "  Setting up OWS wallet with guardrail policy..."
echo ""

WALLET_NAME="${1:-ows-agent}"
MAX_TX="${2:-1000}"
MAX_DAILY="${3:-5000}"

perp ows setup \
  --name "$WALLET_NAME" \
  --max-tx-usd "$MAX_TX" \
  --max-daily-usd "$MAX_DAILY"

echo ""
echo "  Setup complete! You can now use:"
echo ""
echo "    perp --ows $WALLET_NAME -e hl account balance"
echo "    perp ows fund deposit $WALLET_NAME --for hl"
echo ""
