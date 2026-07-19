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
echo "→ Installing LLMLingua-2..."
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

# Replace username placeholder in settings
sed "s|<your-username>|$(whoami)|g" "$(dirname "$0")/../config/settings.json" > "$HOME/.claude/settings.json"
echo "✅ settings.json applied"

# Apply CLAUDE.md rules
cp "$(dirname "$0")/../config/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
echo "✅ CLAUDE.md rules applied"

# --- Add alias ---
echo ""
echo "→ Adding claudem alias to ~/.zshrc..."

ALIAS_LINE="alias claudem='HOME=/Users/$(whoami) claude'"

if ! grep -q "alias claudem=" "$HOME/.zshrc" 2>/dev/null; then
  echo "" >> "$HOME/.zshrc"
  echo "# claudem — Autonomous AI Coding Agent" >> "$HOME/.zshrc"
  echo "$ALIAS_LINE" >> "$HOME/.zshrc"
  echo "✅ Alias added to ~/.zshrc"
else
  echo "ℹ️  claudem alias already exists in ~/.zshrc"
fi

# --- Done ---
echo ""
echo "================================"
echo "✅ claudem setup complete!"
echo ""
echo "Next steps:"
echo "  1. Run: source ~/.zshrc"
echo "  2. Run: omniroute setup  (add your API keys)"
echo "  3. Run: claudem  (start your first session)"
echo ""
echo "For Brain+Worker Swarm mode, prefix any prompt with 'sonnetd'"
echo "================================"
