# ── OmniRoute Configuration ────────────────────────────────────────────────────
export DATA_DIR="$HOME/.omniroute"
export GEMINI_BASE_URL="http://localhost:20128/v1"
export OMNIROUTE_URL="http://localhost:20128"

# ── agy/ model catalog ─────────────────────────────────────────────────────────
if [ -n "$ZSH_VERSION" ]; then typeset -g -a _AGY_MODELS; else declare -a _AGY_MODELS; fi
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
if [ -n "$ZSH_VERSION" ]; then typeset -g -a _CODING_COMBOS; else declare -a _CODING_COMBOS; fi
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
  "combo/sonnet-boss|👑 Sonnet Boss    · Sonnet-first priority with Gemini failover|200K|v,t"
  "combo/gemini-coder|🤖 Gemini Coder    · dedicated Gemini models for coding|1048K|t"
)

# ── Provider display names ─────────────────────────────────────────────────────
if [ -n "$ZSH_VERSION" ]; then typeset -g -A _OMNIROUTE_PROVIDER_LABELS; else declare -A _OMNIROUTE_PROVIDER_LABELS; fi
_OMNIROUTE_PROVIDER_LABELS[agy]="agy  ·  Google AI Pro (Gemini + Claude via MITM)"
_OMNIROUTE_PROVIDER_LABELS[coding-combos]="⚙️  Coding Combos  · Your smart routing presets"
_OMNIROUTE_PROVIDER_LABELS[combo]="auto  ·  Smart Router (picks best available model)"
_OMNIROUTE_PROVIDER_LABELS[opencode]="opencode  ·  OpenCode Free Models"
_OMNIROUTE_PROVIDER_LABELS[theoldllm]="theoldllm  ·  The Old LLM (GPT-5, Claude, Gemini free)"
_OMNIROUTE_PROVIDER_LABELS[duckduckgo-web]="ddgw  ·  DuckDuckGo AI Chat (free, no key)"
_OMNIROUTE_PROVIDER_LABELS[mimocode]="mimocode  ·  MiMo Code"
_OMNIROUTE_PROVIDER_LABELS[chipotle]="chipotle  ·  Chipotle AI (Pepper)"

# ── agym-status ────────────────────────────────────────────────────────────────
agym-status() {
  local url="${OMNIROUTE_URL:-http://localhost:20128}"
  if ! curl -s --connect-timeout 2 "$url/v1/models" >/dev/null 2>&1; then
    echo "❌ OmniRoute is NOT running at $url"
    echo "   Start with: omniroute serve"
    return 1
  fi
  local rest_count
  rest_count=$(curl -s "$url/v1/models" | python3 -c "import json,sys; d=json.load(sys.stdin); groups={}; [groups.update({m.get(\"owned_by\",\"?\"): groups.get(m.get(\"owned_by\",\"?\"),0)+1}) for m in d.get(\"data\",[]) if m.get(\"type\")!=\"video\"]; print(\"\\n\".join([f\"   [{k}]  {v} models\" for k,v in sorted(groups.items())]))" 2>/dev/null)
  echo "✅ OmniRoute LIVE at $url"
  echo ""
  echo "   Provider groups in /v1/models:"
  echo "$rest_count"
  echo ""
  echo "   Run \`agym\` to pick · \`agym --list\` for full table"
}

# ── _agym_build_table ──────────────────────────────────────────────────────────
if [ -n "$ZSH_VERSION" ]; then typeset -g -A _PROVIDER_TO_OWNED_BY; else declare -A _PROVIDER_TO_OWNED_BY; fi
_PROVIDER_TO_OWNED_BY[openai]='openai'
_PROVIDER_TO_OWNED_BY[anthropic]='anthropic'
_PROVIDER_TO_OWNED_BY[groq]='groq'
_PROVIDER_TO_OWNED_BY[mistral]='mistral'
_PROVIDER_TO_OWNED_BY[openrouter]='openrouter'

