# `/team follow-up` 流程規範

> 對 whiteboard / decision 檔進行重新接續處理的專用子指令。
> SKILL.md §H 只放對外行為，完整流程與解析器規則於本檔。

## 1. 子指令定義

### 語法
```
/team follow-up <file>
/team follow-up              # 空檔名 → 列最近 5 筆
```

### 行為總覽
1. 解析 `<file>` 引數（允許省略 `.md`、前綴模糊匹配）
2. 於 `.local/docs/whiteboards/` 與 `.local/docs/decisions/` 下搜尋匹配檔（**過濾 `CLOSED_*`**）
3. 0 筆 / 1 筆 / 多筆 → 各自分支（見第 2 節）
4. Read 目標檔 → 依類型分派至 §3 / §4 處理器
5. 實作或推進單項 → 完成後結案

### 作用域
- 僅限 `.local/docs/whiteboards/` 與 `.local/docs/decisions/` 兩目錄
- 不含 `.local/docs/summary/`（summary 目錄已於 2026-04-22 廢棄；結案摘要改寫入 CLOSED_ 原檔末尾）
- 不含 `.local/docs/tech-note/`、`.local/docs/handoff/`（非互動檔）

## 2. 檔名匹配策略

### 2.1 匹配規則
1. **完全匹配**：`<file>` == 完整檔名 → 命中
2. **省略副檔名**：`<file>` + `.md` == 檔名 → 命中
3. **前綴模糊匹配**：檔名以 `<file>` 開頭 → 候選
4. **類型後綴補全**：`<file>` + `_board.md` 或 `<file>` + `_decision.md` → 候選
5. **無後綴匹配**：若上述皆無命中，以「所在目錄」判別類型（`whiteboards/` → board handler，`decisions/` → decision handler），接收不含後綴的檔名為候選

### 2.2 CLOSED 過濾
- 候選列舉階段即排除所有 `CLOSED_*` 檔（靜默，不提示）
- 若使用者精確輸入 `CLOSED_xxx` → 例外提示「此檔已結案」並附 summary 路徑

### 2.3 多筆候選處理
使用 **AskUserQuestion** 讓使用者點選：

```
questions: [{
  question: "找到多筆匹配，請選擇要 follow-up 的檔案：",
  header: "選擇檔案",
  options: [
    { label: "260422_auth_refactor_board.md", description: "whiteboard / 最後修改 13:45" },
    { label: "260422_auth_refactor_decision.md", description: "decision / 最後修改 14:10" },
  ],
  multiSelect: false
}]
```

### 2.4 跨目錄檔名衝突（例：同 `_board` 與 `_decision` 都匹配）
- 優先順序：**類型後綴準確匹配 > 目錄位置 > 修改時間最新**
- 仍無法唯一確定 → 強制走 AskUserQuestion

### 2.5 零筆匹配
- 空檔名 → 列 `.local/docs/{whiteboard,decision}/` 下最近 5 筆（過濾 CLOSED_），AskUserQuestion 選
- 檔名不存在 → 列最相近的 3 筆候選（用 Levenshtein 或前綴相似），AskUserQuestion 選

## 3. decision 檔 follow-up 處理器

### 3.1 解析流程
1. Read 檔案全文
2. 逐區塊掃描（以 `##` / `###` 分界）
3. 對每個區塊：
   - **若標題含 `✅` 或區塊本文含 `<!-- closed -->`** → 補 `✅` 若缺，跳過
   - 否則解析所有 `- [ ]` / `- [x]` 選項
   - 讀取「補充說明」blockquote 內容
   - 若為自由輸入題（`**答案**: ____`）→ 見 §6

### 3.2 互斥雙勾偵測（非單一路線雙勾允許）
- 若區塊標註「單一路線」卻有 ≥2 個 `- [x]` → **暫停**，列衝突項，請使用者釐清
- 若區塊標註「非單一路線」或「可複選」 → 允許多勾

### 3.3 未勾選必選區塊處理
- 若區塊標註「單一路線」且全部 `- [ ]`（無一勾選）→ 暫停，標示區塊編號
- 「可複選」區塊全未勾 → 視為「跳過本區塊」，不暫停

### 3.4 補充說明中「新增需求」識別
使用者常於補充說明加入超出原選項的要求（例：「請加上 X」「另外要考慮 Y」）。
- 若補充說明含**指令性動詞**（請、要、需要、要求、建議加入、記得、別忘了）→ 於變更摘要中列為「新增需求」區塊
- 若 Claude 判斷新增需求**超出本次決策範圍** → 標示「需另開決策」並於實作後建空殼決策檔

