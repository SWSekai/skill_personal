// Stop hook: Detect stale context summaries and remind user to run /clean
// Input: stdin JSON with assistant_message, stop_reason, cwd
// Output: JSON with decision: "block" if stale summaries found and cooldown expired

const fs = require('fs');
const path = require('path');

const COOLDOWN_MS = 30 * 60 * 1000; // 30 minutes

let input = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => { input += chunk; });
process.stdin.on('end', () => {
  try {
    const data = JSON.parse(input);
    const stopReason = data.stop_reason || '';
    const cwd = data.cwd || process.cwd();

    // Only check on end_turn
    if (stopReason !== 'end_turn') {
      process.exit(0);
    }

    const summaryDir = path.join(cwd, '.local', 'context_summary');
    const cooldownFile = path.join(cwd, '.local', '.clean_reminder_cooldown');

    // Check if summary directory exists
    if (!fs.existsSync(summaryDir)) {
      process.exit(0);
    }

    // List .md files excluding current_topic.md
    const files = fs.readdirSync(summaryDir)
      .filter(f => f.endsWith('.md') && f !== 'current_topic.md');

    if (files.length === 0) {
      process.exit(0);
    }

    // Check cooldown
    if (fs.existsSync(cooldownFile)) {
      const lastReminder = parseInt(fs.readFileSync(cooldownFile, 'utf8').trim(), 10);
      if (Date.now() - lastReminder < COOLDOWN_MS) {
        process.exit(0); // Still in cooldown
      }
    }

    // Update cooldown timestamp
    const localDir = path.join(cwd, '.local');
    if (!fs.existsSync(localDir)) {
      fs.mkdirSync(localDir, { recursive: true });
    }
    fs.writeFileSync(cooldownFile, String(Date.now()));

    const result = {
      decision: 'block',
      reason: 'Stale context summaries detected',
      additionalContext: `[Hook: Context Reminder] Found ${files.length} stale summary file(s) in .local/context_summary/: ${files.join(', ')}. Consider running /clean to save current work, clean old summaries, and reset context. This reminder triggers at most once per 30 minutes.`
    };
    process.stdout.write(JSON.stringify(result));
  } catch (e) {
    // Errors should not block
  }
  process.exit(0);
});