_agym_build_table() {
  local url="${OMNIROUTE_URL:-http://localhost:20128}"

  local rest_owned_by=()
  local configured_providers
  configured_providers=$(omniroute providers list 2>/dev/null     | sed 's/\[[0-9;]*m//g'     | grep -E '^[a-f0-9]+'     | awk '{print $2}')

  if [[ -n "$configured_providers" ]]; then
    while IFS= read -r pid; do
      [[ -z "$pid" ]] && continue
      [[ -n "${_PROVIDER_TO_OWNED_BY[$pid]}" ]] && rest_owned_by+=("${_PROVIDER_TO_OWNED_BY[$pid]}")
    done <<< "$configured_providers"
  fi

  local raw_json
  raw_json=$(curl -s --connect-timeout 4 "$url/v1/models" 2>/dev/null)
  if [[ -z "$raw_json" ]]; then
    raw_json='{"data":[]}'
  fi

  local agy_lines_str
  agy_lines_str=$(printf '%s\n' "${_AGY_MODELS[@]}")
  local rest_owned_by_str
  rest_owned_by_str=$(printf '%s,' "${rest_owned_by[@]}")

  python3 -c '
import json, sys
from collections import defaultdict

try:
    data = json.loads(sys.argv[1])
except Exception:
    data = {"data": []}

agy_lines = [l.strip() for l in (sys.argv[2].splitlines() if len(sys.argv) > 2 and sys.argv[2] else [])]
rest_allow = set(sys.argv[4].split(",")) if len(sys.argv) > 4 and sys.argv[4] else set()

seen = set()
rows = []

# 1. Always inject agy/ models
for line in agy_lines:
    if line and line.strip():
        parts = line.split("|")
        if len(parts) < 4: continue
        mid = parts[0]
        if mid in seen: continue
        seen.add(mid)
        rows.append(line + "|agy")

groups = defaultdict(list)
if isinstance(data, dict):
    for m in data.get("data", []):
        if not isinstance(m, dict): continue
        mid = m.get("id", "")
        ob  = m.get("owned_by", "")
        if not mid or mid in seen: continue
        if m.get("type") == "video": continue
        if ob == "openrouter": continue
        if rest_allow and ob not in rest_allow: continue
        seen.add(mid)
        name = m.get("name") or mid
        ctx  = m.get("context_length") or "?"
        caps = m.get("capabilities", {})
        tags = []
        if caps.get("vision"):   tags.append("v")
        if caps.get("thinking"): tags.append("t")
        if ctx != "?":
            try:
                ctx = str(int(ctx)//1000) + "K"
            except Exception:
                pass
        groups[ob].append(mid + "|" + name + "|" + str(ctx) + "|" + ",".join(tags) + "|" + ob)

for ob in sorted(groups.keys()):
    rows.extend(groups[ob])

print("\n".join(rows))
' "$raw_json" "$agy_lines_str" "1" "$rest_owned_by_str" 2>/dev/null

  # Inject dynamic numeric profiles at the top of combos
  local d
  for d in "$HOME"/.claude/profiles/[0-9]*(N); do
    [[ -d "$d" ]] || continue
    local name="${d##*/}"
    echo "combo/$name|⚡ Profile $name   · dedicated history with dynamic model selection|1048K|t|coding-combos"
  done

  # Inject coding combos as a separate section at the bottom
  for combo_line in "${_CODING_COMBOS[@]}"; do
    combo_line="${combo_line//\"/}"
    combo_line="${combo_line//\'/}"
    echo "${combo_line}|coding-combos"
  done
}

# ── agym ───────────────────────────────────────────────────────────────────────
agym() {
  local url="${OMNIROUTE_URL:-http://localhost:20128}"
  local extra_args=()
  local jump_model=""
  local list_only=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --list|-l) list_only=true; shift ;;
      --model|-m) jump_model="$2"; shift 2 ;;
      *) extra_args+=("$1"); shift ;;
    esac
  done

  local model_table
  model_table=$(_agym_build_table)
  if [[ -z "$model_table" ]]; then
    echo "❌ OmniRoute is NOT running or no models available at $url"
    echo "   Start with: omniroute serve"
    return 1
  fi

  if [[ "$list_only" == true ]]; then
    echo ""
    echo "  ╔══════════════════════════════════════════════════════╗"
    echo "  ║     OmniRoute Available Models                      ║"
    echo "  ╚══════════════════════════════════════════════════════╝"
    echo ""
    local last_ob=""
    while IFS='|' read -r mid mname mctx mcaps mob; do
      if [[ "$mob" != "$last_ob" ]]; then
        local label="${_OMNIROUTE_PROVIDER_LABELS[$mob]:-$mob}"
        echo ""
        echo "  ── $label ────────────────────────────────────────"
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

  if [[ -n "$jump_model" ]]; then
    local matched
    matched=$(echo "$model_table" | awk -F'|' -v q="$jump_model"       'tolower($1) ~ tolower(q) || tolower($2) ~ tolower(q) {print $1; exit}')
    if [[ -z "$matched" ]]; then
      echo "⚠️  No model matched '$jump_model'."
      echo "   Run: agym --list"
      return 1
    fi
    echo "🚀 Launching agy → $matched"
    GEMINI_BASE_URL="$url/v1" agy --model "$matched" --dangerously-skip-permissions "${extra_args[@]}"
    return
  fi

  echo ""
  echo "  ========================================================"
  echo "       OmniRoute Model Selector  [agym]"
  echo "  ========================================================"
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
    local formatted
    formatted=$(printf '%-38s  %-6s  %s' "$mname" "$mctx" "$capstr")
    all_labels+=("$formatted")
  done <<< "$model_table"

  echo "  Select a model (Ctrl-C to cancel):"
  echo ""
  local i=1
  local -a selectable_ids=()
  local idx=1
  for id in "${all_ids[@]}"; do
    local label="${all_labels[$idx]}"
    if [[ "$id" == "---" ]]; then
      printf "\n  %s\n" "$label"
    else
        printf "    %3d.  %s\n" "$i" "$label"
      (( i++ ))
    fi
    (( idx++ ))
  done

  echo ""
  local max_choice=$(( i - 1 ))
  printf "  Enter number [1-%d]: " "$max_choice"
  local choice
  read choice

  if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > max_choice )); then
    echo "  Canceled."
    return 0
  fi

  local selected_id="${selectable_ids[$choice]}"
  echo "  🚀 Launching agy → $selected_id"
  GEMINI_BASE_URL="$url/v1" agy --model "$selected_id" --dangerously-skip-permissions "${extra_args[@]}"
}

