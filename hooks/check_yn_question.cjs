// Stop hook: 偵測回應尾端是否有純文字問句（未使用 AskUserQuestion tool）
// 輸入: stdin JSON with assistant_message, stop_reason
// 輸出: JSON with decision: "block" if question detected

let input = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => { input += chunk; });
process.stdin.on('end', () => {
  try {
    const data = JSON.parse(input);
    const stopReason = data.stop_reason || '';
    const message = data.assistant_message || '';

    // 只在 end_turn 時檢查
    if (stopReason !== 'end_turn') {
      process.exit(0);
    }

    // 已包含 AskUserQuestion 代表有用 tool，跳過
    if (message.includes('AskUserQuestion')) {
      process.exit(0);
    }

    // 取最後 500 字元檢查
    const tail = message.slice(-500);

    // 中文問句模式
    const patterns = /(要我|是否需要|需要我|要執行|要開始|要不要|需不需要|可以嗎|好嗎|要嗎|對嗎|行嗎|確認一下|幫你.*嗎|要.*嗎？)/;

    if (patterns.test(tail)) {
      const result = {
        decision: 'block',
        reason: '偵測到純文字問句',
        additionalContext: '[Hook 攔截] 你的回應結尾包含確認問句，但沒有使用 AskUserQuestion tool。規則：所有需要使用者確認的問題必須透過 AskUserQuestion tool 提供選項，讓使用者按 Enter 即可確認，而非用文字問句要求使用者打字回覆。請立即改用 AskUserQuestion tool 重新提問，第一個選項設為推薦選項。'
      };
      process.stdout.write(JSON.stringify(result));
    }
  } catch (e) {
    // JSON 解析失敗，不阻擋
  }
  process.exit(0);
});
