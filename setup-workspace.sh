#!/bin/bash
# Setup nanobot workspace with ATLAS config
set -e

WORKSPACE="${1:-$HOME/.atlas-agent}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "  Setting up ATLAS workspace at $WORKSPACE"

mkdir -p "$WORKSPACE"
cp "$SCRIPT_DIR/workspace/SOUL.md" "$WORKSPACE/SOUL.md"
cp "$SCRIPT_DIR/workspace/AGENTS.md" "$WORKSPACE/AGENTS.md"

echo "  [OK] Workspace ready"
