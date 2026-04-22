// Stop hook: 偵測回應尾端是否有純文字 Y/N 問句（違反 CLAUDE.md Rule 15）
// 輸入: stdin JSON { session_id, transcript_path, stop_hook_active }
// 輸出: JSON { decision: "block", reason, additionalContext } 若偵測到問句

'use strict';

const fs = require('fs');

// 從 transcript JSONL 取出最後一筆 assistant 訊息的純文字內容
function readLastAssistantText(transcriptPath) {
  if (!transcriptPath || !fs.existsSync(transcriptPath)) return '';
  let raw;
  try {
    raw = fs.readFileSync(transcriptPath, 'utf8');
  } catch (_) {
    return '';
  }
  const lines = raw.split(/\r?\n/).filter(Boolean);
  // 由後往前找最後一筆 assistant
  for (let i = lines.length - 1; i >= 0; i--) {
    let entry;
    try { entry = JSON.parse(lines[i]); } catch (_) { continue; }
    if (entry.type !== 'assistant') continue;
    const content = entry.message && entry.message.content;
    if (!content) continue;
    // content 可能是 string 或 array of {type, text}
    if (typeof content === 'string') return content;
    if (Array.isArray(content)) {
      const textParts = content
        .filter(b => b && b.type === 'text' && typeof b.text === 'string')
        .map(b => b.text);
      if (textParts.length) return textParts.join('\n');
    }
  }
  return '';
}

let input = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => { input += chunk; });
process.stdin.on('end', () => {
  try {
    const data = JSON.parse(input);

    // stop_hook_active 為 true 表示是 hook 觸發的續跑，避免無限迴圈
    if (data.stop_hook_active) process.exit(0);

    // 取得最後一筆 assistant 文字（向下相容舊欄位 assistant_message）
    let message = data.assistant_message || '';
    if (!message) {
      message = readLastAssistantText(data.transcript_path);
    }
    if (!message) process.exit(0);

    // 已使用 AskUserQuestion tool 代表是合法多選確認，跳過
    if (message.includes('AskUserQuestion')) process.exit(0);

    // 取最後 500 字元檢查（Y/N 問句通常在結尾）
    const tail = message.slice(-500);

    const patterns = /(要我|是否需要|需要我|要執行|要開始|要不要|需不需要|可以嗎|好嗎|要嗎|對嗎|行嗎|確認一下|幫你.*嗎|要.*嗎？|嗎？$)/;

    if (patterns.test(tail)) {
      const result = {
        decision: 'block',
        reason: '偵測到純文字 Y/N 問句（違反 Rule 15）',
        additionalContext: '[Hook 攔截 Rule 15] 你的回應結尾包含確認問句但未使用 AskUserQuestion tool。立即改用 AskUserQuestion 重新提問（第一個選項標 Recommended），或直接執行對應動作讓使用者透過 tool approval UI 決定。禁止用文字問句要求使用者打字回覆。'
      };
      process.stdout.write(JSON.stringify(result));
    }
  } catch (_) {
    // JSON 解析失敗不阻擋，避免 hook 自爆影響使用者
  }
  process.exit(0);
});
