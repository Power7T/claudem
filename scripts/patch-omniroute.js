import fs from 'node:fs';
import path from 'node:path';

const omniDir = '/opt/homebrew/lib/node_modules/omniroute';

if (!fs.existsSync(omniDir)) {
  console.log('ℹ️  OmniRoute global installation not found at default Homebrew path, skipping patch.');
  process.exit(0);
}

let patchedCount = 0;

function patchFile(fullPath) {
  if (!fs.existsSync(fullPath)) return;
  try {
    let content = fs.readFileSync(fullPath, 'utf8');
    let orig = content;

    // 1. Source TS: REVERSE_MAP reverse mapping fix (maps lower -> TitleCase AND TitleCase -> TitleCase)
    content = content.replace(
      'REVERSE_MAP[v] = k;',
      'REVERSE_MAP[k] = v; REVERSE_MAP[v] = v;'
    );

    // 2. Minified JS: reverse map loops in compiled chunks
    content = content.replace(
      'for(let[e,r]of Object.entries(t))s[r]=e;',
      'for(let[e,r]of Object.entries(t)){s[e]=r;s[r]=r;}'
    );
    content = content.replace(
      'for(let[e,r]of Object.entries(t))s[r]=e',
      'for(let[e,r]of Object.entries(t)){s[e]=r;s[r]=r;}'
    );
    content = content.replace(
      'for(let[t,r]of Object.entries(e))s[r]=t;',
      'for(let[t,r]of Object.entries(e)){s[t]=r;s[r]=r;}'
    );

    // 3. Source TS & JS: normalizeToolName return fix (ensures TitleCase for Claude Code)
    content = content.replace(
      'return REVERSE_MAP[name] ?? name;',
      'return REVERSE_MAP[name] ?? REVERSE_MAP[name?.toLowerCase()] ?? (name ? name.charAt(0).toUpperCase() + name.slice(1) : name);'
    );

    // 4. SSE Stream output corrector
    if (content.includes('controller.enqueue') || content.includes('enqueue(')) {
      content = content.replace(
        /controller\.enqueue\(value\);/g,
        'if (value && value.length > 0) { let str = new TextDecoder("utf-8").decode(value); if (str.includes(\'"name"\')) { str = str.replace(/"name"\\s*:\\s*"bash"/g, \'"name":"Bash"\').replace(/"name"\\s*:\\s*"read"/g, \'"name":"Read"\').replace(/"name"\\s*:\\s*"write"/g, \'"name":"Write"\').replace(/"name"\\s*:\\s*"edit"/g, \'"name":"Edit"\').replace(/"name"\\s*:\\s*"grep"/g, \'"name":"Grep"\').replace(/"name"\\s*:\\s*"glob"/g, \'"name":"Glob"\').replace(/"name"\\s*:\\s*"websearch"/g, \'"name":"WebSearch"\').replace(/"name"\\s*:\\s*"webfetch"/g, \'"name":"WebFetch"\'); value = new TextEncoder().encode(str); } } controller.enqueue(value);'
      );
    }

    if (content !== orig) {
      fs.writeFileSync(fullPath, content, 'utf8');
      patchedCount++;
    }
  } catch (err) {
    // Ignore read/permission issues
  }
}

// Target primary source files & handlers
const keyFiles = [
  'open-sse/services/claudeCodeToolRemapper.ts',
  'open-sse/services/claudeCodeExtraRemap.ts',
  'open-sse/translator/response/gemini-to-claude.ts',
  'open-sse/translator/response/openai-to-claude.ts',
  'dist/src/mitm/handlers/base.ts',
  'dist/src/mitm/server.cjs',
  'dist/open-sse/mcp-server/server.js'
];

for (const rel of keyFiles) {
  patchFile(path.join(omniDir, rel));
}

// Target server chunks containing open-sse or REVERSE_MAP
const chunksDir = path.join(omniDir, 'dist/.build/next/server/chunks');
if (fs.existsSync(chunksDir)) {
  const entries = fs.readdirSync(chunksDir);
  for (const entry of entries) {
    if (entry.includes('open-sse') || entry.startsWith('_')) {
      const p = path.join(chunksDir, entry);
      if (fs.statSync(p).isFile()) {
        patchFile(p);
      }
    }
  }
}

console.log(`✅ Patched ${patchedCount} OmniRoute files for PascalCase Claude Code tool compatibility.`);
