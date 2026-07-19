# claudem Architecture — Deep Dive

## Overview

`claudem` is built on the **Planner-Worker (Brain + Hands)** architecture, a pattern used at top-tier AI labs for autonomous multi-agent systems.

The core insight is simple: **use the most intelligent model to plan, and the fastest models to execute.** This maximizes quality while minimizing token cost and latency.

---

## Layer 1: The User Interface (Terminal)

You interact entirely through your Mac terminal. There is no web UI, no IDE extension. This is intentional — the terminal gives you raw control and forces the agent to be self-sufficient rather than relying on GUI scaffolding.

---

## Layer 2: claudem Alias

The `claudem` alias sets the `HOME` environment variable before launching Claude Code. This allows a completely isolated Claude Code profile that doesn't interfere with any other Claude Code setup you might have.

```bash
alias claudem='HOME=/Users/chandan claude'
```

**Why this matters:** All config (settings.json, CLAUDE.md, history, sessions, MCP servers) is loaded from the specified HOME directory, giving you a clean, dedicated environment.

---

## Layer 3: CLAUDE.md — The Permanent Brain

`~/.claude/CLAUDE.md` is read **first, every single session**, before any user prompt. It is the guaranteed injection point for the 11 mandatory SDE rules.

**Why CLAUDE.md over customInstructions?**

`customInstructions` in `settings.json` has a known `sysprompt_missing_boundary_marker` bug — it silently fails to inject in ~8% of sessions. `CLAUDE.md` is the officially supported mechanism with 100% reliability.

---

## Layer 4: OmniRoute — The Task-Aware Router

OmniRoute sits between claudem and all AI provider APIs. Every prompt you type passes through OmniRoute's local classifier (runs in ~10ms, no API call) before being sent to the appropriate model.

### Task-Aware Classification

OmniRoute reads keyword signals in your prompt:

| Signal Words | Routed To | Reason |
|-------------|-----------|--------|
| "design", "architect", "why", "analyze", "debug complex" | Claude Sonnet | Requires deep reasoning |
| "write", "build", "create", "implement", "add" | Gemini 3.1 Pro | Code generation |
| "fix", "change", "update", "rename", "format" | Gemini 3.5 Flash | Fast single-task edits |

### Zero-Downtime Fallback Chain

```
Primary model 429 Rate Limit
    │
    ▼
OmniRoute catches error (never shown to agent)
    │
    ▼
Next model in combo's fallback list
    │
    ▼
Session continues seamlessly
```

The sub-agent receives the full conversation history from OmniRoute when it takes over, ensuring zero context loss during model switches.

---

## Layer 5: MCP Servers — The Tool Extensions

Two MCP (Model Context Protocol) servers extend claudem's capabilities:

### Swarm MCP (`swarm_mcp.py`)
Provides `delegate_task` tool. Allows the primary agent to spawn background sub-agents that run in parallel and return results when complete.

**The 3-Layer Swarm Rule:** Allows the primary agent (Layer 1) to spawn Domain Architects (Layer 2) for massive tasks, or Gemini Workers (Layer 3) directly for standard tasks. Workers are explicitly forbidden from spawning further sub-agents. This prevents infinite delegation loops and "Agent Bombing".

### LLMLingua-2 MCP
Provides `compress_prompt` tool. Uses the LLMLingua-2 neural compression model to reduce any large text input by 30-90% before sending to the AI. Preserves semantic meaning while dramatically reducing token usage.

---

## The `sonnetd` Trigger — Manual Brain+Worker Mode

When you prefix a prompt with `sonnetd`, you explicitly activate the Brain+Worker pipeline:

```
sonnetd [your massive multi-system task]
         │
         ▼
OmniRoute forces routing → Layer 1: Master Brain (Claude Sonnet 4.6)
         │
         ▼
Sonnet parses prompt → identifies 3 distinct systems (no file reading)
         │
         ├─── delegate_task(tier="architect") ──▶ Layer 2: Firestick Architect
         ├─── delegate_task(tier="architect") ──▶ Layer 2: Leadflow Architect
         └─── delegate_task(tier="architect") ──▶ Layer 2: Router Architect
                                        │
                                        ▼
                 Architects simultaneously read specific files
                 and build flawless execution plans in parallel
                                        │
                                        ▼
             ├── delegate_task(tier="worker") ──▶ Layer 3: Gemini Coder
             ├── delegate_task(tier="worker") ──▶ Layer 3: Gemini Coder
             └── delegate_task(tier="worker") ──▶ Layer 3: Gemini Coder
                                        │
                                        ▼
                              Results return to Master
                                        │
                                        ▼
                              Sonnet integrates + reviews
```

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

| Optimization | Savings |
|-------------|---------|
| LLMLingua-2 compression (70% on code) | ~60,000 tokens |
| Skeleton mapping (grep before reading) | ~20,000 tokens |
| Context Amnesia (reset at milestones) | ~40,000 tokens |
| Removing Opus from combos | ~30,000 tokens |
| Routing simple tasks to Flash | ~15,000 tokens |
| **Total saved** | **~165,000 tokens (~82%)** |

---

## Safety Architecture

Three layers of safety prevent the agent from doing irreversible damage:

1. **Micro-Commits:** `git commit` after every task → instant rollback available
2. **Bash Safety Rule:** Blocks `rm -rf`, `find /` at the CLAUDE.md level
3. **Auto-mode:** Human approval required for high-risk operations

---

*For combo reference, see [combos.md](combos.md). For troubleshooting, see [troubleshooting.md](troubleshooting.md).*
