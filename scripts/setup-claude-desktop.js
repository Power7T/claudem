import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';

const claudeConfigPath = path.join(os.homedir(), 'Library', 'Application Support', 'Claude', 'claude_desktop_config.json');

if (!fs.existsSync(path.dirname(claudeConfigPath))) {
  console.log('ℹ️  Claude Desktop App directory not found on this system.');
  process.exit(0);
}

let existingConfig = {};
if (fs.existsSync(claudeConfigPath)) {
  try {
    existingConfig = JSON.parse(fs.readFileSync(claudeConfigPath, 'utf8'));
  } catch (err) {
    existingConfig = {};
  }
}

// Inject MCP servers for Swarm & OmniRoute helpers into Claude Desktop App
existingConfig.mcpServers = existingConfig.mcpServers || {};
existingConfig.mcpServers.swarm = {
  command: "python3",
  args: [path.join(os.homedir(), ".omniroute", "swarm_mcp.py")]
};

// Enable Co-working & workspace preferences
existingConfig.preferences = existingConfig.preferences || {};
existingConfig.preferences.coworkWebSearchEnabled = true;
existingConfig.preferences.coworkScheduledTasksEnabled = true;

fs.writeFileSync(claudeConfigPath, JSON.stringify(existingConfig, null, 2), 'utf8');
console.log('✅ Synchronized Claude Desktop App configuration with OmniRoute MCP!');
