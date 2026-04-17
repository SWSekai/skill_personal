// PostToolUse hook: 寫入 memory 時建立 pending flag，寫入 skills 時清除 flag
// 輸入: stdin JSON with tool_name, tool_input, cwd
//
// 精準偵測邏輯：
// - Memory 寫入：必須匹配 `.claude/projects/<proj>/memory/<file>.md` 完整路徑
//   （避免把 `sekai-workflow/memo/` 這類 Skill 目錄誤判為 memory 寫入）
// - Skill 寫入：路徑任一處含 `skills` 或 `sekai-workflow/<name>/SKILL.md|README.md`
//   （兩者都算同步點，寫入任一即清旗）

const fs = require('fs');
const path = require('path');

// Matches <anything>/.claude/projects/<project>/memory/<file>.md
// but not MEMORY.md (index file)
const MEMORY_WRITE_RE = /[\/\\]\.claude[\/\\]projects[\/\\][^\/\\]+[\/\\]memory[\/\\][^\/\\]+\.md$/i;

// Matches paths under .claude/skills/ OR sekai-workflow/<name>/SKILL.md|README.md
const SKILL_WRITE_RE = /(?:[\/\\]\.claude[\/\\]skills[\/\\])|(?:[\/\\]sekai-workflow[\/\\][^\/\\]+[\/\\](?:SKILL|README)\.md$)/i;

let input = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => { input += chunk; });
process.stdin.on('end', () => {
  try {
    const data = JSON.parse(input);
    const cwd = data.cwd || process.cwd();
    const FLAG_DIR = path.join(cwd, '.local');
    const FLAG_FILE = path.join(FLAG_DIR, '.pending_skill_sync');

    const filePath = (data.tool_input && (data.tool_input.file_path || data.tool_input.path)) || '';
    const lowerPath = filePath.toLowerCase();

    const isMemoryWrite = MEMORY_WRITE_RE.test(filePath) && !lowerPath.endsWith('memory.md');
    const isSkillWrite = SKILL_WRITE_RE.test(filePath);

    // 寫入 memory 檔案（排除 MEMORY.md 索引檔）→ 建立 flag
    if (isMemoryWrite) {
      if (!fs.existsSync(FLAG_DIR)) {
        fs.mkdirSync(FLAG_DIR, { recursive: true });
      }
      fs.writeFileSync(FLAG_FILE, filePath, 'utf8');
    }

    // 寫入 skills 目錄 → 清除 flag
    if (isSkillWrite) {
      if (fs.existsSync(FLAG_FILE)) {
        fs.unlinkSync(FLAG_FILE);
      }
    }
  } catch (e) {
    // 解析失敗不阻擋
  }
  process.exit(0);
});
