from mcp.server.fastmcp import FastMCP
import asyncio
import os
import shlex

# Initialize FastMCP server
mcp = FastMCP("Claudem Swarm")

@mcp.tool()
async def delegate_task(role: str, task: str, tier: str = "worker") -> str:
    """
    Spawns an autonomous background claudem sub-agent to complete a specific task in parallel.
    CRITICAL: YOU MUST ONLY CALL THIS TOOL IF THE USER EXPLICITLY STARTS THEIR PROMPT WITH THE EXACT WORD "swarm" (e.g. "swarm fix the bug" or "swarm: search logs").
    Do NOT call this tool under any other circumstances, so you do not disturb normal coding sessions.
    
    Args:
        role: The job title of the sub-agent (e.g., 'database_engineer', 'frontend_dev'). Must be filename-safe.
        task: A detailed, explicit prompt telling the agent exactly what to do and what files to edit.
        tier: 'worker' (default) for fast Gemini coders. 'architect' for Sonnet planners.
    """
    role = "".join(c for c in role if c.isalnum() or c in "_-")
    if not role:
        role = "worker"
        
    base_dir = os.getcwd()
    agent_dir = os.path.join(base_dir, ".agents", role)
    os.makedirs(agent_dir, exist_ok=True)
    
    # Inject context so the sub-agent knows to edit the main project files
    system_prompt = (
        f"You are an autonomous sub-agent. Role: {role}. "
        f"CRITICAL: The main project files are located one directory up in '../'. "
        f"You must use paths like '../filename' to read and write the real project files. "
        f"Never initialize a git repo here. Do the following task, then summarize what you did:\n\n{task}"
    )
    
    safe_prompt = shlex.quote(system_prompt)
    combo = "combo/architect" if tier == "architect" else "combo/gemini-coder"
    cmd = f"omniroute launch -- --model {combo} --permission-mode auto -p {safe_prompt} < /dev/null"
    
    env = os.environ.copy()
    if 'CLAUDE_CODE_MAX_OUTPUT_TOKENS' in env:
        del env['CLAUDE_CODE_MAX_OUTPUT_TOKENS']
        
    # Run in the background
    process = await asyncio.create_subprocess_shell(
        cmd,
        cwd=agent_dir,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE,
        env=env
    )
    
    stdout, stderr = await process.communicate()
    
    output = stdout.decode('utf-8')
    errs = stderr.decode('utf-8')
    
    result = f"=== Sub-Agent '{role}' Finished ===\n"
    if output.strip():
        result += f"Output:\n{output.strip()}\n"
    if errs.strip():
        result += f"\nErrors/Logs:\n{errs.strip()}\n"
        
    if process.returncode != 0:
        result += f"\n[Agent exited with code {process.returncode}]"
        
    return result

if __name__ == "__main__":
    mcp.run()
