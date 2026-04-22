#!/usr/bin/env node
// PreToolUse hook for the Agent tool.
// Logs every Agent dispatch to .local/model_dispatch.log so the user can audit
// which model tier was actually used (statusline only shows the main session).
//
// Log format:
//   [YYYY-MM-DD HH:MM:SS] [hook] model=<tier> agent=<subagent_type> desc="<...>"
//
// The hook never blocks the tool call. JSON parse / FS errors are silently
// swallowed because a logging failure must not interrupt user work.

'use strict';

const fs = require('fs');
const path = require('path');

let raw = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => { raw += chunk; });
process.stdin.on('end', () => {
  try {
    const event = JSON.parse(raw);
    const toolName = event.tool_name || event.tool || '';
    if (toolName !== 'Agent') return process.exit(0);

    const input = event.tool_input || event.input || {};
    const ts = new Date().toISOString().replace('T', ' ').slice(0, 19);
    const model = input.model || 'inherit';
    const agent = input.subagent_type || 'general-purpose';
    const desc = String(input.description || '').slice(0, 80).replace(/"/g, "'");
    const line = `[${ts}] [hook] model=${model} agent=${agent} desc="${desc}"\n`;

    const cwd = event.cwd || process.cwd();
    const dir = path.join(cwd, '.local');
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    fs.appendFileSync(path.join(dir, 'model_dispatch.log'), line);
  } catch (_) {
    // Silently ignore — logging must not break tool execution
  }
  process.exit(0);
});
