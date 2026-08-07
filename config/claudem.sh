# ── OmniRoute Configuration ────────────────────────────────────────────────────
export DATA_DIR="$HOME/.omniroute"
export GEMINI_BASE_URL="http://localhost:20128/v1"
export OMNIROUTE_URL="http://localhost:20128"

# ── agy/ model catalog ─────────────────────────────────────────────────────────
# OmniRoute removed agy/ models from /v1/models in a recent update (they are
# now MITM-intercepted only). Hardcoded here so agym always shows them.
# Update this list if OmniRoute adds/removes agy models.
_AGY_MODELS=(
  "agy/gemini-3.1-pro-high|Gemini 3.1 Pro (High)|1048K|v,t"
  "agy/gemini-3.1-pro-low|Gemini 3.1 Pro (Low)|1048K|v,t"
  "agy/gemini-pro-agent|Gemini 3.1 Pro (Agent)|1048K|v,t"
  "agy/gemini-3.5-flash-high|Gemini 3.5 Flash (High)|1048K|v,t"
  "agy/gemini-3.5-flash-medium|Gemini 3.5 Flash (Medium)|1048K|v,t"
  "agy/gemini-3.5-flash-low|Gemini 3.5 Flash (Low)|1048K|v"
  "agy/gemini-3.1-flash-lite|Gemini 3.1 Flash Lite|1048K|v"
  "agy/gemini-3.1-flash-image|Gemini 3.1 Flash Image|1000K|v"
  "agy/gemini-2.5-pro|Gemini 2.5 Pro|1048K|v,t"
  "agy/gemini-2.5-flash|Gemini 2.5 Flash|1048K|v"
  "agy/gemini-2.5-flash-thinking|Gemini 2.5 Flash Thinking|1048K|v,t"
  "agy/gemini-2.5-flash-lite|Gemini 2.5 Flash Lite|1048K|v"
  "agy/claude-opus-4-6-thinking|Claude Opus 4.6 (Thinking)|200K|v,t"
  "agy/claude-sonnet-4-6|Claude Sonnet 4.6 (Thinking)|200K|v,t"
)

# ── Coding combos shown in agym ─────────────────────────────────────────────
# Hardcoded so only YOUR combos appear — no OmniRoute auto/* clutter.
# Format: "combo/<name>|<display label>|<ctx>|<caps>"
_CODING_COMBOS=(
  "combo/code-sprint|⚡ Code Sprint   · round-robin Flash (medium+low+lite)|1048K|t"
  "combo/architect|🏗️  Architect     · priority Pro for design & refactor|1048K|t"
  "combo/debugger|🐛 Debugger      · LKGP Claude-first for bug hunting|1048K|t"
  "combo/bigbrain|📄 Big Brain     · context-optimized huge codebases|1048K|t"
  "combo/turbo|🚀 Turbo         · least-used Flash for max speed|1048K|t"
  "combo/test-forge|🧪 Test Forge    · priority Sonnet for test writing|1048K|t"
  "combo/agentic-coder|🤖 Agentic Coder · reset-aware for long agent runs|1048K|t"
  "combo/web-builder|🌐 Web Builder   · Stitch MCP + vision models for UI/CSS/React|1048K|v,t"
  "combo/master-reasoner|🧠 Master Reasoner · priority Opus-thinking for logic & architecture|1048K|t"
  "combo/pure-thinking|🧠 Pure Thinking  · pure Opus-thinking with no fallbacks|200K|t"
  "combo/gemini-coder|🤖 Gemini Coder    · dedicated Gemini models for coding|1048K|t"
)

