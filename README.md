# claudem ⚡

> A fully autonomous, Principal-Engineer-grade AI coding assistant — built on Claude Code CLI, supercharged with OmniRoute multi-model orchestration, LLMLingua-2 compression, Swarm multi-agent delegation, and world-class SDE guardrails.

---

## What is claudem?

`claudem` is a supercharged alias of **Claude Code CLI** (`claude`) configured to behave like a **Principal Software Engineer**, not just a code autocomplete tool. It runs entirely in your terminal and operates autonomously across projects.

It combines four layers of intelligence:

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **AI Brain** | Claude Sonnet 4.6 (Thinking) | Reasoning, planning, architecture |
| **AI Workers** | Gemini 3.1 Pro / 3.5 Flash | Fast code generation, boilerplate |
| **Token Optimizer** | LLMLingua-2 MCP | Compress context before reading large files |
| **Multi-Agent Swarm** | Swarm MCP | Spawn parallel sub-agents for complex tasks |

---

## Architecture

```
You (Terminal)
    │
    ▼
claudem alias  ─────────────────────────────────────────────────────────────
    │                                                                        │
    ▼                                                                        ▼
~/.claude/CLAUDE.md          ~/.claude/settings.json
(13 mandatory SDE rules)     (MCP servers, model config, timeouts)
    │
    ▼
OmniRoute Proxy  (Zero-downtime task-aware routing)
         │
         ▼
    Swarm MCP  (3-Layer Hierarchical Delegation)
         │
         ├── Layer 1: Master Brain (Claude Sonnet 4.6)
         │    └─ Parses prompt, issues parallel architectural assignments.
         │
         ├── Layer 2: Domain Architects (Parallel Sub-Sonnets)
         │    └─ Dynamically spawned for massive, multi-system tasks. 
         │    └─ Reads specific codebase in parallel (2 mins vs 25 mins).
         │
         └── Layer 3: Gemini Workers (Coders)
              └─ Receives flawless execution plans, writes code at lightning speed.
```

---

## The 13 Mandatory SDE Rules (CLAUDE.md)

Every session, `claudem` loads these rules from `~/.claude/CLAUDE.md`:

1. **SWARM ORCHESTRATION** — Delegates disconnected tasks to parallel agents
2. **SKELETON MAPPING** — Grep file structure before reading entire files
3. **DYNAMIC PRE-COMPRESSION** — LLMLingua-2 compresses files >150 lines (0.3 ratio for code, 0.1 for logs)
4. **CONTEXT AMNESIA** — Auto git commit + state.md reset after 50k tokens
5. **SELF-HEALING LOOP** — Forbidden from saying "done" without running the code first
6. **ATOMIC MICRO-COMMITS** — `git commit` after every single individual task
7. **STATE LOG** — Maintains `state.md` with architectural decisions
8. **VISUAL REGRESSION QA** — Puppeteer screenshot + AI vision check on UI changes
9. **SONNETD TRIGGER** — `sonnetd:` prefix forces 3-Layer Brain+Architect+Worker Swarm mode
10. **3-LAYER SWARM RULE** — Master → Architects → Workers (Workers cannot spawn agents)
11. **BASH SAFETY RULE** — Forbidden from running `rm -rf`, `find /` without user approval
12. **AUTOMATED LINTING** — Agent automatically runs and fixes `eslint`/`ruff` errors before finishing
13. **SECURITY SCANNING** — Fast dependency checks (`npm audit`/`bandit`) before production milestones

---

## The `sonnetd` Trigger

Prefix any complex prompt with `sonnetd` to activate **Brain + Worker mode**:

```bash
sonnetd Build a full analytics dashboard for Leadflow with backend API and DB schema
```

**What happens:**
1. Claude Sonnet (Brain) reads the prompt and writes a detailed execution plan
2. Sonnet delegates each task to parallel Gemini worker agents via Swarm
3. Workers build everything simultaneously and return finished files
4. Sonnet reviews and integrates all outputs

This is the fastest way to build large, multi-file features.

---

## OmniRoute Combo Strategy

