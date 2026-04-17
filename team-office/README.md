# team-office — 互動協作

## 功能說明

整合五種與使用者互動的協作模式：AI TODO 處理、即時白板、Markdown 互動式決策表、技術筆記整理、交接文件產出。

## 使用方式

```
/team-office <todo|board|decide|notes|handoff> [args...]
```

## Model

- **建議 model**: `sonnet`（主體）
- **Effort**: `medium`
- **理由**: 多步驟互動工作流，需要判斷結構與增量更新
- **例外**: `handoff` 子命令建議透過 Agent 呼叫 **Opus**（摘要 + 風險評估屬性）

## 觸發條件

- `todo` / `decide` / `notes` / `handoff`：手動呼叫
- `board`：諮詢類對話自動觸發 / 手動呼叫

## 執行流程

| 子命令 | 用途 |
|---|---|
| `todo [add/list/<n>]` | 處理 AI TODO 清單 |
| `board [topic]` | 即時白板（諮詢、規劃類對話） |
| `decide <topic>` | Markdown 互動式決策表（核取／填寫） |
| `notes [topic]` | 結構化技術筆記 |
| `handoff [--share]` | 交接文件（離開前產出進度 + 環境 + 待辦文件） |

## 目錄結構

```
team-office/
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
| （新增）| `handoff` |
