# memo — 互動協作

## 功能說明

整合四種與使用者互動的協作模式：AI TODO 處理、即時白板、Markdown 互動式決策表、技術筆記整理。

## 使用方式

```
/memo <todo|board|decide|notes> [args...]
```

## Model

- **建議 model**: `sonnet`
- **Effort**: `medium`
- **理由**: 多步驟互動工作流，需要判斷結構與增量更新

## 觸發條件

- `todo` / `decide` / `notes`：手動呼叫
- `board`：諮詢類對話自動觸發 / 手動呼叫

## 執行流程

| 子命令 | 用途 |
|---|---|
| `todo [add/list/<n>]` | 處理 AI TODO 清單 |
| `board [topic]` | 即時白板（諮詢、規劃類對話） |
| `decide <topic>` | Markdown 互動式決策表（核取／填寫） |
| `notes [topic]` | 結構化技術筆記 |

## 目錄結構

```
memo/
├── SKILL.md
├── README.md
├── references/
│   └── interaction-modes.md     ← 四種互動模式說明（單選/多選/填寫/混合）
└── assets/
    ├── collab-template.md       ← 決策表初始模板
    └── whiteboard-template.md   ← 白板初始模板
```

## 整合來源

| 原 Skill | 對應子命令 |
|---|---|
| todo | `todo` |
| whiteboard | `board` |
| md-collab | `decide` |
| tech-notes | `notes` |
