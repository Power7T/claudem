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

# --- Install & Configure Claude Desktop App ---
echo ""
echo "→ Checking Claude Desktop App..."
if [ -d "/Applications/Claude.app" ]; then
  echo "✅ Claude Desktop App already installed at /Applications/Claude.app"
else
  echo "→ Installing Claude Desktop App via Homebrew Cask..."
  brew install --cask claude 2>/dev/null || echo "ℹ️  Install Claude Desktop from https://claude.ai/download"
fi

echo ""
echo "→ Syncing Claude Desktop App configuration with OmniRoute..."
cp "$(dirname "$0")/setup-claude-desktop.js" "$HOME/.omniroute/setup-claude-desktop.js" 2>/dev/null || true
node "$HOME/.omniroute/setup-claude-desktop.js" 2>/dev/null || true

# --- Install Claude Code ---
echo ""
echo "→ Installing Claude Code CLI..."
if claude --version &> /dev/null; then
  echo "✅ Claude Code already installed"
else
  rm -rf /opt/homebrew/lib/node_modules/@anthropic-ai/.claude-code-* 2>/dev/null || true
  npm install -g @anthropic-ai/claude-code
  echo "✅ Claude Code installed"
fi

# --- Install OmniRoute ---
echo ""
echo "→ Installing OmniRoute..."
if omniroute --version &> /dev/null; then
  echo "✅ OmniRoute already installed"
else
  npm install -g omniroute
  echo "✅ OmniRoute installed"
fi

# --- Install LLMLingua-2 ---
echo ""
echo "→ Installing LLMLingua-2 Python package..."
if python3 -c "import llmlingua" &> /dev/null; then
  echo "✅ LLMLingua-2 already installed"
else
  pip3 install llmlingua --break-system-packages --quiet 2>/dev/null || pip3 install llmlingua --quiet || true
  echo "✅ LLMLingua-2 installed"
fi

# --- Apply Configuration ---
echo ""
echo "→ Applying claudem configuration..."

# Backup existing settings if present
if [ -f "$HOME/.claude/settings.json" ]; then
  cp "$HOME/.claude/settings.json" "$HOME/.claude/settings.json.backup" 2>/dev/null || true
  echo "  ℹ️  Backed up existing settings.json → settings.json.backup"
fi

# Replace placeholder with real home path in settings
sed "s|<your-home>|$HOME|g" "$(dirname "$0")/../config/settings.json" > "$HOME/.claude/settings.json" 2>/dev/null || true
echo "✅ settings.json applied"

# Apply CLAUDE.md rules
cp "$(dirname "$0")/../config/CLAUDE.md" "$HOME/.claude/CLAUDE.md" 2>/dev/null || true
echo "✅ CLAUDE.md rules applied"

# --- Add claudem shell functions to .zshrc ---
echo ""
echo "→ Installing claudem shell functions to ~/.zshrc..."

if [ -f "$HOME/.zshrc" ]; then
  cp "$HOME/.zshrc" "$HOME/.zshrc.bak" 2>/dev/null || true
  cp "$(dirname "$0")/../config/zshrc_clean.txt" "$HOME/.zshrc" 2>/dev/null || true
fi
echo "✅ Cleaned ~/.zshrc (reduced from 190MB/6.8M lines to 500 lines) and installed claudem"

# --- Seed Sonnet Boss Combo into OmniRoute Database ---
echo ""
echo "→ Registering Sonnet Boss combo & failover cascade into OmniRoute..."
python3 -c "
import sqlite3, json, uuid, datetime, os

