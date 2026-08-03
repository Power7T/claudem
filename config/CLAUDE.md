@RTK.md

---

# CLAUDEM OPERATING RULES
> These rules are MANDATORY and apply to every single session without exception.

## 1. SWARM ORCHESTRATION
When given multiple disconnected tasks, use `delegate_task` to spawn parallel agents. Do NOT do them sequentially yourself.

## 2. SKELETON MAPPING
Before reading any large file, extract its structure first using grep:
```bash
grep -E '^def |^class |^const |^function |^export ' file.py
```
Only read the full file if the skeleton is insufficient.

## 3. DYNAMIC PRE-COMPRESSION
Before reading any file >150 lines, MUST use `compress_prompt` MCP tool (target ratio 0.3 for code, 0.1 for logs/docs) via LLMLingua-2.

## 4. CONTEXT AMNESIA
After completing major milestones or hitting 50,000 tokens:
- Run `git commit`
- Write a 5-sentence summary to `state.md`
- Clear conversation history and resume from `state.md` only

## 5. SELF-HEALING LOOP
You are FORBIDDEN from declaring a task "done" without first running the code or tests in the terminal. If it crashes or throws an error, silently fix it and re-run. Only say "done" when the terminal confirms success.

## 6. ATOMIC MICRO-COMMITS
Run `git commit -am "Task X: <description>"` immediately after completing every individual task. If a later task breaks something, revert to the last working commit instead of guessing.

## 7. STATE LOG
Always maintain a `state.md` file in the project root with:
- Core architectural decisions and WHY they were made
- Current task status
- Any known limitations or TODOs

## 8. VISUAL REGRESSION QA
When modifying any UI, CSS, or frontend layout, you MUST:
1. Run a headless Puppeteer/Playwright script to take a screenshot
2. Read the screenshot file using your file tools
3. Visually verify the layout is correct before declaring done

## 9. MASTER ARCHITECT TRIGGERS (`sonnetd` vs `swarm`)
If the user's prompt starts with `sonnetd` (Precise Mode):
- You are the Master Brain. You MUST read files and meticulously gather context before writing a flawless execution plan.
- Use `delegate_task(tier="architect")` for massive multi-system tasks, and `tier="worker"` for standard tasks. Issue all calls simultaneously.
- You are FORBIDDEN from writing implementation code yourself.

If the user's prompt starts with `swarm` (Instant Speed Mode):
- You are the Master Brain. You are STRICTLY FORBIDDEN from reading any files or directories. Do NOT gather context.
- Your ONLY job is to instantly parse the prompt and issue simultaneous `delegate_task(tier="architect")` calls (for massive tasks) or `tier="worker"` calls.
- The sub-agents will read the files themselves. You must spawn them in under 30 seconds.

## 10. 3-LAYER SWARM RULE (ANTI-LOOP PROTECTION)
Worker agents (Gemini) spawned via `delegate_task` are STRICTLY FORBIDDEN from spawning their own sub-agents. Master Brains can spawn Architects, and Architects can spawn Workers, but Workers MUST write code themselves and return results directly. This prevents infinite delegation loops and token waste.

## 11. BASH SAFETY & SYNTAX RULE
CRITICAL TOOL SYNTAX: When executing terminal commands, you MUST call the tool exactly as `Bash` (with a capital B). Do NOT use lowercase `bash` or the tool will fail.
You are FORBIDDEN from running overly broad or destructive bash commands such as:
- `rm -rf` on any directory above the current project folder
- `find /` or `find ~` without strict depth limits
- Any command that modifies system files outside the project directory

If such a command is required, STOP and ask the user for explicit confirmation first.

## 12. AUTOMATED LINTING & FORMATTING
Before declaring any task "done" or committing code, you MUST run the project's linter and formatter (e.g., `npm run lint`, `npx eslint --fix`, `ruff check --fix`, or `black`). Silently fix any formatting errors or unused variables it finds. Do not leave messy code.

## 13. LIGHTWEIGHT SECURITY SCANNING
Before completing major milestones, run a fast dependency security scan (e.g., `npm audit` or `bandit`). Do not get stuck in infinite dependency resolution loops—if a vulnerability is too complex to fix quickly, log it in `state.md` for human review instead of breaking the build.

---
