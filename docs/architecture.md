# claudem Architecture — Deep Dive

## Overview

`claudem` is built on the **Planner-Worker (Brain + Hands)** architecture, a pattern used at top-tier AI labs for autonomous multi-agent systems.

The core insight is simple: **use the most intelligent model to plan, and the fastest models to execute.** This maximises quality while minimising token cost and latency.

---

## Full Stack Diagram

```
You (Terminal)
    │
    ▼
claudem()  ←  zsh function in ~/.zshrc  (alias: cm)
    │
    │  Auto-starts OmniRoute if offline
    │  Shows interactive TUI or fuzzy-matches model name
    │  Isolates session via Claude Code profile
    ▼
OmniRoute Proxy  ←  localhost:20128  (npm: omniroute v3.8+)
    │   "Unified AI router — 160+ providers, RTK compression, auto fallback"
    │
    ├── Task-Aware Classifier  (~10ms local, no API call)
    │       Reads keyword signals in each prompt
    │       Routes to the right model automatically
    │
    ├── Zero-Downtime Fallback Chain
    │       429 / timeout → silently switches to next model in combo
    │       Agent never sees an error, context is preserved
    │
    └── MITM Interceptor  (for agy/ Google AI Pro models)
            Intercepts traffic at the TLS layer
            Routes to one of 11 AGY accounts via round-robin
    │
    ▼
Claude Code Profiles  ←  ~/.claude/profiles/<name>/
    │   Each profile = isolated API token + history + settings
    │   Numbered slots (1-5): __route__ token patching for combo selection
    ▼
CLAUDE.md  ←  ~/.claude/CLAUDE.md
    │   13 mandatory SDE rules — loaded FIRST, every session, 100% reliable
    ▼
MCP Servers
    ├── Swarm MCP (~/.omniroute/swarm_mcp.py)
    │       delegate_task() — spawn parallel sub-agents
    └── LLMLingua-2 (~/.llmlingua-mcp/server.py)
            compress_prompt() — 30-90% token compression
```

---

## Layer 1: The User Interface (Terminal)

You interact entirely through your Mac terminal. There is no web UI, no IDE extension. This is intentional — the terminal gives you raw control and forces the agent to be self-sufficient rather than relying on GUI scaffolding.

---

## Layer 2: claudem — The Launcher

The `claudem()` zsh function (aliased as `cm`) does several things:

1. **Auto-starts OmniRoute** if the server is offline (`nohup omniroute serve &`)
2. **Builds a live model table** by calling `_agym_build_table()`, which merges:
   - Hardcoded AGY model catalog (`_AGY_MODELS`) — injected because OmniRoute removed `agy/` from `/v1/models` (they are MITM-only now)
   - REST `/v1/models` for other configured providers
   - Coding combos (`_CODING_COMBOS`) and dynamic numbered profiles
3. **Presents a TUI picker** or **fuzzy-matches** a model name if you pass one as an argument
4. **Selects the right Claude Code profile** based on the model ID format:
   - `agy/<model>` → profile name derived from model ID
   - `combo/<name>` → combo profile with `ANTHROPIC_HEADER_X_ROUTE_MODEL` env var
   - `1`–`5` → isolated numbered slots (see Token Patching below)
5. **Launches Claude Code** via `omniroute launch --profile <name> -- --permission-mode auto`

### Env Var Reset
At the very start of every `claudem()` call:
```bash
unset ANTHROPIC_HEADER_X_ROUTE_MODEL
```
This prevents a stale value from a previous session leaking into the next one.

---

## Layer 3: CLAUDE.md — The Permanent Brain

`~/.claude/CLAUDE.md` is read **first, every single session**, before any user prompt. It is the guaranteed injection point for the 13 mandatory SDE rules.

**Why CLAUDE.md over customInstructions?**

`customInstructions` in `settings.json` has a known `sysprompt_missing_boundary_marker` bug — it silently fails to inject in ~8% of sessions. `CLAUDE.md` is the officially supported mechanism with 100% reliability.

---

## Layer 4: OmniRoute — The Task-Aware Router

OmniRoute sits between claudem and all AI provider APIs. Every prompt you type passes through OmniRoute's local classifier (runs in ~10ms, no API call) before being sent to the appropriate model.

### How AGY Models Work

AGY (Google AI Pro / Antigravity) models are **not exposed via `/v1/models`** — they are MITM-intercepted only. OmniRoute holds TLS certificates (`~/.9router/mitm/`) and intercepts traffic at the network layer. The `_AGY_MODELS` catalog in `.zshrc` is therefore hardcoded (not fetched from the API) so `claudem` and `agym` always know which models exist.

You have **11 AGY accounts** configured. OmniRoute round-robins across them, so availability of any given model is non-deterministic per request. The fallback chains in each combo absorb this variability transparently.

### Task-Aware Classification

OmniRoute reads keyword signals in your prompt:

| Signal Words | Routed To | Reason |
|-------------|-----------|--------|
| `design`, `architect`, `why`, `analyze`, `debug complex` | Claude Sonnet | Requires deep reasoning |
| `write`, `build`, `create`, `implement`, `add` | Gemini 3.1 Pro | Code generation |
| `fix`, `change`, `update`, `rename`, `format` | Gemini 3.5 Flash | Fast single-task edits |
| `sonnetd` prefix | Claude Sonnet (forced) | Brain+Worker Swarm mode |

