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
        'if (value && value.length > 0) { let str = new TextDecoder("utf-8").decode(value); if (str.includes(\'"name"\')) { str = str.replace(/"name"\\s*:\\s*"bash"/g, \'"name":"Bash"\').replace(/"name"\\s*:\\s*"read"/g, \'"name":"Read"\').replace(/"name"\\s*:\\s*"write"/g, \'"name":"Write"\').replace(/"name"\\s*:\\s*"edit"/g, \'"name":"Edit"\').replace(/"name"\\s*:\\s*"grep"/g, \'"name":"Grep"\').replace(/"name"\\s*:\\s*"websearch"/g, \'"name":"WebSearch"\').replace(/"name"\\s*:\\s*"webfetch"/g, \'"name":"WebFetch"\'); value = new TextEncoder().encode(str); } } controller.enqueue(value);'
      );
    }

    // 5. Fix Ambiguous Model errors in open-sse/services/model.ts
    if (content.includes('errorType: "ambiguous_model"')) {
      content = content.replace(
        /if\s*\(\s*candidatesToUse\.length\s*>\s*1\s*\)\s*\{[\s\S]*?errorType:\s*"ambiguous_model"[\s\S]*?\};?\s*\}/,
        'if (candidatesToUse.length > 1) {\n    const autoProvider = (activeCandidates && activeCandidates.length > 0 ? activeCandidates[0] : null) || (candidatesToUse.includes("google") ? "google" : (candidatesToUse.includes("agy") ? "agy" : candidatesToUse[0]));\n    const canonicalModel = resolveInferredProviderModel(autoProvider, modelId);\n    return { provider: autoProvider, model: canonicalModel, extendedContext };\n  }'
      );
    }

    // 6. Fix Ambiguous Model 400 error in src/sse/handlers/chatHelpers.ts
    if (content.includes('Ambiguous model') && content.includes('HTTP_STATUS.BAD_REQUEST')) {
      const chatHelpersTarget = /if\s*\(\s*\(modelInfo\s*as\s*any\)\.errorType\s*===\s*"ambiguous_model"\s*\)\s*\{[\s\S]*?return\s*\{\s*error:\s*errorResponse\(HTTP_STATUS\.BAD_REQUEST,\s*message\)\s*\};\s*\}/;
      const chatHelpersReplacement = 'if ((modelInfo as any).errorType === "ambiguous_model") {\n      const candidates: string[] = (modelInfo as any).candidateProviders || [];\n      const modelLower = (modelInfo.model || modelStr).toLowerCase();\n      const family = modelLower.match(NON_OAUTH_MODEL_PREFIX)?.[1];\n      const pick = family && PREFERRED_BY_FAMILY[family];\n      const autoPick = (pick && candidates.includes(pick)) ? pick : (candidates.includes("google") ? "google" : (candidates.includes("agy") ? "agy" : candidates[0]));\n      log.info(\n        "ROUTING",\n        `${modelStr} → ${autoPick}/${modelInfo.model || modelStr} (ambiguity auto-resolved)`\n      );\n      modelInfo.provider = autoPick;\n    }';
      content = content.replace(chatHelpersTarget, chatHelpersReplacement);
    }

    if (content !== orig) {
      fs.writeFileSync(fullPath, content, 'utf8');
      patchedCount++;
    }
  } catch (err) {
    console.error(`⚠️  Patch error on ${fullPath}:`, err.message);
  }
}

// Target primary source files & handlers
const keyFiles = [
  'open-sse/services/claudeCodeToolRemapper.ts',
  'open-sse/services/claudeCodeExtraRemap.ts',
  'open-sse/translator/response/gemini-to-claude.ts',
  'open-sse/translator/response/openai-to-claude.ts',
  'open-sse/services/model.ts',
  'src/sse/handlers/chatHelpers.ts',
  'src/lib/modelMetadataRegistry.ts',
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

console.log(`✅ Patched ${patchedCount} OmniRoute files for PascalCase Claude Code tool compatibility & ambiguous model auto-resolution.`);
