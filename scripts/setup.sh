#!/bin/bash

# claudem Setup Script
# Installs and configures claudem — the autonomous Principal Engineer terminal agent

set -e

echo "⚡ claudem Setup"
echo "================================"

# --- Prerequisites Check ---
echo ""
echo "→ Checking prerequisites..."

if ! command -v node &> /dev/null; then
  echo "❌ Node.js not found. Install from https://nodejs.org"
  exit 1
fi

if ! command -v python3 &> /dev/null; then
  echo "❌ Python 3 not found. Install from https://python.org"
  exit 1
fi

echo "✅ Node.js $(node --version)"
echo "✅ Python $(python3 --version)"

# --- Install Claude Code ---
echo ""
echo "→ Installing Claude Code CLI..."
npm install -g @anthropic-ai/claude-code
echo "✅ Claude Code installed"

# --- Install OmniRoute ---
echo ""
echo "→ Installing OmniRoute..."
npm install -g omniroute
echo "✅ OmniRoute installed"

# --- Install LLMLingua-2 ---
echo ""
echo "→ Installing LLMLingua-2 Python package..."
pip3 install llmlingua --quiet
echo "✅ LLMLingua-2 installed"

# --- Apply Configuration ---
echo ""
echo "→ Applying claudem configuration..."

# Backup existing settings if present
if [ -f "$HOME/.claude/settings.json" ]; then
  cp "$HOME/.claude/settings.json" "$HOME/.claude/settings.json.backup"
  echo "  ℹ️  Backed up existing settings.json → settings.json.backup"
fi

# Replace placeholder with real home path in settings
sed "s|<your-home>|$HOME|g" "$(dirname "$0")/../config/settings.json" > "$HOME/.claude/settings.json"
echo "✅ settings.json applied"

# Apply CLAUDE.md rules
cp "$(dirname "$0")/../config/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
echo "✅ CLAUDE.md rules applied"

# --- Add claudem shell functions to .zshrc ---
echo ""
echo "→ Installing claudem shell functions to ~/.zshrc..."

if ! grep -q "claudem()" "$HOME/.zshrc" 2>/dev/null; then
  echo "" >> "$HOME/.zshrc"
  echo "# ── claudem + agym (OmniRoute Claude Code selector) ─────────────────────────" >> "$HOME/.zshrc"
  cat "$(dirname "$0")/../config/claudem.sh" >> "$HOME/.zshrc"
  echo "✅ claudem functions installed to ~/.zshrc"
else
  echo "ℹ️  claudem function already exists in ~/.zshrc — skipping (update manually if needed)"
fi

# --- Copy swarm_mcp.py to OmniRoute data dir ---
echo ""
echo "→ Installing Swarm MCP server..."
mkdir -p "$HOME/.omniroute"
cp "$(dirname "$0")/swarm_mcp.py" "$HOME/.omniroute/swarm_mcp.py"
echo "✅ swarm_mcp.py installed to ~/.omniroute/"

# --- Done ---
echo ""
echo "================================"
echo "✅ claudem setup complete!"
echo ""
echo "Next steps:"
echo "  1. source ~/.zshrc"
echo "  2. omniroute serve            (start the proxy)"
echo "  3. omniroute providers add google  (add your AGY/Google AI Pro account)"
echo "  4. claudem                    (start your first session)"
echo ""
echo "Tips:"
echo "  · Prefix any complex prompt with 'sonnetd' to activate Brain+Worker Swarm mode"
echo "  · Use 'agym --list' to see all available models"
echo "  · Use 'agym-status' to check OmniRoute health"
echo "================================"
