# OmniRoute Combo Reference

All combos use `task-aware` routing strategy and have automatic zero-downtime fallback.
Select via `claudem` interactive picker or `claudem <combo-name>`.

> **Note:** Claude Opus 4.6 (Thinking) is available for direct selection from the `claudem`
> menu but has been removed from all combos to prevent unintentional token drain
> (Opus shares rate limits with Sonnet on the `agy` provider).

---

## Active Combos

### `code-sprint` — ⚡ Default for most tasks
**Best for:** Standard feature development, boilerplate, day-to-day coding
**Model Stack:** Gemini 3.5 Flash Medium → Gemini 3.5 Flash Low → Gemini Flash Lite → Claude Sonnet 4.6
**Strategy:** task-aware (round-robin Flash variants)
**Notes:** Most token-efficient option. Sonnet only activates as final fallback.

---

### `architect` — 🏗️ System design
**Best for:** Database schema, API design, architectural decisions, refactors
**Model Stack:** Gemini 3.1 Pro High → Claude Sonnet 4.6 → Gemini 3.1 Pro Low
**Strategy:** task-aware (priority Pro)

---

### `debugger` — 🐛 Bug hunting
**Best for:** Complex bug investigations, reading stack traces, root cause analysis
**Model Stack:** Claude Sonnet 4.6 → Gemini 3.1 Pro High → Gemini 3.1 Pro Agent → Gemini 3.1 Pro Low
**Strategy:** task-aware
**Notes:** Sonnet is the **primary** model here — debugging requires deep reasoning.
This is the only combo where Claude leads rather than acting as a fallback.

---

### `bigbrain` — 📄 Huge codebases
**Best for:** Context-heavy tasks, reading large files, multi-system analysis
**Model Stack:** Gemini 3.1 Pro High → Claude Sonnet 4.6 → Gemini 3.5 Flash High → Gemini Pro Agent → Gemini Pro Low
**Strategy:** task-aware (context-optimized)
**Notes:** Uses 1048K context window. Best when working across many large files.

---

### `turbo` — 🚀 Single-file speed
**Best for:** Quick fixes, renaming, formatting, single-file edits
**Model Stack:** Gemini 3.5 Flash Medium → Gemini 3.5 Flash Low → Gemini Flash Lite → Claude Sonnet 4.6
**Strategy:** task-aware (least-used Flash for max speed)

---

### `test-forge` — 🧪 Test writing
**Best for:** Unit tests, integration tests, test coverage, TDD
**Model Stack:** Claude Sonnet 4.6 → Gemini 3.1 Pro High
**Strategy:** task-aware (Sonnet priority for test accuracy)

---

### `agentic-coder` — 🤖 Long autonomous runs
**Best for:** Fully autonomous multi-step coding tasks with minimal supervision
**Strategy:** task-aware (reset-aware for sessions that hit the 50k token milestone)
**Notes:** Designed for `sonnetd`/`swarm` prefix tasks that run for extended periods.

---

### `web-builder` — 🌐 Frontend & UI
**Best for:** Frontend, CSS, React, HTML, UI components, visual work
**Strategy:** task-aware
**Notes:** Includes vision-capable models for screenshot-based visual QA (Rule 8).

---

### `master-reasoner` — 🧠 Deep reasoning
**Best for:** Complex philosophical or strategic reasoning about architecture
**Model Stack:** Claude Sonnet 4.6 → Gemini 3.1 Pro High
**Strategy:** task-aware
**Notes:** Sonnet is the primary reasoning engine. Use with `sonnetd` prefix for max power.

---

### `pure-thinking` — 🧠 Extended thinking
**Best for:** Extended thinking / stream-of-consciousness architectural exploration
**Model Stack:** Claude Sonnet 4.6 → Gemini 3.1 Pro High
**Notes:** Sonnet with thinking mode enabled. Use for problems that need prolonged internal reasoning.

---

### `gemini-coder` — 🤖 Gemini-only coding
**Best for:** Tasks where you want Gemini exclusively (no Claude fallback)
**Model Stack:** Gemini 3.1 Pro High → Gemini 3.5 Flash High → Gemini 3.1 Pro Low
**Strategy:** task-aware (dedicated Gemini stack)

---

## Dynamic Profile Slots (1–5)

Numbered profiles are **blank canvas** slots with isolated API token + history. When you pick one:

1. You're shown the full model picker to choose any model or combo
2. If a combo is selected, the token is temporarily patched with `__route__` so OmniRoute knows which combo to use
3. After the session ends, the token is restored to its original value

Use these for experiments, client projects, or anything you want to keep separate from your main sessions.

---

## Combo Selection Guide

```
Quick edit (1-2 files)        →  turbo
Standard feature dev          →  code-sprint
System design / schema        →  architect
Debugging errors              →  debugger
Huge codebase context         →  bigbrain
Writing tests                 →  test-forge
Frontend / CSS / React        →  web-builder
Complex reasoning             →  master-reasoner
Extended thinking             →  pure-thinking
Fully autonomous sprint       →  agentic-coder + sonnetd prefix
Want Gemini only              →  gemini-coder
```

---

## `sonnetd` and `swarm` Keyword Overrides

All combos respond to the `sonnetd` and `swarm` prompt prefixes:

| Prefix | Behaviour |
|--------|-----------|
| `sonnetd` | Forces Claude Sonnet 4.6 as primary. Agent reads files first, then delegates in parallel. |
| `swarm` | Forces Claude Sonnet 4.6 as primary. Agent dispatches immediately without reading files (faster). |

Both prefixes activate the 3-Layer delegation: Master Brain → Domain Architects → Gemini Workers.

---

## Removed Models

**Claude Opus 4.6 (Thinking)** has been removed from all combos. It remains available for:
- Direct manual selection from the `claudem` menu
- Selection via `claudem claude-opus` or `claudem opus`

It was removed from combos because Opus shares rate limits with Sonnet on the `agy` provider — unintentional Opus usage drains the quota that Sonnet needs for reasoning-heavy tasks.

---

## Live Model Status

Run the health check to see which models are currently responding:

```bash
bash scripts/health_check.sh
```

AGY model availability is non-deterministic (11 accounts, round-robin). If a model times out, OmniRoute's fallback chain silently routes to the next model in the combo.