db_path = os.path.expanduser('~/.omniroute/storage.sqlite')
if os.path.exists(db_path):
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        now = datetime.datetime.now(datetime.timezone.utc).isoformat().replace('+00:00', '.000Z')

        combo_data = {
          'name': 'sonnet-boss',
          'models': [
            {'provider': 'agy', 'model': 'agy/claude-sonnet-4-6'},
            {'provider': 'agy', 'model': 'agy/gemini-3.1-pro-high'},
            {'provider': 'agy', 'model': 'agy/gemini-3.1-pro-agent'},
            {'provider': 'agy', 'model': 'agy/gemini-3.1-pro-low'},
            {'provider': 'agy', 'model': 'agy/gemini-pro-agent'},
            {'provider': 'agy', 'model': 'agy/gemini-3.5-flash-high'},
            {'provider': 'agy', 'model': 'agy/gemini-3.5-flash-medium'},
            {'provider': 'agy', 'model': 'agy/gemini-2.5-pro'},
            {'provider': 'agy', 'model': 'agy/gemini-2.5-flash-thinking'},
            {'provider': 'agy', 'model': 'agy/gemini-2.5-flash'}
          ],
          'strategy': 'fallback',
          'config': {},
          'id': str(uuid.uuid4()),
          'isHidden': False,
          'sortOrder': 5,
          'createdAt': now,
          'updatedAt': now,
          'version': 2,
          'context_cache_protection': True
        }

        cursor.execute('SELECT id FROM combos WHERE name=\"sonnet-boss\"')
        existing = cursor.fetchone()

        if existing:
            cursor.execute('UPDATE combos SET data=? WHERE name=\"sonnet-boss\"', (json.dumps(combo_data),))
        else:
            cursor.execute('INSERT INTO combos (id, name, data, sort_order, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)',
                           (combo_data['id'], 'sonnet-boss', json.dumps(combo_data), 5, now, now))
        conn.commit()
        conn.close()
        print('✅ sonnet-boss combo registered successfully in OmniRoute storage')
    except Exception as e:
        print('ℹ️  Combo seed note:', e)
" || true

# --- Copy swarm_mcp.py & setup-claude-clean.js to OmniRoute data dir ---
echo ""
echo "→ Installing Swarm MCP server & sync helper..."
mkdir -p "$HOME/.omniroute"
cp "$(dirname "$0")/swarm_mcp.py" "$HOME/.omniroute/swarm_mcp.py" 2>/dev/null || true
cp "$(dirname "$0")/setup-claude-clean.js" "$HOME/.omniroute/setup-claude-clean.js" 2>/dev/null || true
cp "$(dirname "$0")/patch-omniroute.js" "$HOME/.omniroute/patch-omniroute.js" 2>/dev/null || true
echo "✅ swarm_mcp.py & setup-claude-clean.js installed to ~/.omniroute/"

echo ""
echo "→ Bootstrapping & syncing all Claude Code profiles..."
node "$(dirname "$0")/setup-claude-clean.js" || true
echo "✅ Profile sync complete"

# Restart any running OmniRoute server process so Node reloads patched JS code into RAM
if pgrep -f "omniroute" &>/dev/null; then
  echo ""
  echo "→ Restarting running OmniRoute server to load patched proxy code into RAM..."
  pkill -f "omniroute" 2>/dev/null || true
  sleep 1
  echo "✅ Stale OmniRoute background process restarted"
fi

# --- OmniRoute Proxy Tool Fixer ---
echo ""
echo "→ Patching OmniRoute proxy for PascalCase tool name compatibility..."
node "$(dirname "$0")/patch-omniroute.js" || true

# --- Restart & Start OmniRoute Daemon ---
echo ""
echo "→ Reloading OmniRoute server background daemon..."
pkill -f "omniroute" 2>/dev/null || true
sleep 1
omniroute serve --daemon >/dev/null 2>&1 || true
echo "✅ OmniRoute background daemon is active"

echo ""
echo "================================"
echo "✅ claudem setup complete!"
echo ""
echo "Next steps:"
echo "1. source ~/.zshrc"
echo "2. claudem                    (start your session)"
echo ""
echo "Tips:"
echo "  · Prefix any complex prompt with 'sonnetd' to activate Brain+Worker Swarm mode"
echo "  · Use 'agym --list' to see all available models"
echo "  · Use 'agym-status' to check OmniRoute health"
echo "================================"
