// PostToolUse hook: 寫入 memory 時建立 pending flag，寫入 skills 時清除 flag
// 輸入: stdin JSON with tool_name, tool_input, cwd

const fs = require('fs');
const path = require('path');

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

    // 寫入 memory 目錄（排除 MEMORY.md 索引檔）→ 建立 flag
    if (lowerPath.includes('memory') && !lowerPath.endsWith('memory.md')) {
      if (!fs.existsSync(FLAG_DIR)) {
        fs.mkdirSync(FLAG_DIR, { recursive: true });
      }
      fs.writeFileSync(FLAG_FILE, filePath, 'utf8');
    }

    // 寫入 skills 目錄 → 清除 flag
    if (lowerPath.includes('skills')) {
      if (fs.existsSync(FLAG_FILE)) {
        fs.unlinkSync(FLAG_FILE);
      }
    }
  } catch (e) {
    // 解析失敗不阻擋
  }
  process.exit(0);
});