### 3.5 產出變更摘要 + 實作
1. 於 CLI 輸出變更摘要表（已選選項 + 新增需求）
2. 使用者以 tool approval UI 確認（執行首個 Edit tool call 即為 gate）
3. 依選項實作
4. 完成後走 §8 結案流程

## 4. whiteboard 檔 follow-up 處理器

### 4.1 解析流程
1. Read 檔案，定位 "Pending" section（或語意等效區段）
2. 若區塊含 `✅` 或 `<!-- closed -->` → 跳過
3. 收集所有 Pending 項為候選清單

### 4.2 推進單項
使用 **AskUserQuestion** 讓使用者選要推進哪項：

```
questions: [{
  question: "白板現有 Pending 項目，要推進哪一項？",
  header: "選項目",
  options: [<pending items>, { label: "不推進，僅載入 context", description: "延續對話自由討論" }],
  multiSelect: false
}]
```

### 4.3 選後行為
- 選項目 → 直接進入該項工作（讀相關程式碼、修改、測試），完成後把項目從 Pending 移至 Completed 並更新白板
- 選「不推進」→ 僅載入 context，等使用者下一句對話

### 4.4 無 Pending 項
- 若白板 Pending 為空 → 提示「無待辦項目」並列 Completed 最近 3 條供回顧，接著結束

## 5. CLOSED 檔 / 區塊標記互通

見 `naming.md` §3。本檔僅列 follow-up 時的解析動作：
1. 遇到 `CLOSED_*` 檔 → 候選階段過濾
2. 遇到區塊有 `<!-- closed -->` 但標題無 `✅` → 補 `✅` 於標題末（Edit）
3. 遇到區塊標題有 `✅` → 解析器直接 `continue`

## 6. 自由輸入題互動（統一語法）

### 6.1 語法規範
決策檔中的自由輸入題必須使用：
```markdown
**答案**: ____________
```
或已填：
```markdown
**答案**: Redis 7.0
```

### 6.2 follow-up 偵測
- 若 `**答案**: ` 後僅含底線（`_+` regex）或空字串 → 視為**未填**
- 未填 → 走 §6.3 引導
- 已填 → 直接採用字串

### 6.3 未填引導
以 **AskUserQuestion** 收答案：
```
questions: [{
  question: "§X.Y 自由輸入題未填答案：<題目描述>。請選或自訂：",
  header: "自由輸入題",
  options: [<Claude 預估 2-4 個合理值>, { label: "自訂", description: "於 Other 輸入" }],
  multiSelect: false
}]
```
收到答案後 **Edit 回檔案**，把 `____________` 替換為答案（留下歷史可追蹤），繼續解析。

## 7. 生成互動檔的時間取樣

所有 follow-up 產生新檔（例如重啟保留候選建新 decision、whiteboard 推進後新 Completed 項時間戳）必須先呼叫：
```bash
date '+%Y-%m-%d %H:%M'
```
以 Bash 輸出為準，不得直接套用 context `currentDate`。詳見 `naming.md` §2。

## 8. 結案流程（decision 檔）

實作完成後強制走（依 SKILL.md §C.6 + naming.md §5 內嵌結案流程）：
1. **Append 內嵌結案摘要**至原 decision 檔末尾（保留 §1-§n 勾選痕跡，格式見 `naming.md` §5.2）
2. 原 decision 檔 rename 為 `CLOSED_YYMMDD_<topic>_decision.md`
3. 更新 `.local/docs/living/PROJECT_JOURNAL.md` 索引欄（連結指向 `CLOSED_*_decision.md`）

**不再寫獨立 summary 檔**：`.local/docs/summary/` 目錄已廢棄（2026-04-22）。

## 9. 錯誤與邊界

| 情境 | 處理 |
|---|---|
| `<file>` 為目錄 | 報錯「請給檔名，不是目錄」 |
| `<file>` 含 `..` 或絕對路徑 | 拒絕，只接受 `.local/docs/` 相對路徑 |
| 檔為空 / 格式不合 | 提示「檔案格式異常，無 decision/board 結構」並中止 |
| 解析到區塊編號重複（`§1.1` 出現兩次） | 告警並列所有重複位置 |
| 使用者於 AskUserQuestion 選「Other」 | 以使用者輸入為準，視為自訂檔名/答案 |

## 10. 與其他子指令互動

- `/team decide` 建立的 decision 檔 **必須**符合本檔 §6 自由輸入題語法
- `/team board` 建立的 whiteboard 檔 **必須**用 `YYMMDD_<topic>_board.md` 格式（見 `naming.md` §1）
- `/team journal view` 不會列出正進行中的檔，只列 `CLOSED_*` 的歷史