# ── Provider display names ─────────────────────────────────────────────────────
# Maps owned_by → friendly label shown in agym header rows
declare -A _OMNIROUTE_PROVIDER_LABELS
_OMNIROUTE_PROVIDER_LABELS=(
  [agy]="agy  ·  Google AI Pro (Gemini + Claude via MITM)"
  [coding-combos]="⚙️  Coding Combos  · Your smart routing presets"
  [combo]="auto  ·  Smart Router (picks best available model)"
  [opencode]="opencode  ·  OpenCode Free Models"
  [theoldllm]="theoldllm  ·  The Old LLM (GPT-5, Claude, Gemini free)"
  [duckduckgo-web]="ddgw  ·  DuckDuckGo AI Chat (free, no key)"
  [mimocode]="mimocode  ·  MiMo Code"
  [chipotle]="chipotle  ·  Chipotle AI (Pepper)"
)

# ── agym-status ────────────────────────────────────────────────────────────────
agym-status() {
  local url="${OMNIROUTE_URL:-http://localhost:20128}"
  if ! curl -s --connect-timeout 2 "$url/v1/models" >/dev/null 2>&1; then
    echo "❌ OmniRoute is NOT running at $url"
    echo "   Start with: omniroute serve"
    return 1
  fi
  local rest_count
  rest_count=$(curl -s "$url/v1/models" | python3 -c "
import json,sys
d=json.load(sys.stdin)
groups={}
for m in d.get('data',[]):
    if m.get('type')=='video': continue
    ob=m.get('owned_by','?')
    groups[ob]=groups.get(ob,0)+1
for ob,n in sorted(groups.items()): print(f'   [{ob}]  {n} models')
" 2>/dev/null)
  echo "✅ OmniRoute LIVE at $url"
  echo ""
  echo "   Provider groups in /v1/models:"
  echo "$rest_count"
  echo "   [agy]  ${#_AGY_MODELS[@]} models  (MITM-injected, Google AI Pro)"
  echo ""
  local configured
  configured=$(omniroute providers list 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g' | grep -E "^[a-f0-9]+" | awk '{print "   •", $2, $3, $4, $5}')
  echo "   Configured API providers:"
  [[ -n "$configured" ]] && echo "$configured" || echo "   (none)"
  echo ""
  echo "   Run \`agym\` to pick · \`agym --list\` for full table"
}

# ── _agym_build_table ──────────────────────────────────────────────────────────
# Builds the pipe-separated model table: id|name|ctx|caps|provider
# Always includes all providers — agy/ injected, /v1/models for the rest.
# Note: OmniRoute removed agy/ models from /v1/models (now MITM-only), so they
# are injected from _AGY_MODELS rather than filtered from REST.
# 'combo' (auto/ router) is always included when any provider is configured.
typeset -A _PROVIDER_TO_OWNED_BY
_PROVIDER_TO_OWNED_BY=(
  [openai]='openai'
  [anthropic]='anthropic'
  [groq]='groq'
  [mistral]='mistral'
  [openrouter]='openrouter'
)

_agym_build_table() {
  local url="${OMNIROUTE_URL:-http://localhost:20128}"

  # Get currently configured provider IDs from omniroute
  local configured_providers
  configured_providers=$(omniroute providers list 2>/dev/null \
    | sed 's/\x1b\[[0-9;]*m//g' \
    | grep -E '^[a-f0-9]+' \
    | awk '{print $2}')

  if [[ -z "$configured_providers" ]]; then
    echo "⚠️  No providers configured in OmniRoute." >&2
    echo "   Add one: omniroute providers add google" >&2
    return 1
  fi

  local has_google=0
  local rest_owned_by=()
  while IFS= read -r pid; do
    [[ -z "$pid" ]] && continue
    [[ "$pid" == 'google' || "$pid" == 'antigravity' ]] && has_google=1
    [[ -n "${_PROVIDER_TO_OWNED_BY[$pid]}" ]] && rest_owned_by+=("${_PROVIDER_TO_OWNED_BY[$pid]}")
  done <<< "$configured_providers"

  local raw_json
  raw_json=$(curl -s --connect-timeout 4 "$url/v1/models" 2>/dev/null)
  [[ -z "$raw_json" ]] && return 1

  python3 -c "
import json, sys
data        = json.loads(sys.argv[1])
agy_lines   = sys.argv[2].split('|||') if sys.argv[2] else []
has_google  = sys.argv[3] == '1'
rest_allow  = set(sys.argv[4].split(',')) if sys.argv[4] else set()
# combo excluded — agym shows only agy + explicitly configured API providers

seen = set()
rows = []

# 1. Inject agy/ models when google/antigravity provider is configured
if has_google:
    for line in agy_lines:
        if not line.strip(): continue
        parts = line.split('|')
        if len(parts) < 4: continue
        mid = parts[0]
        if mid in seen: continue
        seen.add(mid)
        rows.append(line + '|agy')

# 2. REST models filtered to configured providers + combo
from collections import defaultdict
groups = defaultdict(list)
for m in data.get('data', []):
    mid = m.get('id', '')
    ob  = m.get('owned_by', '')
    if not mid or mid in seen: continue
    if m.get('type') == 'video': continue
    if ob == 'openrouter': continue  # completely exclude OpenRouter models from agym
    if ob not in rest_allow: continue
    seen.add(mid)
    name = m.get('name') or mid
    ctx  = m.get('context_length') or '?'
    caps = m.get('capabilities', {})
    tags = []
    if caps.get('vision'):   tags.append('v')
    if caps.get('thinking'): tags.append('t')
    if ctx != '?': ctx = str(int(ctx)//1000) + 'K'
    groups[ob].append(mid + '|' + name + '|' + str(ctx) + '|' + ','.join(tags) + '|' + ob)

# agy first (already injected), then rest in sorted order
for ob in sorted(groups.keys()):
    rows.extend(groups[ob])

print('\n'.join(rows))
" "$raw_json" "${(j:|||:)_AGY_MODELS}" "$has_google" "${(j:,:)rest_owned_by}" 2>/dev/null

  # Inject dynamic numeric profiles at the top of combos
  local d
  for d in "$HOME"/.claude/profiles/[0-9]*(N); do
    [[ -d "$d" ]] || continue
    local name="${d##*/}"
    echo "combo/$name|⚡ Profile $name   · dedicated history with dynamic model selection|1048K|t|coding-combos"
  done

  # Inject coding combos as a separate section at the bottom
  for combo_line in "${_CODING_COMBOS[@]}"; do
    echo "${combo_line}|coding-combos"
  done
}

# ── agym ───────────────────────────────────────────────────────────────────────
# Usage:
#   agym                 → interactive picker — configured providers only
#   agym --list          → model table grouped by provider
#   agym --model <term>  → fuzzy jump: agym --model sonnet / agym --model flash
#   agym --continue      → extra flags forwarded to agy
agym() {
  local url="${OMNIROUTE_URL:-http://localhost:20128}"
  local extra_args=()
  local jump_model=""
  local list_only=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --list)  list_only=true; shift ;;
      --model) jump_model="$2"; shift 2 ;;
      *)       extra_args+=("$1"); shift ;;
    esac
  done

  local model_table
  model_table=$(_agym_build_table)
  if [[ -z "$model_table" ]]; then
    echo "❌ OmniRoute is not reachable at $url"
    echo "   Start with: omniroute serve"
    return 1
  fi

  # ── --list mode ───────────────────────────────────────────────────────────
  if $list_only; then
    printf "\n  %-50s %-36s %-7s %s\n" "MODEL ID" "NAME" "CTX" "CAPS"
    printf '  '; printf -- '─%.0s' {1..103}; echo
    local last_ob=""
    while IFS='|' read -r mid mname mctx mcaps mob; do
      if [[ "$mob" != "$last_ob" ]]; then
        local label="${_OMNIROUTE_PROVIDER_LABELS[$mob]:-$mob}"
        printf "\n  ┌─ %s\n" "$label"
        last_ob="$mob"
      fi
      local capstr=""
      [[ "$mcaps" == *"v"* ]] && capstr+="vision "
      [[ "$mcaps" == *"t"* ]] && capstr+="think"
      printf "  │  %-48s %-36s %-7s %s\n" "$mid" "$mname" "$mctx" "$capstr"
    done <<< "$model_table"
    echo ""
    return 0
  fi

  # ── Fuzzy jump ─────────────────────────────────────────────────────────────
  if [[ -n "$jump_model" ]]; then
    local matched
    matched=$(echo "$model_table" | awk -F'|' -v q="$jump_model" \
      'tolower($1) ~ tolower(q) || tolower($2) ~ tolower(q) {print $1; exit}')
    if [[ -z "$matched" ]]; then
      echo "⚠️  No model matched '$jump_model'."
      echo "   Run: agym --list"
      return 1
    fi
    echo "🚀 Launching agy → $matched"
    GEMINI_BASE_URL="$url/v1" agy --model "$matched" --dangerously-skip-permissions "${extra_args[@]}"
    return
  fi

  # ── Interactive menu ────────────────────────────────────────────────────────
  echo ""
  echo "  ╔══════════════════════════════════════════════════════╗"
  echo "  ║     OmniRoute Model Selector  [agym]                ║"
  echo "  ╚══════════════════════════════════════════════════════╝"
  echo ""

  local -a all_ids=() all_labels=()
  local last_ob=""
  while IFS='|' read -r mid mname mctx mcaps mob; do
    if [[ "$mob" != "$last_ob" ]]; then
      local label="${_OMNIROUTE_PROVIDER_LABELS[$mob]:-$mob}"
      all_ids+=("---")
      all_labels+=("── $label")
      last_ob="$mob"
    fi
    all_ids+=("$mid")
    local capstr=""
    [[ "$mcaps" == *"v"* ]] && capstr+="[v] "
    [[ "$mcaps" == *"t"* ]] && capstr+="[t]"
    all_labels+=("$(printf '%-38s  %-6s  %s' "$mname" "$mctx" "$capstr")")
  done <<< "$model_table"

  echo "  Select a model (Ctrl-C to cancel):"
  echo ""
  local i=1
  local -a selectable_ids=()
  local idx
  for (( idx=1; idx <= ${#all_ids[@]}; idx++ )); do
    local id="${all_ids[$idx]}"
    local label="${all_labels[$idx]}"
    if [[ "$id" == "---" ]]; then
      printf "\n  %s\n" "$label"
    else
      printf "    %3d)  %s\n" "$i" "$label"
      selectable_ids+=("$id")
      (( i++ ))
    fi
  done

  echo ""
  printf "  Enter number [1-$((i-1))]: "
  local choice
  read choice

  if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > i-1 )); then
    echo "  Canceled."
    return 0
  fi

  local selected_id="${selectable_ids[$choice]}"
  echo "  🚀 Launching agy → $selected_id"
  GEMINI_BASE_URL="$url/v1" agy --model "$selected_id" --dangerously-skip-permissions "${extra_args[@]}"
}

# ── _agym_select_model ───────────────────────────────────────────────────────
# Sub-selector used inside claudem() for dynamic profile model picking.
# Renders the menu to stderr so it doesn't pollute the captured return value.
_agym_select_model() {
  local model_table="$1"
  local -a all_ids=() all_labels=()
  local last_ob=""

  while IFS='|' read -r mid mname mctx mcaps mob; do
    # Skip profile 1 itself from the selection list
    [[ "$mid" == "combo/1" ]] && continue

    if [[ "$mob" != "$last_ob" ]]; then
      local label="${_OMNIROUTE_PROVIDER_LABELS[$mob]:-$mob}"
      all_ids+=("---")
      all_labels+=("── $label")
      last_ob="$mob"
    fi
    all_ids+=("$mid")
    local capstr=""
    [[ "$mcaps" == *"v"* ]] && capstr+="[v] "
    [[ "$mcaps" == *"t"* ]] && capstr+="[t]"
    all_labels+=("$(printf '%-38s  %-6s  %s' "$mname" "$mctx" "$capstr")")
  done <<< "$model_table"

  echo "  Select a target model/combo for this session (Ctrl-C to cancel):" >&2
  echo "" >&2
  local i=1
  local -a selectable_ids=()
  local idx
  for (( idx=1; idx <= ${#all_ids[@]}; idx++ )); do
    local id="${all_ids[$idx]}"
    local label="${all_labels[$idx]}"
    if [[ "$id" == "---" ]]; then
      printf "\n  %s\n" "$label" >&2
    else
      printf "    %3d)  %s\n" "$i" "$label" >&2
      selectable_ids+=("$id")
      (( i++ ))
    fi
  done

  echo "" >&2
  printf "  Enter number [1-$((i-1))]: " >&2
  local choice
  read choice < /dev/tty

  if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > i-1 )); then
    return 1
  fi

  echo "${selectable_ids[$choice]}"
}

# claudem — Autonomous AI Coding Agent
# ── claudem ───────────────────────────────────────────────────────────────────
# Claude Code profile selector and launcher.
# Supports interactive mode, fuzzy model resolution, and command forwarding.
#
# Usage:
#   claudem               → interactive TUI — pick model/combo then launch
#   claudem <term>        → fuzzy match: claudem sonnet / claudem debugger
#   claudem <1-5>         → launch isolated numbered profile slot
#   cm                    → alias for claudem
claudem() {
  unset ANTHROPIC_HEADER_X_ROUTE_MODEL  # reset any stale value from a previous session
  local url="${OMNIROUTE_URL:-http://localhost:20128}"
  local model_table
  model_table=$(_agym_build_table)
  if [[ -z "$model_table" ]]; then
    echo "🔄 OmniRoute is offline. Auto-starting background server..."
    nohup omniroute serve > "$HOME/.omniroute/server.log" 2>&1 &
    sleep 3
    model_table=$(_agym_build_table)
    if [[ -z "$model_table" ]]; then
      echo "❌ Failed to auto-start OmniRoute. Try manually: omniroute serve"
      return 1
    fi
  fi

  local profile_name=""
  local extra_args=()
  local mode=""

  # Check if first arg is "command"
  if [[ "$1" == "command" ]]; then
    mode="command"
    shift
  fi

  if [[ $# -gt 0 ]]; then
    # Parse search term
    local search_term="$1"
    shift

    if [[ "$search_term" =~ ^[1-5]$ ]]; then
      profile_name="$search_term"
    else
      # Fuzzy match to model ID
      local matched
      matched=$(echo "$model_table" | awk -F'|' -v q="$search_term" \
        'tolower($1) ~ tolower(q) || tolower($2) ~ tolower(q) {print $1; exit}')

      if [[ -n "$matched" ]]; then
        if [[ "$matched" == combo/* ]]; then
          profile_name="${matched#combo/}"
          export ANTHROPIC_HEADER_X_ROUTE_MODEL="$matched"
          extra_args=("--model" "claude-3-5-sonnet-20241022" "${extra_args[@]}")
        elif [[ "$matched" == *"/"* ]]; then
          profile_name=$(echo "$matched" | tr '/' '-' | tr '_' '-' | tr '.' '-')
        else
          profile_name="$matched"
        fi
      else
        # Fall back to checking direct directory
        if [[ -d "$HOME/.claude/profiles/$search_term" ]]; then
          profile_name="$search_term"
        else
          echo "⚠️  No model/profile matched '$search_term'."
          echo "   Available profiles:"
          ls -1 "$HOME/.claude/profiles/" | grep -v '^\.' | awk '{print "     • " $1}'
          return 1
        fi
      fi
    fi
    extra_args+=("$@")
  else
    # Interactive mode
    echo ""
    echo "  ╔══════════════════════════════════════════════════════╗"
    echo "  ║     OmniRoute Claude Code Selector  [claudem]        ║"
    echo "  ╚══════════════════════════════════════════════════════╝"
    echo ""

    local -a all_ids=() all_labels=()
    local last_ob=""
    while IFS='|' read -r mid mname mctx mcaps mob; do
      if [[ "$mob" != "$last_ob" ]]; then
        local label="${_OMNIROUTE_PROVIDER_LABELS[$mob]:-$mob}"
        all_ids+=("---")
        all_labels+=("── $label")
        last_ob="$mob"
      fi
      all_ids+=("$mid")
      local capstr=""
      [[ "$mcaps" == *"v"* ]] && capstr+="[v] "
      [[ "$mcaps" == *"t"* ]] && capstr+="[t]"
      all_labels+=("$(printf '%-38s  %-6s  %s' \"$mname\" \"$mctx\" \"$capstr\")")
    done <<< "$model_table"

    echo "  Select a Claude Code profile (Ctrl-C to cancel):"
    echo ""
    local i=1
    local -a selectable_ids=()
    local idx
    for (( idx=1; idx <= ${#all_ids[@]}; idx++ )); do
      local id="${all_ids[$idx]}"
      local label="${all_labels[$idx]}"
      if [[ "$id" == "---" ]]; then
        printf "\n  %s\n" "$label"
      else
        printf "    %3d)  %s\n" "$i" "$label"
        selectable_ids+=("$id")
        (( i++ ))
      fi
    done

    echo ""
    printf "  Enter number [1-$((i-1))]: "
    local choice
    read choice

    if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > i-1 )); then
      echo "  Canceled."
      return 0
    fi

    local selected_id="${selectable_ids[$choice]}"
    if [[ "$selected_id" == combo/* ]]; then
      profile_name="${selected_id#combo/}"
      export ANTHROPIC_HEADER_X_ROUTE_MODEL="$selected_id"
      extra_args=("--model" "claude-3-5-sonnet-20241022" "${extra_args[@]}")
    elif [[ "$selected_id" == *"/"* ]]; then
      profile_name=$(echo "$selected_id" | tr '/' '-' | tr '_' '-' | tr '.' '-')
    else
      profile_name="$selected_id"
    fi
  fi

  # ── Dynamic numbered profile (1-5): prompt for model selection ────────
  if [[ "$profile_name" =~ ^[0-9]+$ ]]; then
    local profile_dir="$HOME/.claude/profiles/$profile_name"
    if [[ ! -d "$profile_dir" ]]; then
      echo "➕ Profile $profile_name does not exist. Creating and bootstrapping..."
      mkdir -p "$profile_dir"
      setup-claude >/dev/null
    fi

    local selected_model
    selected_model=$(_agym_select_model "$model_table")
    if [[ -z "$selected_model" ]]; then
      echo "  Canceled."
      return 0
    fi
    if [[ "$selected_model" == combo/* ]]; then
      export ANTHROPIC_HEADER_X_ROUTE_MODEL="$selected_model"
      extra_args=("--model" "claude-3-5-sonnet-20241022" "${extra_args[@]}")
    else
      unset ANTHROPIC_HEADER_X_ROUTE_MODEL
      extra_args=("--model" "$selected_model" "${extra_args[@]}")
    fi
    echo "  🎯 Target model selected: $selected_model"
  fi

  # Build launch options for omniroute launch (before -- delimiter)
  local -a launch_opts=("--profile" "$profile_name")
  if [[ -n "$ANTHROPIC_HEADER_X_ROUTE_MODEL" ]]; then
    local omni_token=""
    if [[ -f "$HOME/.omniroute/.env" ]]; then
      omni_token=$(grep '^OMNIROUTE_API_KEY=' "$HOME/.omniroute/.env" | cut -d '=' -f2 | tr -d '"''')
    fi
    [[ -z "$omni_token" ]] && omni_token="omniroute-no-auth"
    launch_opts+=("--token" "${omni_token}__route__${ANTHROPIC_HEADER_X_ROUTE_MODEL}")
  fi

  echo "  🚀 Launching Claude Code → profile: $profile_name"
  omniroute launch "${launch_opts[@]}" -- --permission-mode auto "${extra_args[@]}"
}
