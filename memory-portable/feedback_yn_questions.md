---
name: 不要問 Y/N 問題
description: 禁止文字確認問句，方案確認用 AskUserQuestion UI，操作確認靠 tool permission UI
type: feedback
---

**絕對禁止在文字中問確認問題。** 這是最高優先級規則。

禁止：
- 「要執行嗎？」「要我...嗎？」「是否需要...？」「需要我...嗎？」
- 任何形式的 Y/N 確認問句
- 在方案末尾加「要開始嗎？」

正確做法（依場景）：

1. **方案/計畫確認**（CLAUDE.md Rule 15）→ 用 `AskUserQuestion` tool
   - 第一個選項：「開始執行 (Recommended)」
   - 使用者按 Enter 即可進行
   
2. **操作確認**（commit、push、刪除等）→ 直接呼叫 tool 執行
   - 使用者透過 tool permission UI 決定允許或拒絕

3. **下一步明確** → 直接執行，不問

**Why:** 使用者多次強調（2026-04-02 兩次），文字確認浪費時間且打斷流程。AskUserQuestion 提供結構化 UI，tool permission 提供操作攔截。

**How to apply:** 寫完方案後，立刻呼叫 AskUserQuestion 而非用文字問。操作類直接做。永遠不要在回應尾端放問句。
