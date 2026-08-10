import { existsSync, mkdirSync, writeFileSync, readdirSync, rmSync, readFileSync, statSync } from "node:fs";
import { join } from "node:path";
import os from "node:os";

const port = 20128;
const baseUrl = `http://localhost:${port}`;
const homesToSync = Array.from(new Set([
  join(os.homedir(), ".claude")
]));

// Define target combos and models we want to keep
const targetCombos = [
  "code-sprint",
  "architect",
  "debugger",
  "bigbrain",
  "turbo",
  "test-forge",
  "agentic-coder",
  "web-builder",
  "master-reasoner",
  "pure-thinking",
  "gemini-coder"
];

function getEffortLevel(modelId) {
  const id = modelId.toLowerCase();
  if (id.includes("flash") || id.includes("lite") || id === "turbo" || id === "code-sprint") {
    return "low";
  }
  if (id.includes("pro") || id.includes("opus") || id.includes("sonnet") || id.includes("thinking") || id.includes("agent") || id.includes("reasoner") || id.includes("debugger") || id.includes("architect")) {
    return "high";
  }
  return undefined;
}

let adminKey = "";
const envPath = join(os.homedir(), ".omniroute", ".env");
if (existsSync(envPath)) {
  try {
    const envContent = readFileSync(envPath, "utf8");
    const match = envContent.match(/^OMNIROUTE_API_KEY=(.+)$/m);
    if (match) {
      adminKey = match[1].replace(/['"]/g, "").trim();
    }
  } catch (e) {
    // ignore
  }
}

function getOrCreateTokenForProfile(profileName) {
  const primaryProfilesRoot = join(os.homedir(), ".claude", "profiles");
  const settingsPath = join(primaryProfilesRoot, profileName, "settings.json");
  if (existsSync(settingsPath)) {
    try {
      const settings = JSON.parse(readFileSync(settingsPath, "utf8"));
      const token = settings?.env?.ANTHROPIC_AUTH_TOKEN;
      if (token && token.length > 5) {
        return token;
      }
    } catch (e) {
      // ignore
    }
  }

  if (adminKey) {
    try {
      const result = execSync(
        `omniroute auth-tokens create --name "profile-${profileName}" --api-key "${adminKey}" --output json`,
        { encoding: "utf8" }
      );
      const data = JSON.parse(result);
      if (data && data.token) {
        return data.token;
      }
    } catch (e) {
      // ignore
    }
  }
  return null;
}

function profileNameFromModelId(modelId) {
  return modelId
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

async function main() {
  console.log("🧼 Cleaning and generating active Claude Code profiles...");

  let models = [];
  try {
    const res = await fetch(`${baseUrl}/v1/models`, { signal: AbortSignal.timeout(5000) });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const body = await res.json();
    models = body.data ?? [];
  } catch (err) {
    console.log(`ℹ️ OmniRoute server offline during sync, generating static profile templates.`);
  }

  const activeProfilesMap = new Map();

  for (const m of models) {
    const id = m.id;
    if (!id) continue;

    const isAgy = id.startsWith("agy/");
    const isCombo = m.owned_by === "combo" || id.startsWith("combo/");

    if (isAgy || isCombo) {
      const rawId = id.startsWith("combo/") ? id : (m.owned_by === "combo" ? `combo/${id}` : id);
      const profileName = profileNameFromModelId(rawId.replace(/^combo\//, ""));
      const effort = getEffortLevel(id);

      const settings = {
        $schema: "https://json.schemastore.org/claude-code-settings.json",
        model: id,
        env: {
          ANTHROPIC_BASE_URL: baseUrl,
          ANTHROPIC_MODEL: id,
          CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY: "1",
          CLAUDE_CODE_AUTO_COMPACT_WINDOW: "190000"
        }
      };

      if (effort) {
        settings.effortLevel = effort;
      }

      activeProfilesMap.set(profileName, settings);
    }
  }

  // Ensure default combos are always in activeProfilesMap even if offline
  for (const combo of targetCombos) {
    if (!activeProfilesMap.has(combo)) {
      activeProfilesMap.set(combo, {
        $schema: "https://json.schemastore.org/claude-code-settings.json",
        model: `combo/${combo}`,
        env: {
          ANTHROPIC_BASE_URL: baseUrl,
          ANTHROPIC_MODEL: `combo/${combo}`,
          CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY: "1",
          CLAUDE_CODE_AUTO_COMPACT_WINDOW: "190000"
        }
      });
    }
  }

  const primaryRoot = join(os.homedir(), ".claude", "profiles");
  let existingNumericDirs = [];
  if (existsSync(primaryRoot)) {
    try {
      existingNumericDirs = readdirSync(primaryRoot).filter(d => /^[0-9]+$/.test(d));
    } catch (e) {
      // ignore
    }
  }

  const numericProfilesToKeep = new Set(["1", "2", "3", "4", "5", ...existingNumericDirs]);
  for (const name of numericProfilesToKeep) {
    const token = getOrCreateTokenForProfile(name);
    activeProfilesMap.set(name, {
      $schema: "https://json.schemastore.org/claude-code-settings.json",
      model: name,
      env: {
        ANTHROPIC_BASE_URL: baseUrl,
        ANTHROPIC_MODEL: name,
        ANTHROPIC_AUTH_TOKEN: token || "omniroute-no-auth",
        CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY: "1",
        CLAUDE_CODE_AUTO_COMPACT_WINDOW: "190000"
      }
    });
  }

  for (const home of homesToSync) {
    const profilesRoot = join(home, "profiles");

    if (!existsSync(profilesRoot)) {
      mkdirSync(profilesRoot, { recursive: true });
    }

    let baseSettings = {};
    const globalSettingsPath = join(home, "settings.json");
    if (existsSync(globalSettingsPath)) {
      try {
        baseSettings = JSON.parse(readFileSync(globalSettingsPath, "utf8"));
      } catch (e) {}
    }

    const globalClaudeMdPath = join(home, "CLAUDE.md");
    let globalClaudeMdContent = "";
    if (existsSync(globalClaudeMdPath)) {
      try {
        globalClaudeMdContent = readFileSync(globalClaudeMdPath, "utf8");
      } catch (e) {}
    }

    let writtenCount = 0;
    for (const [profileName, settings] of activeProfilesMap.entries()) {
      const dirPath = join(profilesRoot, profileName);
      if (!existsSync(dirPath)) {
        mkdirSync(dirPath, { recursive: true });
      }

      const mergedSettings = {
        ...baseSettings,
        ...settings,
        env: {
          ...(baseSettings.env || {}),
          ...(settings.env || {})
        },
        permissions: baseSettings.permissions || settings.permissions,
        mcpServers: baseSettings.mcpServers || settings.mcpServers,
        customInstructions: baseSettings.customInstructions || "IMPORTANT: All operating rules are defined in CLAUDE.md. Read and follow them on every session."
      };

      const settingsPath = join(dirPath, "settings.json");
      try { writeFileSync(settingsPath, JSON.stringify(mergedSettings, null, 2) + "\n", "utf8"); } catch (e) {}

      if (globalClaudeMdContent) {
        const profileClaudeMdPath = join(dirPath, "CLAUDE.md");
        try { writeFileSync(profileClaudeMdPath, globalClaudeMdContent, "utf8"); } catch (e) {}
      }

      writtenCount++;
    }
    console.log(`✅ Successfully synchronized ${writtenCount} active profiles to ${profilesRoot}`);
  }
}

main().catch(err => {
  console.error("Fatal error:", err);
  process.exit(1);
});


// Strip stale oauthAccount from ~/.claude.json to avoid "Both ANTHROPIC_AUTH_TOKEN and /login managed key set" warning
const globalClaudeJson = join(os.homedir(), ".claude.json");
if (existsSync(globalClaudeJson)) {
  try {
    const raw = readFileSync(globalClaudeJson, "utf8");
    const parsed = JSON.parse(raw);
    if (parsed.oauthAccount || parsed.sessionKey) {
      delete parsed.oauthAccount;
      delete parsed.sessionKey;
      writeFileSync(globalClaudeJson, JSON.stringify(parsed, null, 2), "utf8");
    }
  } catch (e) {
    // ignore
  }
}
