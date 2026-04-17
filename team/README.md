# team — 互動協作

## 功能說明

整合六種與使用者互動的協作模式：AI TODO 處理、即時白板、Markdown 互動式決策表、技術筆記整理、交接文件產出、工作報告。

> **2026-04-17 改名**：`/team-office` → `/team`（名稱過長、補全體驗差）；`notes` 子命令改為單數 `note`。
> **2026-04-17 新增**：`report` 子命令從 `/ask` 搬入（工作報告屬於協作產出）。

## 使用方式

```
/team <todo|board|decide|note|handoff|report> [args...]
```

## Model

- **建議 model**: `sonnet`（主體）
- **Effort**: `medium`
- **理由**: 多步驟互動工作流，需要判斷結構與增量更新
- **例外**: `handoff` 與 `report` 子命令建議透過 Agent 呼叫 **Opus**（摘要 + 風險評估屬性）

## 觸發條件

- `todo` / `decide` / `note` / `handoff` / `report`：手動呼叫
- `board`：諮詢類對話自動觸發 / 手動呼叫

## 執行流程

| 子命令 | 用途 |
|---|---|
| `todo [add/list/<n>]` | 處理 AI TODO 清單 |
| `board [topic]` | 即時白板（諮詢、規劃類對話） |
| `decide <topic>` | Markdown 互動式決策表（核取／填寫） |
| `note [topic]` | 結構化技術筆記 |
| `handoff [--share]` | 交接文件（離開前產出進度 + 環境 + 待辦文件） |
| `report [scope]` | 從修改紀錄生成簡報用工作報告（full / weekly / 指定區間） |

## 目錄結構

```
team/
├── SKILL.md
├── README.md
├── references/
│   └── interaction-modes.md     ← 四種互動模式說明（單選/多選/填寫/混合）
└── assets/
    ├── collab-template.md       ← 決策表初始模板
    └── whiteboard-template.md   ← 白板初始模板
```

## 整合來源

| 原 Skill / 子命令 | 對應子命令 |
|---|---|
| todo | `todo` |
| whiteboard | `board` |
| md-collab | `decide` |
| tech-notes | `note`（原 `notes`） |
| handoff | `handoff` |
| `/ask report` | `report`（2026-04-17 搬入） |
