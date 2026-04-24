// UserPromptSubmit hook: detect system-info query intent, suggest /ask info
// Replaces deleted CLAUDE.md Rule 13 (2026-04-24, CLOSED_260424_claudemd_slim §3.8)
//
// Trigger strategy: strict keyword allowlist on high-signal phrases.
// Avoids false positives on narrow questions like "這個函數做什麼".
// Triggers on integrative questions: "整體架構", "資料流", "端到端流程" etc.

const fs = require('fs');
const path = require('path');

// High-signal phrases — 必須是 integrative/architecture-level query
const TRIGGER_PATTERNS = [
  /系統架構/,
  /整體架構/,
  /整體流程/,
  /完整流程/,
  /端到端/,
  /資料流(?:程|向|動)?/,
  /資料如何流/,
  /data\s*flow/i,
  /end-to-end/i,
  /architecture/i,
  /how\s+does\s+the\s+system\s+work/i,
  /整體.*運作/,
];

// Exclusions — 單純問「這段 code 做什麼」不觸發
const EXCLUDE_PATTERNS = [
  /^這個函數/,
  /^這個變數/,
  /^這行.*是什麼/,
  /^what\s+does\s+this\s+function/i,
];

let input = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => { input += chunk; });
process.stdin.on('end', () => {
  try {
    const data = JSON.parse(input);
    const cwd = data.cwd || process.cwd();
    const prompt = (data.user_prompt || data.prompt || '').trim();

    // settings toggle — user can disable via settings.local.json
    const settingsPath = path.join(cwd, '.claude', 'settings.local.json');
    if (fs.existsSync(settingsPath)) {
      try {
        const s = JSON.parse(fs.readFileSync(settingsPath, 'utf8'));
        if (s.ask_info && s.ask_info.auto_route === false) {
          process.exit(0);
        }
      } catch (_) { /* ignore malformed */ }
    }

    // Exclusion check first
    for (const re of EXCLUDE_PATTERNS) {
      if (re.test(prompt)) {
        process.exit(0);
      }
    }

    // Trigger check
    let matched = false;
    for (const re of TRIGGER_PATTERNS) {
      if (re.test(prompt)) {
        matched = true;
        break;
      }
    }

    if (matched) {
      // Emit context injection — Claude sees this on receipt of prompt
      const message = '[Hook: ask_info_router] 偵測到系統資訊/架構/資料流類問題 — 建議考慮呼叫 `/ask info` 建立互動式追蹤文件，而非單純 CLI 回答。使用者若不需追蹤可忽略此提示。可於 `.claude/settings.local.json` 設 `ask_info.auto_route = false` 關閉本 hook。';
      process.stdout.write(JSON.stringify({
        hookSpecificOutput: {
          hookEventName: 'UserPromptSubmit',
          additionalContext: message
        }
      }));
    }
  } catch (e) {
    // Silent on parse failure
  }
  process.exit(0);
});
