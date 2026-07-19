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

## 9. SONNETD TRIGGER
If the user's prompt starts with `sonnetd`:
- You are the Brain (Sonnet). Write a detailed execution plan only.
- You are STRICTLY FORBIDDEN from reading files, exploring directories, or searching the codebase. Your ONLY job is to immediately delegate to workers. Do not waste time gathering context.
- Use the `delegate_task` tool (you MUST provide both `role` and `task` string arguments) to assign each implementation task to a Gemini worker agent. Tell the workers to read the files themselves.
- You are FORBIDDEN from writing implementation code yourself.

## 10. 2-LAYER SWARM RULE (ANTI-LOOP PROTECTION)
Worker agents spawned via `delegate_task` are STRICTLY FORBIDDEN from spawning their own sub-agents. Only the top-level Brain agent may delegate. Workers must write code themselves and return results directly. This prevents infinite delegation loops and token waste.

## 11. BASH SAFETY RULE
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
