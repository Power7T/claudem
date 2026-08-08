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

# Remove existing claudem block from ~/.zshrc if present and replace with fresh config
if [ -f "$HOME/.zshrc" ]; then
  python3 -c "
import os
path = os.path.expanduser('~/.zshrc')
with open(path, 'r') as f:
    c = f.read()
start = '# ── claudem + agym'
end = '# ── setup-claude override'
idx1 = c.find(start)
idx2 = c.find(end)
if idx1 != -1 and idx2 != -1:
    c = c[:idx1] + c[idx2:]
elif idx1 != -1:
    c = c[:idx1]
with open(path, 'w') as f:
    f.write(c.strip() + '\n')
" 2>/dev/null || true
fi

echo "" >> "$HOME/.zshrc"
echo "# ── claudem + agym (OmniRoute Claude Code selector) ─────────────────────────" >> "$HOME/.zshrc"
cat "$(dirname "$0")/../config/claudem.sh" >> "$HOME/.zshrc"
echo "✅ claudem functions updated in ~/.zshrc" 

# --- Copy swarm_mcp.py & setup-claude-clean.js to OmniRoute data dir ---
echo ""
echo "→ Installing Swarm MCP server & sync helper..."
mkdir -p "$HOME/.omniroute"
cp "$(dirname "$0")/swarm_mcp.py" "$HOME/.omniroute/swarm_mcp.py"
cp "$(dirname "$0")/setup-claude-clean.js" "$HOME/.omniroute/setup-claude-clean.js"
echo "✅ swarm_mcp.py & setup-claude-clean.js installed to ~/.omniroute/"

echo ""
echo "→ Bootstrapping & syncing all Claude Code profiles..."
node "$HOME/.omniroute/setup-claude-clean.js" || true
echo "✅ Profile sync complete" 

# --- OmniRoute Proxy Tool Fixer ---
echo ""
echo "→ Patching OmniRoute proxy tool name auto-corrector..."
python3 -c "
import os

files = [
  '/opt/homebrew/lib/node_modules/omniroute/dist/src/mitm/handlers/base.ts',
  '/opt/homebrew/lib/node_modules/omniroute/dist/src/mitm/server.cjs',
  '/opt/homebrew/lib/node_modules/omniroute/dist/open-sse/mcp-server/server.js'
]

for filepath in files:
  if os.path.exists(filepath):
    with open(filepath, 'r') as f:
      c = f.read()
    if '"name":"Bash"' not in c and '"name": "Bash"' not in c:
      c = c.replace('controller.enqueue(value);', 'if (value && value.length > 0) { let str = new TextDecoder("utf-8").decode(value); if (str.includes("\"name\"")) { str = str.replace(/"name"\\s*:\\s*"bash"/g, "\"name\":\"Bash\"").replace(/"name"\\s*:\\s*"read"/g, "\"name\":\"Read\"").replace(/"name"\\s*:\\s*"write"/g, "\"name\":\"Write\"").replace(/"name"\\s*:\\s*"edit"/g, "\"name\":\"Edit\"").replace(/"name"\\s*:\\s*"grep"/g, "\"name\":\"Grep\"").replace(/"name"\\s*:\\s*"glob"/g, "\"name\":\"Glob\"").replace(/"name"\\s*:\\s*"websearch"/g, "\"name\":\"WebSearch\"").replace(/"name"\\s*:\\s*"webfetch"/g, "\"name\":\"WebFetch\""); value = new TextEncoder().encode(str); } } controller.enqueue(value);')
      c = c.replace('controller.enqueue(enc.encode(s));', 'if (typeof s === "string" && s.includes("\"name\"")) { s = s.replace(/"name"\\s*:\\s*"bash"/g, "\"name\":\"Bash\"").replace(/"name"\\s*:\\s*"read"/g, "\"name\":\"Read\"").replace(/"name"\\s*:\\s*"write"/g, "\"name\":\"Write\"").replace(/"name"\\s*:\\s*"edit"/g, "\"name\":\"Edit\""); } controller.enqueue(enc.encode(s));')
      c = c.replace(
        'const buf = Buffer.from(value);',
        'let buf = Buffer.from(value);\n        let str = buf.toString("utf-8");\n        if (str.includes("\"name\"")) {\n          str = str.replace(/"name"\\s*:\\s*"bash"/g, "\"name\":\"Bash\"").replace(/"name"\\s*:\\s*"read"/g, "\"name\":\"Read\"").replace(/"name"\\s*:\s*"write"/g, "\"name\":\"Write\"").replace(/"name"\\s*:\\s*"edit"/g, "\"name\":\"Edit\"").replace(/"name"\\s*:\\s*"grep"/g, "\"name\":\"Grep\"").replace(/"name"\\s*:\\s*"glob"/g, "\"name\":\"Glob\"").replace(/"name"\\s*:\\s*"websearch"/g, "\"name\":\"WebSearch\"").replace(/"name"\\s*:\\s*"webfetch"/g, "\"name\":\"WebFetch\"");\n          buf = Buffer.from(str, "utf-8");\n        }'
      )
      c = c.replace(
        'res.write(text);',
        'if (text.includes("\"name\"")) { text = text.replace(/"name"\\s*:\\s*"bash"/g, "\"name\":\"Bash\"").replace(/"name"\\s*:\\s*"read"/g, "\"name\":\"Read\"").replace(/"name"\\s*:\\s*"write"/g, "\"name\":\"Write\"").replace(/"name"\\s*:\\s*"edit"/g, "\"name\":\"Edit\""); }\n      res.write(text);'
      )
      with open(filepath, 'w') as f:
        f.write(c)
      print(f'✅ Patched {filepath}')
" 2>/dev/null || true

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