_agym_select_model() {
  local model_table="$1"
  local -a all_ids=() all_labels=()
  local last_ob=""
  local mid mname mctx mcaps mob capstr label formatted

  while IFS='|' read -r mid mname mctx mcaps mob; do

    if [[ "$mob" != "$last_ob" ]]; then
      label="${_OMNIROUTE_PROVIDER_LABELS[$mob]:-$mob}"
      all_ids+=("---")
      all_labels+=("── $label")
      last_ob="$mob"
    fi
    all_ids+=("$mid")
    capstr=""
    [[ "$mcaps" == *"v"* ]] && capstr+="[v] "
    [[ "$mcaps" == *"t"* ]] && capstr+="[t]"
    formatted=$(printf '%-38s  %-6s  %s' "$mname" "$mctx" "$capstr")
    all_labels+=("$formatted")
  done <<< "$model_table"

  echo "  Select a target model/combo for this session (Ctrl-C to cancel):" >&2
  echo "" >&2
  local i=1
  local -a selectable_ids=()
  local idx=1
  for id in "${all_ids[@]}"; do
    label="${all_labels[$idx]}"
    if [[ "$id" == "---" ]]; then
      printf "
  %s
" "$label" >&2
    else
      printf "    %3d.  %s
" "$i" "$label" >&2
      selectable_ids+=("$id")
      (( i++ ))
    fi
    (( idx++ ))
  done

  echo "" >&2
  local max_choice=$(( i - 1 ))
  printf "  Enter number [1-%d]: " "$max_choice" >&2
  local choice
  read choice < /dev/tty

  if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > max_choice )); then
    return 1
  fi

  echo "${selectable_ids[$choice]}"
}

