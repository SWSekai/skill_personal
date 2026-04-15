// Stop hook: 檢查是否有未完成的 Memory→Skill 同步
// 輸入: stdin JSON with assistant_message, stop_reason, cwd
// 輸出: JSON with decision: "block" if pending sync exists

const fs = require('fs');
const path = require('path');

let input = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => { input += chunk; });
process.stdin.on('end', () => {
  try {
    const data = JSON.parse(input);
    const cwd = data.cwd || process.cwd();
    const FLAG_FILE = path.join(cwd, '.local', '.pending_skill_sync');

    if (fs.existsSync(FLAG_FILE)) {
      const pendingFile = fs.readFileSync(FLAG_FILE, 'utf8').trim();
      const result = {
        decision: 'block',
        reason: 'Memory→Skill 同步未完成',
        additionalContext: `[Hook 攔截] 你寫入了 Memory 檔案 (${pendingFile}) 但尚未同步到 .claude/skills/。根據 Rule 9 三方同步規則，你必須評估此 Memory 是否應寫入 Skill。如果應該，立即建立或更新對應的 Skill 檔案並同步 Sekai_workflow/；如果不適合作為 Skill，請在回應中明確說明原因，然後刪除 flag 檔案 (${FLAG_FILE})。`
      };
      process.stdout.write(JSON.stringify(result));
    }
  } catch (e) {
    // 錯誤不阻擋
  }
  process.exit(0);
});