| Combo | Best For | Model Stack |
|-------|----------|-------------|
| `gemini-coder` | Standard coding tasks | Gemini 3.1 Pro → Gemini 3.5 Flash → Sonnet |
| `architect` | System design, DB schemas | Gemini Pro High → Sonnet → Gemini Pro Low |
| `debugger` | Debugging complex errors | Sonnet → Gemini Pro Agent → Gemini Pro |
| `bigbrain` | Maximum reasoning tasks | Gemini Pro High → Sonnet → Gemini Flash |
| `code-sprint` | Fast boilerplate | Gemini Flash Medium → Flash Low → Sonnet |
| `turbo` | Quick single-file edits | Gemini Flash → Flash Low → Sonnet |

All combos use **task-aware routing** (not random) and have **automatic zero-downtime fallback** if any model's rate limit is hit.

---

## Zero-Downtime Fallback

If any model hits its rate limit mid-session:

```
Sonnet limit hit → OmniRoute catches 429 error
                 → Silently switches to Gemini 3.1 Pro
                 → Session continues without interruption
                 → Worker agents retain full context via OmniRoute
```

You will never see a session-breaking rate limit error again.

---

## Token Optimization

LLMLingua-2 MCP compresses all large inputs before sending to the model:

| Content Type | Compression Ratio | Tokens Saved |
|-------------|-------------------|--------------|
| Code files | 0.3 (70% reduction) | ~70% |
| Log files | 0.1 (90% reduction) | ~90% |
| Documentation | 0.5 (50% reduction) | ~50% |

---

## Installation & Setup

### Prerequisites

```bash
# Install Claude Code CLI
npm install -g @anthropic-ai/claude-code

# Install OmniRoute
npm install -g omniroute

# Install LLMLingua-2
pip install llmlingua

# Install GitHub CLI (for push)
brew install gh
```

### 1. Configure OmniRoute

```bash
omniroute setup
# Add your agy (Antigravity Pro) API key when prompted
```

### 2. Apply Settings

Copy [`config/settings.json`](config/settings.json) to `~/.claude/settings.json`:

```bash
cp config/settings.json ~/.claude/settings.json
```

### 3. Apply CLAUDE.md Rules

Copy [`config/CLAUDE.md`](config/CLAUDE.md) to `~/.claude/CLAUDE.md`:

```bash
cp config/CLAUDE.md ~/.claude/CLAUDE.md
```

### 4. The Interactive UI

The setup script automatically injects the `claudem` bash UI into your `~/.zshrc`. This provides a dynamic model selector, isolated profile environments, and fuzzy matching for combos!

Just reload your shell:

```bash
source ~/.zshrc
```

### 5. Start a Session

```bash
claudem                     # Launch with default combo
claudem --combo gemini-coder  # Launch with specific combo
```

---

## File Structure

```
claudem/
├── README.md               ← This file
├── config/
│   ├── settings.json       ← Claude Code settings (MCP, timeouts, model config)
│   └── CLAUDE.md           ← The 11 mandatory SDE rules (loaded every session)
├── scripts/
│   ├── setup.sh            ← One-command setup script
│   └── health_check.sh     ← Verify all components are working
├── docs/
│   ├── architecture.md     ← Deep dive into the Brain+Worker architecture
│   ├── combos.md           ← OmniRoute combo reference
│   └── troubleshooting.md  ← Common issues and fixes
└── .gitignore
```

---

## Known Fixed Issues

| Issue | Fix Applied |
|-------|------------|
| MCP servers failing at startup | `timeout: 30000` + `initializationTimeout: 15000` in settings.json |
| Agent hanging/stalling mid-session | `apiTimeout: 60000` in settings.json |
| Rules not loading reliably | Moved from `customInstructions` → `CLAUDE.md` (guaranteed load) |
| Background Haiku/Fable token drain | `smallFastModel: agy/gemini-3.5-flash-low` routes to OmniRoute |
| Overly broad bash commands | Rule 11 (BASH SAFETY) in CLAUDE.md blocks dangerous commands |
| Agent breaking working code | Rule 6 (MICRO-COMMITS) gives instant git revert capability |

---

## License

MIT — use freely, modify as needed.

---

*Built for autonomous, professional-grade software engineering in the terminal.*
