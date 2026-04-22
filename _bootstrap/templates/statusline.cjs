#!/usr/bin/env node
// Claude Code statusLine — Sekai_workflow template
// Segments:  cwd │  branch │  XX% [bar] │ Session XX% │ Weekly XX% │  model
// No external dependencies (Node built-ins only). Requires a Nerd Font in the terminal.

'use strict';

const { execSync } = require('child_process');

const GREEN   = '\x1b[32m';
const YELLOW  = '\x1b[33m';
const RED     = '\x1b[31m';
const MAGENTA = '\x1b[35m';
const DIM     = '\x1b[2m';
const RESET   = '\x1b[0m';

function progressBar(pct, width) {
  const filled = Math.round((pct / 100) * width);
  return '█'.repeat(filled) + '░'.repeat(width - filled);
}

function colorForPct(pct) {
  if (pct < 30) return GREEN;
  if (pct < 60) return YELLOW;
  return RED;
}

let raw = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => { raw += chunk; });
process.stdin.on('end', () => {
  let data = {};
  try { data = JSON.parse(raw); } catch (_) {}

  // 1. CWD basename
  const cwdRaw = (data.cwd
    || (data.workspace && data.workspace.current_dir)
    || process.cwd()).replace(/\\/g, '/');
  const cwdShort = cwdRaw.replace(/\/+$/, '').split('/').pop() || cwdRaw;
  const cwdSeg = ` ${cwdShort}`;

  // 2. Git branch (omit segment entirely if not in a repo)
  let branchSeg = '';
  try {
    const branch = execSync(
      `git -C "${cwdRaw}" --no-optional-locks branch --show-current 2>/dev/null`,
      { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }
    ).trim();
    if (branch) branchSeg = ` ${branch}`;
  } catch (_) {}

  // 3. Context usage (% + 10-cell bar, color-coded)
  let ctxSeg = '';
  const ctxWin = data.context_window;
  if (ctxWin) {
    let pct = ctxWin.used_percentage;
    if (pct == null && ctxWin.current_usage && ctxWin.context_window_size) {
      const used = (ctxWin.current_usage.input_tokens || 0)
                 + (ctxWin.current_usage.cache_read_input_tokens || 0);
      pct = (used / ctxWin.context_window_size) * 100;
    }
    if (pct != null) {
      pct = Math.min(100, Math.max(0, Math.round(pct)));
      ctxSeg = ` ${colorForPct(pct)}${pct}% [${progressBar(pct, 10)}]${RESET}`;
    }
  }

  // 4. Session usage (5-hour rate limit — Pro/Max only, may be absent)
  let sessionSeg = '';
  if (data.rate_limits && data.rate_limits.five_hour
      && typeof data.rate_limits.five_hour.used_percentage === 'number') {
    const pct = Math.min(100, Math.max(0, Math.round(data.rate_limits.five_hour.used_percentage)));
    sessionSeg = `${colorForPct(pct)}Session ${pct}%${RESET}`;
  }

  // 5. Weekly usage (7-day rate limit — Pro/Max only, may be absent)
  let weekSeg = '';
  if (data.rate_limits && data.rate_limits.seven_day
      && typeof data.rate_limits.seven_day.used_percentage === 'number') {
    const pct = Math.min(100, Math.max(0, Math.round(data.rate_limits.seven_day.used_percentage)));
    weekSeg = `${colorForPct(pct)}Weekly ${pct}%${RESET}`;
  }

  // 6. Model
  const modelName = (data.model && data.model.display_name) || '';
  const modelSeg = modelName ? `${MAGENTA} ${modelName}${RESET}` : '';

  const SEP = ` ${DIM}│${RESET} `;
  const parts = [cwdSeg];
  if (branchSeg)  parts.push(branchSeg);
  if (ctxSeg)     parts.push(ctxSeg);
  if (sessionSeg) parts.push(sessionSeg);
  if (weekSeg)    parts.push(weekSeg);
  if (modelSeg)   parts.push(modelSeg);

  process.stdout.write(parts.join(SEP));
});
