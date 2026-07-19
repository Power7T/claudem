# Troubleshooting Guide

## MCP Servers Not Connecting

**Symptom:** claudem starts but `delegate_task` tool is unavailable or LLMLingua compression doesn't work.

**Cause:** MCP Python servers take a few seconds to boot and claudem gave up before they were ready.

**Fix:** Already applied in `settings.json` via `timeout: 30000` and `initializationTimeout: 15000`. If still failing:

```bash
# Test swarm MCP manually
python3 ~/.omniroute/swarm_mcp.py

# Test llmlingua MCP manually
python3 /path/to/llmlingua/server.py
```

If either crashes, check that dependencies are installed:
```bash
pip3 install llmlingua mcp
```

---

## Session Freezing / Hanging

**Symptom:** claudem stops responding mid-task, cursor blinks but nothing happens.

**Cause:** Internal API call timed out.

**Fix:** Already applied via `apiTimeout: 60000` in settings.json. If it still hangs beyond 60 seconds, press `Ctrl+C` to cancel the current tool call. claudem will ask if you want to continue.

---

## Rules Not Being Followed

**Symptom:** claudem is not using git commits, not running self-healing tests, not compressing files.

**Cause:** CLAUDE.md failed to load (rare) or rules were only in `customInstructions` (unreliable).

**Verify rules are loaded:**
```bash
# At the start of a claudem session, type:
what are your operating rules?
```
It should list all 11 rules. If it doesn't:
```bash
# Verify CLAUDE.md is correct
cat ~/.claude/CLAUDE.md
```

---

## Rate Limit Hitting All Models

**Symptom:** Session stops with "all models exhausted" message.

**Cause:** Extremely rare — you burned through Sonnet AND all Gemini daily limits in one session.

**Fix:** claudem will display a timer and automatically resume when limits reset (typically 1 hour). No action needed.

---

## Haiku/Fable Appearing in Logs

**Symptom:** You see `claude-haiku` or `claude-fable` in telemetry, not your agy models.

**Cause:** These are claudem's internal background API calls (skill loading, MCP checks). They bypass OmniRoute.

**Fix:** Already applied via `smallFastModel: agy/gemini-3.5-flash-low`. This routes background calls through your agy OmniRoute account. Check telemetry periodically to confirm Haiku no longer appears.

---

## Overly Broad Bash Command Blocked

**Symptom:** claudem stops mid-task saying it cannot run a command without approval.

**Cause:** Rule 11 (BASH SAFETY) correctly blocked a potentially dangerous command.

**Fix:** Review the proposed command carefully. If it is safe, type `yes` to approve it for this session. If you want to permanently allow specific patterns, add them to your CLAUDE.md bash safety rule.

---

## sonnetd Not Triggering Swarm Mode

**Symptom:** Typing `sonnetd [task]` does not activate Brain+Worker mode.

**Cause:** The keyword override in OmniRoute combos may not be supported by your OmniRoute version, or claudem is not routing through a combo.

**Fix:** Verify you are using a combo:
```bash
claudem --combo gemini-coder
```
Then use the `sonnetd` prefix. If still not working, manually select Claude Sonnet from the claudem model menu before typing your task.

---

## Combo Fallback Not Working

**Symptom:** Session crashes instead of falling back to next model on rate limit.

**Cause:** Combo models list may not have enough fallbacks.

**Check active combos:**
```bash
omniroute models
```

**Add fallback to a combo via OmniRoute:**
```bash
omniroute combos edit gemini-coder
```

---

## Health Check

Run the full health check to diagnose any issue:

```bash
bash scripts/health_check.sh
```
