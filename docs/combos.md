# OmniRoute Combo Reference

All combos use `task-aware` routing strategy and have automatic zero-downtime fallback.

## Active Combos

### `gemini-coder`
**Best for:** Standard feature development, day-to-day coding  
**Model Stack:** Gemini 3.1 Pro High → Gemini 3.5 Flash High → Claude Sonnet 4.6  
**Strategy:** task-aware  
**Notes:** Default recommendation for most sessions. Sonnet only activates for reasoning-heavy prompts.

---

### `architect`
**Best for:** System design, database schema, API design, architectural decisions  
**Model Stack:** Gemini 3.1 Pro High → Claude Sonnet 4.6 → Gemini 3.1 Pro Low  
**Strategy:** task-aware

---

### `debugger`
**Best for:** Complex bug investigations, reading stack traces, root cause analysis  
**Model Stack:** Claude Sonnet 4.6 → Gemini 3.1 Pro High → Gemini 3.1 Pro Agent → Gemini 3.1 Pro Low  
**Strategy:** task-aware  
**Notes:** Sonnet is the primary model here since debugging requires deep reasoning.

---

### `bigbrain`
**Best for:** Maximum reasoning tasks, complex refactors, multi-system analysis  
**Model Stack:** Gemini 3.1 Pro High → Claude Sonnet 4.6 → Gemini 3.5 Flash High → Gemini Pro Agent → Gemini Pro Low  
**Strategy:** task-aware

---

### `code-sprint`
**Best for:** Fast boilerplate, repeated patterns, bulk code generation  
**Model Stack:** Gemini 3.5 Flash Medium → Gemini 3.5 Flash Low → Gemini Flash Lite → Claude Sonnet 4.6  
**Strategy:** task-aware  
**Notes:** Sonnet only activates as final fallback. Extremely token-efficient.

---

### `turbo`
**Best for:** Single-file edits, quick fixes, renaming, formatting  
**Model Stack:** Gemini 3.5 Flash Medium → Gemini 3.5 Flash Low → Gemini Flash Lite → Claude Sonnet 4.6  
**Strategy:** task-aware

---

### `master-reasoner`
**Best for:** Deep philosophical or strategic reasoning about architecture  
**Model Stack:** Claude Sonnet 4.6 → Gemini 3.1 Pro High  
**Strategy:** task-aware  
**Notes:** Opus was removed from this combo. Sonnet is the primary reasoning engine.

---

### `pure-thinking`
**Best for:** Extended thinking / stream-of-consciousness architectural exploration  
**Model Stack:** Claude Sonnet 4.6 → Gemini 3.1 Pro High  
**Notes:** Opus was removed. Sonnet with thinking mode enabled.

---

### `web-builder`
**Best for:** Frontend, CSS, React, HTML, UI components  
**Strategy:** task-aware

---

### `agentic-coder`
**Best for:** Fully autonomous multi-step coding tasks with minimal supervision  
**Strategy:** task-aware

---

## Combo Selection Guide

```
Simple fix (1-2 files)    → turbo or code-sprint
Feature development       → gemini-coder
System design             → architect
Debugging errors          → debugger
Complex reasoning         → bigbrain or master-reasoner
Frontend / UI             → web-builder
Fully autonomous sprint   → agentic-coder + sonnetd prefix
```

## `sonnetd` Keyword Override

All combos have a `keyword_override` for `sonnetd`. When detected, OmniRoute bypasses task-aware classification and forces Claude Sonnet 4.6 as the primary model, activating Brain+Worker Swarm mode.

## Removed Models

**Claude Opus 4.6 (Thinking)** has been removed from all combos. It remains available for direct manual selection from the claudem menu. It was removed from combos to prevent unintentional token drain (Opus shares rate limits with Sonnet on the `agy` provider).
