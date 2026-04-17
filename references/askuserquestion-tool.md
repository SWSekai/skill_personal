# AskUserQuestion Tool Reference

> 最後更新：2026-04-17

Claude Code 內建的互動式選項詢問工具。使用者按 Enter 即可選擇推薦項，避免純文字 Y/N 問句。

---

## 本質

- **Deferred tool**（延遲載入工具）
- Schema 不在初始 tool list 中，需要先透過 `ToolSearch` 載入才能呼叫
- 呼叫後由 CLI harness 攔截並渲染成互動式選擇 UI，而非當作一般文字訊息顯示

---

## 載入流程

```
1. ToolSearch(query="select:AskUserQuestion", max_results=1)
   → 回傳完整 JSONSchema 定義

2. schema 載入後，AskUserQuestion 變成可呼叫的 tool

3. 呼叫 AskUserQuestion 傳入 questions 陣列
   → harness 渲染 UI
   → 使用者選擇後回傳 {"問題文字": "選項 label"} 格式
```

**注意**：每個對話 session 中 schema 只需載入一次，之後可直接呼叫。

---

## 參數結構

### Top-level

| 欄位 | 型別 | 說明 |
|---|---|---|
| `questions` | array (1-4) | 題目陣列，同次呼叫可問多題 |
| `answers` | object | 使用者回答（由 harness 填入） |

### 單一 question 物件

| 欄位 | 必填 | 型別 | 說明 |
|---|:---:|---|---|
| `question` | ✓ | string | 完整問句，以問號結尾 |
| `header` | ✓ | string | 很短的標籤（**上限 12 字元**），顯示為 chip/tag |
| `options` | ✓ | array (2-4) | 選項陣列，不可放 "Other"（harness 自動提供） |
| `multiSelect` | ✓ | boolean | 是否允許多選 |

### 單一 option 物件

| 欄位 | 必填 | 說明 |
|---|:---:|---|
| `label` | ✓ | 顯示文字（1-5 字為佳），使用者看到與選擇的內容 |
| `description` | ✓ | 選項說明，解釋選了會發生什麼或 trade-off |
| `preview` | | 選項被 focus 時顯示的 markdown 預覽（ASCII 圖、code snippet 等）。**僅限 single-select**，multi-select 不支援 |

---

## 設計規則

1. **推薦選項永遠排第一**，label 後加 `(Recommended)`
   - 使用者按 Enter 即確認推薦項 → 最少打字成本
2. **選項 2-4 個**，超過會讓使用者難決策
3. **不要自己列 "Other"**，harness 會自動提供讓使用者打字自填
4. **互斥才用 single-select**（multiSelect: false）；可疊加才用 multi-select
5. **preview 用於需視覺比較的場合**：ASCII UI mockup、code 替代實作、設定檔對照。簡單偏好題用 label + description 就夠
6. **header 極短**（≤ 12 字元）：例 `方案選擇`、`儲存位置`、`Auth 方式`

---

## Plan mode 限制

- Plan mode 中可用 AskUserQuestion 釐清需求 / 在方案定稿**前**做選擇
- **不要**用來問「方案 OK 嗎？」「可以 proceed 嗎？」—— 這類方案整體批准用 `ExitPlanMode`
- 問題文字**不要**提到「the plan」（使用者在 `ExitPlanMode` 之前看不到 plan）

---

## 何時使用

對應 CLAUDE.md Rule 15 與 `memo/feedback_yn_questions.md`：

| 情境 | 做法 |
|---|---|
| 方案 / 計畫確認 | **用 AskUserQuestion**，第一選項 `開始執行 (Recommended)` |
| 多種做法抉擇 | **用 AskUserQuestion** 列替代方案，description 寫 trade-off |
| 操作確認（commit、push、刪除） | **直接呼叫 tool**，靠 tool permission UI 攔截 |
| 下一步明確 | **直接執行**，不問 |
| 純文字 Y/N 問句 | **永遠禁止**（`memo/feedback_yn_questions.md`） |

---

## 呼叫範例

### 單題、single-select、含推薦項

```json
{
  "questions": [{
    "question": "要採用哪個方案實作？",
    "header": "方案選擇",
    "multiSelect": false,
    "options": [
      {
        "label": "方案 A (Recommended)",
        "description": "符合現有結構，風險低，隨 git 同步"
      },
      {
        "label": "方案 B",
        "description": "新建獨立 skill，語意不匹配但統一管理"
      }
    ]
  }]
}
```

### 多題一次問

```json
{
  "questions": [
    {
      "question": "儲存位置選哪個？",
      "header": "儲存位置",
      "multiSelect": false,
      "options": [...]
    },
    {
      "question": "順手補 README 索引嗎？",
      "header": "README",
      "multiSelect": false,
      "options": [...]
    }
  ]
}
```

### 含 preview（ASCII mockup 比較）

```json
{
  "questions": [{
    "question": "UI 排版用哪個？",
    "header": "排版",
    "multiSelect": false,
    "options": [
      {
        "label": "垂直堆疊 (Recommended)",
        "description": "手機優先",
        "preview": "┌──────────┐\n│  Header  │\n├──────────┤\n│  Content │\n└──────────┘"
      },
      {
        "label": "水平並排",
        "description": "桌面最佳化",
        "preview": "┌─────┬──────┐\n│ Nav │ Main │\n└─────┴──────┘"
      }
    ]
  }]
}
```

---

## 回傳格式

使用者選擇後，harness 以下列格式把結果送回給 Claude：

```
"問題文字" = "選項 label"
```

多題時多行並列。Claude 根據答案繼續工作。

---

## 交叉參照

- 行為規則：`memo/feedback_yn_questions.md`
- 方案確認流程整合：`build/SKILL.md`（plan 子命令）
- 建立 Skill 時詢問欄位：`skill/SKILL.md`
- Plan 模式配合使用：CLAUDE.md Rule 15