### Zero-Downtime Fallback Chain

```
Primary model → 429 Rate Limit / timeout
    │
    ▼
OmniRoute catches error (never shown to agent)
    │
    ▼
Next model in combo's fallback list
    │
    ▼
Session continues seamlessly — zero context loss
```

---

## Layer 5: Token Patching for Numbered Profiles

When you pick a numbered profile slot (1–5) and select a `combo/*` model, claudem uses a `__route__` token suffix to communicate the combo choice to OmniRoute without needing a separate header:

```
base_token = sk-ant-xxxx...
new_token  = sk-ant-xxxx...__route__combo/debugger
```

The token is temporarily patched into `~/.claude/profiles/<N>/settings.json` before launch, then **restored to the original** after the Claude Code session exits. This gives numbered profiles full isolated API memory while still supporting smart combo routing.

---

## Layer 6: MCP Servers — The Tool Extensions

### Swarm MCP (`~/.omniroute/swarm_mcp.py`)

Provides the `delegate_task` tool. Allows the primary agent to spawn background sub-agents that run in parallel and return results when complete.

**The 3-Layer Swarm Rule:** Allows the Master Brain (Layer 1) to spawn Domain Architects (Layer 2) for massive tasks, or Gemini Workers (Layer 3) directly for standard tasks. Workers are **explicitly forbidden** from spawning further sub-agents. This prevents infinite delegation loops and "Agent Bombing".

**Activation:** Only via the `swarm` prefix (instant, no file reading) or `sonnetd` prefix (precise, reads files first). The MCP tool docstring enforces this contract.

### LLMLingua-2 MCP (`~/.llmlingua-mcp/server.py`)

Provides the `compress_prompt` tool. Uses the LLMLingua-2 neural compression model to reduce any large text input by 30–90% before sending to the AI. Preserves semantic meaning while dramatically reducing token usage.

- Code files: 0.3 compression ratio
- Logs / docs: 0.1 compression ratio
- Triggered by Rule 3 (DYNAMIC PRE-COMPRESSION) for any file >150 lines

---

## The `sonnetd` Trigger — Manual Brain+Worker Mode

When you prefix a prompt with `sonnetd`, you explicitly activate the Brain+Worker pipeline:

```
sonnetd [your massive multi-system task]
         │
         ▼
OmniRoute forces routing → Claude Sonnet 4.6 (Master Brain)
         │
         ▼
Sonnet reads files, identifies 3 distinct sub-systems
         │
         ├─── delegate_task(tier="architect") ──▶ Domain Architect 1
         ├─── delegate_task(tier="architect") ──▶ Domain Architect 2
         └─── delegate_task(tier="architect") ──▶ Domain Architect 3
                                        │
                              Architects read specific files in parallel
                              (~2 min vs ~25 min sequential)
                                        │
                             ├── delegate_task(tier="worker") ──▶ Gemini Coder
                             ├── delegate_task(tier="worker") ──▶ Gemini Coder
                             └── delegate_task(tier="worker") ──▶ Gemini Coder
                                        │
                                        ▼
                              Results return to Sonnet
                                        │
                                        ▼
                              Sonnet integrates + reviews
```

The `swarm` prefix is the faster variant — Sonnet dispatches immediately without reading files, letting sub-agents discover their own context.

**When to use `sonnetd`:**
- Building a new feature from scratch that spans 3+ files
- Refactoring an entire module
- Any task you estimate would take >30 minutes sequentially

**When NOT to use `sonnetd`:**
- Simple bug fixes (1-2 files)
- Quick config changes
- Single-function implementations

---

## Token Economics

Without claudem optimizations, a typical large project session might use 200,000 tokens. With all optimizations active:

| Optimization | Tokens Saved |
|-------------|-------------|
| LLMLingua-2 compression (70% on code) | ~60,000 |
| Skeleton mapping (grep before reading) | ~20,000 |
| Context Amnesia (reset at 50k tokens) | ~40,000 |
| Routing simple tasks to Flash | ~15,000 |
| Removing Opus from default combos | ~30,000 |
| **Total saved** | **~165,000 (~82%)** |

---

## Safety Architecture

Three layers of safety prevent the agent from doing irreversible damage:

1. **Micro-Commits (Rule 6):** `git commit` after every task → instant rollback available
2. **Bash Safety (Rule 11):** Blocks `rm -rf`, `find /` at the CLAUDE.md level — agent must ask first
3. **Auto-mode:** `--permission-mode auto` — Claude Code still prompts for high-risk operations

---

## Key Differences vs Vanilla Claude Code

| Feature | Vanilla `claude` | `claudem` |
|---------|-----------------|-----------|
| Model routing | Single model | Task-aware, 10+ models |
| Rate limit handling | Error shown to agent | Silent fallback to next model |
| Profile isolation | Shared history | Per-session isolated profiles |
| Token compression | None | LLMLingua-2 (30-90% savings) |
| Multi-agent | None | Swarm MCP (parallel sub-agents) |
| SDE guardrails | None | 13 mandatory rules via CLAUDE.md |
| AGY model access | N/A | 11 accounts, round-robin |

---

*For combo reference, see [combos.md](combos.md). For troubleshooting, see [troubleshooting.md](troubleshooting.md).*
