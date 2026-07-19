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
check "Claude Code CLI" "command -v claude"
check "OmniRoute" "command -v omniroute"
check "Python 3" "command -v python3"
check "Git" "command -v git"
check "Node.js" "command -v node"

echo ""
echo "→ claudem Config Files"
check "settings.json exists" "[ -f $HOME/.claude/settings.json ]"
check "CLAUDE.md exists" "[ -f $HOME/.claude/CLAUDE.md ]"
check "RTK.md exists" "[ -f $HOME/.claude/RTK.md ]"
check "CLAUDE.md has SDE rules" "grep -q 'SELF-HEALING' $HOME/.claude/CLAUDE.md"
check "settings.json has apiTimeout" "grep -q 'apiTimeout' $HOME/.claude/settings.json"
check "settings.json has smallFastModel" "grep -q 'smallFastModel' $HOME/.claude/settings.json"
check "MCP swarm configured" "grep -q 'swarm' $HOME/.claude/settings.json"
check "MCP llmlingua configured" "grep -q 'llmlingua' $HOME/.claude/settings.json"

echo ""
echo "→ MCP Servers"
check "Swarm MCP script exists" "[ -f $HOME/.omniroute/swarm_mcp.py ]"
check "LLMLingua installed" "python3 -c 'import llmlingua' 2>/dev/null"

echo ""
echo "→ OmniRoute"
check "OmniRoute DB exists" "[ -f $HOME/.omniroute/storage.sqlite ]"
check "OmniRoute combos loaded" "omniroute models 2>/dev/null | grep -q 'agy'"

echo ""
echo "→ claudem alias"
check "claudem alias in .zshrc" "grep -q 'alias claudem' $HOME/.zshrc"

echo ""
echo "================================"
echo "Results: $PASS passed, $FAIL failed"

if [ "$FAIL" -eq 0 ]; then
  echo "🎉 All checks passed! claudem is fully operational."
else
  echo "⚠️  $FAIL checks failed. Run scripts/setup.sh to fix."
fi
echo "================================"
