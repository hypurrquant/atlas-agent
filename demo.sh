#!/bin/bash
# ATLAS Agent — Full Demo Flow
set -e

WALLET="${1:-main}"
echo ""
echo "  ATLAS Agent Demo"
echo "  =============="
echo "  Wallet: $WALLET"
echo ""

# 1. Show OWS wallets
echo "=== 1. OWS Wallet List ==="
perp ows list
echo ""

# 2. Check balances across all exchanges
echo "=== 2. Exchange Balances (via OWS) ==="
echo "--- Hyperliquid ---"
perp --ows "$WALLET" -e hl --json account balance 2>/dev/null | \
  node -e "const d=JSON.parse(require('fs').readFileSync('/dev/stdin','utf8'));console.log('  Equity: \$'+d.data?.perp?.equity)" 2>/dev/null || echo "  (no account)"

echo "--- Lighter ---"
perp --ows "$WALLET" -e lt --json account balance 2>/dev/null | \
  node -e "const d=JSON.parse(require('fs').readFileSync('/dev/stdin','utf8'));console.log('  Equity: \$'+d.data?.perp?.equity)" 2>/dev/null || echo "  (no account)"
echo ""

# 3. On-chain balance
echo "=== 3. On-chain Balance ==="
perp ows fund balance "$WALLET" -c evm 2>/dev/null || echo "  (skipped)"
echo ""

# 4. Guardrail tests
echo "=== 4. Guardrail Policy Tests ==="

echo "--- Valid contract (allow) ---"
echo '{"chain_id":"eip155:42161","wallet_id":"t","api_key_id":"t","transaction":{"to":"0xb21D281DEdb17AE5B501F6AA8256fe38C4e45757","value":"0","data":"0x","raw_hex":"0x"},"spending":{"daily_total":"0","date":"2026-04-04"},"timestamp":"2026-04-04T00:00:00Z"}' | \
  npx perp-guardrail

echo ""
echo "--- Unknown contract (deny) ---"
echo '{"chain_id":"eip155:42161","wallet_id":"t","api_key_id":"t","transaction":{"to":"0xDEAD","value":"0","data":"0x","raw_hex":"0x"},"spending":{"daily_total":"0","date":"2026-04-04"},"timestamp":"2026-04-04T00:00:00Z"}' | \
  npx perp-guardrail

echo ""
echo "--- approve() call (deny) ---"
echo '{"chain_id":"eip155:42161","wallet_id":"t","api_key_id":"t","transaction":{"to":"0xb21D281DEdb17AE5B501F6AA8256fe38C4e45757","value":"0","data":"0x095ea7b3","raw_hex":"0x"},"spending":{"daily_total":"0","date":"2026-04-04"},"timestamp":"2026-04-04T00:00:00Z","policy_config":{"block_selectors":["0x095ea7b3"]}}' | \
  npx perp-guardrail

echo ""
echo "--- Amount exceeds limit (deny) ---"
echo '{"chain_id":"eip155:42161","wallet_id":"t","api_key_id":"t","transaction":{"to":"0xb21D281DEdb17AE5B501F6AA8256fe38C4e45757","value":"10000000000000000000","data":"0x","raw_hex":"0x"},"spending":{"daily_total":"0","date":"2026-04-04"},"timestamp":"2026-04-04T00:00:00Z","policy_config":{"max_tx_usd":100,"eth_price_usd":3500}}' | \
  npx perp-guardrail

echo ""

# 5. Fund deposit (MoonPay)
echo "=== 5. MoonPay Deposit (Arbitrum USDC) ==="
perp ows fund deposit "$WALLET" --for hl --json 2>/dev/null | \
  node -e "const d=JSON.parse(require('fs').readFileSync('/dev/stdin','utf8'));const a=d.data?.depositAddresses||{};console.log('  Target:', d.data?.targetAddress);Object.entries(a).forEach(([k,v])=>console.log('  '+k+':', v))" 2>/dev/null || echo "  (skipped — OWS CLI required)"

echo ""

# 6. Funding rate scan
echo "=== 6. Funding Rate Scan ==="
perp --json arb scan 2>/dev/null | \
  node -e "const d=JSON.parse(require('fs').readFileSync('/dev/stdin','utf8'));const r=d.data?.results?.slice(0,3)||[];r.forEach(s=>console.log('  '+s.symbol+': '+s.exchanges?.map(e=>e.exchange+'='+e.annualized+'%').join(' | ')))" 2>/dev/null || echo "  (skipped)"

echo ""
echo "  Demo complete!"
echo ""
