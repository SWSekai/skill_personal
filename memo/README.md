# /collab — 互動協作合併 Skill

整合 todo、whiteboard、md-collab、tech-notes 四個原始 Skill。

## 使用方式

| 指令 | 說明 |
|---|---|
| `/collab todo [add/list/<n>]` | 處理 AI TODO 清單 |
| `/collab board [topic]` | 即時白板 |
| `/collab decide <topic>` | Markdown 互動式決策表 |
| `/collab notes [topic]` | 結構化技術筆記 |

## Model

- **Skill model**：`sonnet`
- 四個子命令均屬於多步驟工作流，sonnet 即可勝任

## 觸發

- **手動**：使用者呼叫 `/collab <subcommand>`
- **自動**：
  - `board`：諮詢、規劃、排錯類對話自動觸發
  - `notes`：偵測到技術知識型問答時被動提醒

## 主要流程

### `/collab todo`
讀取 `.local/collab/TODO.md` → 排序 → 追問細節 → 執行 → 更新狀態 → 完成回報

### `/collab board`
建立 `.local/docs/whiteboards/YYMMDD_主題.md`，每次 follow-up 增量更新待辦/已完成/決策/備註。

### `/collab decide`
分析主題 → 生成核取表（預填建議值）→ 使用者編輯 → Claude 讀回 → 差異摘要 → 確認後實作

### `/collab notes`
存放於 `.local/docs/tech-notes/`，完整結構化文章（目錄、概述、章節、陷阱、最佳實踐、延伸閱讀）。

## 檔案結構

```
.claude/skills/collab/
├── SKILL.md
└── README.md
```

## 對應原 Skill

| 原 Skill | 子命令 |
|---|---|
| todo | `/collab todo` |
| whiteboard | `/collab board` |
| md-collab | `/collab decide` |
| tech-notes | `/collab notes` |