unalias claudem 2>/dev/null || true
unfunction claudem 2>/dev/null || true
claudem() {
  unset ANTHROPIC_HEADER_X_ROUTE_MODEL
  local url="${OMNIROUTE_URL:-http://localhost:20128}"
  local model_table
  model_table=$(_agym_build_table)
  if [[ -z "$model_table" ]]; then
    echo "🔄 OmniRoute is offline. Auto-starting background server..."
    omniroute serve --daemon >/dev/null 2>&1 || nohup omniroute serve > "$HOME/.omniroute/server.log" 2>&1 &
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

  if [[ "$1" == "command" ]]; then
    mode="command"
    shift
  fi

  if [[ $# -gt 0 ]]; then
    local search_term="$1"
    shift

    if [[ "$search_term" =~ ^[1-5]$ ]]; then
      profile_name="$search_term"
    else
      local matched
      matched=$(echo "$model_table" | awk -F'|' -v q="$search_term"         'tolower($1) ~ tolower(q) || tolower($2) ~ tolower(q) {print $1; exit}')

      if [[ -n "$matched" ]]; then
        if [[ "$matched" == combo/* ]]; then
          profile_name="${matched#combo/}"
          export ANTHROPIC_HEADER_X_ROUTE_MODEL="$matched"
          extra_args=("--model" "agy/claude-sonnet-4-6" "${extra_args[@]}")
        elif [[ "$matched" == *"/"* ]]; then
          profile_name=$(echo "$matched" | tr '/' '-' | tr '_' '-' | tr '.' '-')
        else
          profile_name="$matched"
        fi
      else
        if [[ -d "$HOME/.claude/profiles/$search_term" ]]; then
          profile_name="$search_term"
        else
          echo "⚠️  No model/profile matched '$search_term'."
          echo "   Available profiles:"
          ls -1 "$HOME/.claude/profiles/" | grep -v '^\.' | sed 's/^/     • /'
          return 1
        fi
      fi
    fi
    extra_args+=("$@")
  else
    echo ""
    echo "  ========================================================"
    echo "       OmniRoute Claude Code Selector  [claudem]"
    echo "  ========================================================"
    echo ""

    echo "  Select a Claude Code profile (Ctrl-C to cancel):"
    echo ""
    local i=1
    local -a selectable_ids=()
    local last_ob=""
    local mid mname mctx mcaps mob capstr label

    while IFS='|' read -r mid mname mctx mcaps mob; do
      [[ -z "$mid" ]] && continue
      if [[ "$mob" != "$last_ob" ]]; then
        label="${_OMNIROUTE_PROVIDER_LABELS[$mob]:-$mob}"
        printf "\n  ── %s ────────────────────────────────────────\n" "$label"
        last_ob="$mob"
      fi
      capstr=""
      [[ "$mcaps" == *"v"* ]] && capstr+="[v] "
      [[ "$mcaps" == *"t"* ]] && capstr+="[t]"
      printf "    %3d.  %-38s  %-6s  %s\n" "$i" "$mname" "$mctx" "$capstr"
      selectable_ids[$i]="$mid"
      (( i++ ))
    done <<< "$model_table"

    echo ""
    local max_choice=$(( i - 1 ))
    printf "  Enter number [1-%d]: " "$max_choice"
    local choice
    read choice

    if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > max_choice )); then
      echo "  Canceled."
      return 0
    fi

    local selected_id="${selectable_ids[$choice]}"
    if [[ "$selected_id" == combo/* ]]; then
      profile_name="${selected_id#combo/}"
      export ANTHROPIC_HEADER_X_ROUTE_MODEL="$selected_id"
      extra_args=("--model" "agy/claude-sonnet-4-6" "${extra_args[@]}")
    elif [[ "$selected_id" == *"/"* ]]; then
      profile_name=$(echo "$selected_id" | tr '/' '-' | tr '_' '-' | tr '.' '-')
    else
      profile_name="$selected_id"
    fi
  fi

  if [[ "$profile_name" =~ ^[0-9]+$ ]]; then
    local profile_dir="$HOME/.claude/profiles/$profile_name"
    if [[ ! -d "$profile_dir" ]]; then
      echo "➕ Profile $profile_name does not exist. Syncing active profiles..."
      mkdir -p "$profile_dir"
      node "$HOME/.omniroute/setup-claude-clean.js" >/dev/null 2>&1
    fi
  fi

  local -a launch_opts=("--profile" "$profile_name")
  if [[ -n "$ANTHROPIC_HEADER_X_ROUTE_MODEL" ]]; then
    local omni_token=""
    if [[ -f "$HOME/.omniroute/.env" ]]; then
      omni_token=$(grep -E '^OMNIROUTE_API_KEY=' "$HOME/.omniroute/.env" | cut -d'=' -f2- | tr -d '\"')
    fi
    [[ -z "$omni_token" ]] && omni_token="omniroute-no-auth"
    launch_opts+=("--token" "${omni_token}__route__${ANTHROPIC_HEADER_X_ROUTE_MODEL}")
  fi

  if ! curl -s --connect-timeout 2 "${url}/v1/models" >/dev/null 2>&1; then
    echo "🔄 Starting OmniRoute server daemon..."
    omniroute serve --daemon >/dev/null 2>&1 || true
    sleep 2
  fi

  echo "  🚀 Launching Claude Code → profile: $profile_name"
  omniroute launch "${launch_opts[@]}" -- --permission-mode auto "${extra_args[@]}"
}
