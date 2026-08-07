#!/bin/bash

# claudem Health Check
# Verifies all components are installed and working correctly

echo "⚡ claudem Health Check"
echo "================================"

PASS=0
FAIL=0

check() {
  local name="$1"
  local cmd="$2"
  if eval "$cmd" &>/dev/null; then
    echo "✅ $name"
    ((PASS++))
  else
    echo "❌ $name"
    ((FAIL++))
  fi
}

echo ""
echo "→ Core Tools"
check "Claude Code CLI (claude)"   "command -v claude"
check "OmniRoute"                  "command -v omniroute"
check "Python 3"                   "command -v python3"
check "Git"                        "command -v git"
check "Node.js"                    "command -v node"

echo ""
echo "→ OmniRoute Server"
check "OmniRoute running (port 20128)" "curl -s --connect-timeout 3 http://localhost:20128/v1/models >/dev/null"
check "OmniRoute DB exists"        "[ -f $HOME/.omniroute/storage.sqlite ]"
check "AGY provider configured"    "omniroute providers list 2>/dev/null | grep -q antigravity"

echo ""
echo "→ claudem Config Files"
check "settings.json exists"       "[ -f $HOME/.claude/settings.json ]"
check "CLAUDE.md exists"           "[ -f $HOME/.claude/CLAUDE.md ]"
check "RTK.md exists"              "[ -f $HOME/.claude/RTK.md ]"
check "CLAUDE.md has 14 SDE rules" "grep -q 'SELF-HEALING' $HOME/.claude/CLAUDE.md && grep -q 'AUTONOMY' $HOME/.claude/CLAUDE.md"
check "settings.json apiTimeout"   "python3 -c \"import json; d=json.load(open('$HOME/.claude/settings.json')); assert d.get('apiTimeout',0)>=60000\""
check "settings.json smallFastModel" "grep -q 'smallFastModel' $HOME/.claude/settings.json"
check "settings.json effortLevel high" "python3 -c \"import json; d=json.load(open('$HOME/.claude/settings.json')); assert d.get('effortLevel')=='high'\""

echo ""
echo "→ MCP Servers"
check "Swarm MCP script exists"    "[ -f $HOME/.omniroute/swarm_mcp.py ]"
check "LLMLingua Python pkg"       "python3 -c 'import llmlingua'"
check "LLMLingua server.py exists" "[ -f $HOME/.llmlingua-mcp/server.py ]"
check "settings.json MCP llmlingua path correct" \
  "python3 -c \"import json; d=json.load(open('$HOME/.claude/settings.json')); assert '$HOME/.llmlingua-mcp/server.py' in str(d.get('mcpServers',{}).get('llmlingua',{}).get('args',[]))\""
check "settings.json MCP swarm configured" "grep -q 'swarm' $HOME/.claude/settings.json"

echo ""
echo "→ Shell Integration"
check "claudem() in .zshrc"        "grep -q 'claudem()' $HOME/.zshrc"
check "cm alias in .zshrc"         "grep -q 'alias cm=claudem' $HOME/.zshrc"
check "ANTHROPIC_HEADER env reset" "grep -q 'unset ANTHROPIC_HEADER_X_ROUTE_MODEL' $HOME/.zshrc"
check "AGY model catalog in .zshrc" "grep -q '_AGY_MODELS' $HOME/.zshrc"
check "CLAUDE_CODE_MAX_OUTPUT_TOKENS set" "grep -q 'CLAUDE_CODE_MAX_OUTPUT_TOKENS' $HOME/.zshrc"

echo ""
echo "→ Live AGY Model Spot-Check"
check "agy/claude-sonnet-4-6 responds" \
  "curl -s -X POST http://localhost:20128/v1/chat/completions \
    -H 'Content-Type: application/json' \
    -d '{\"model\":\"agy/claude-sonnet-4-6\",\"messages\":[{\"role\":\"user\",\"content\":\"hi\"}],\"max_tokens\":3}' \
    --max-time 15 | python3 -c \"import json,sys; d=json.load(sys.stdin); assert d.get('choices') or d.get('error',{}).get('code')!='MODEL_NOT_FOUND'\""
check "agy/gemini-3.5-flash-low responds" \
  "curl -s -X POST http://localhost:20128/v1/chat/completions \
    -H 'Content-Type: application/json' \
    -d '{\"model\":\"agy/gemini-3.5-flash-low\",\"messages\":[{\"role\":\"user\",\"content\":\"hi\"}],\"max_tokens\":3}' \
    --max-time 15 | python3 -c \"import json,sys; d=json.load(sys.stdin); assert d.get('choices') or d.get('error',{}).get('code')!='MODEL_NOT_FOUND'\""

echo ""
echo "================================"
echo "Results: $PASS passed, $FAIL failed"

if [ "$FAIL" -eq 0 ]; then
  echo "🎉 All checks passed! claudem is fully operational."
else
  echo "⚠️  $FAIL checks failed. See above for details."
  echo "   Run scripts/setup.sh to fix missing components."
fi
echo "================================"
