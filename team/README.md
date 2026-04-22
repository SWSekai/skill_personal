# team — 互動協作

## 功能說明

整合七種與使用者互動的協作模式：AI TODO 處理、即時白板、Markdown 互動式決策表、技術筆記整理、交接文件產出、工作報告、專案活文件維護。

> **2026-04-17 改名**：`/team-office` → `/team`（名稱過長、補全體驗差）；`notes` 子命令改為單數 `note`。
> **2026-04-17 新增**：`report` 子命令從 `/ask` 搬入（工作報告屬於協作產出）。
> **2026-04-22 新增**：`living` 子命令，白板/決策表結案時自動維護的專案活文件；白板與決策表結案流程強制主動化（`CLOSED_` 前綴更名 + 活文件更新）。

## 使用方式

```
/team <todo|board|decide|note|handoff|report|living> [args...]
```

## Model

- **建議 model**: `sonnet`（主體）
- **Effort**: `medium`
- **理由**: 多步驟互動工作流，需要判斷結構與增量更新
- **例外**: `handoff` 與 `report` 子命令建議透過 Agent 呼叫 **Opus**（摘要 + 風險評估屬性）

## 觸發條件

- `todo` / `decide` / `note` / `handoff` / `report`：手動呼叫
- `board`：諮詢類對話自動觸發 / 手動呼叫
- `living`：**由 `board` 和 `decide` 結案時自動呼叫**（也可手動 `/team living view` 查看或 `/team living regen` 重建）

## 執行流程

| 子命令 | 用途 |
|---|---|
| `todo [add/list/<n>]` | 處理 AI TODO 清單 |
| `board [topic]` | 即時白板（諮詢、規劃類對話） |
| `decide <topic>` | Markdown 互動式決策表（核取／填寫） |
| `note [topic]` | 結構化技術筆記 |
| `handoff [--share]` | 交接文件（離開前產出進度 + 環境 + 待辦文件） |
| `report [scope]` | 從修改紀錄生成簡報用工作報告（full / weekly / 指定區間） |
| `living [view\|regen]` | 專案活文件（自動維護；手動查看或重建） |

## 結案流程更新（2026-04-22）

白板與決策表在結案時新增兩個強制步驟：

### 白板結案（`/team board` Step 3）
1. 更新文件狀態（Completed / Paused）
2. **更名**：`YYMMDD_topic.md` → `CLOSED_YYMMDD_topic.md`
3. **新增結案摘要章節**：包含關鍵成果、決策紀錄、未解決事項
4. **更新活文件**（`.local/docs/living/PROJECT_JOURNAL.md`）

### 決策表結案（`/team decide` Step 6）
1. 產出決策摘要（`.local/docs/summary/`）—— 原有
2. **更名**：`decision/topic.md` → `decision/CLOSED_topic.md`（取代原「刪除」行為）
3. **更新活文件**（`.local/docs/living/PROJECT_JOURNAL.md`）

### 專案活文件（`.local/docs/living/PROJECT_JOURNAL.md`）
- 三個表格：決策紀錄 / 討論成果 / 🔖 保留候選
- 僅追加，不刪除（永久歷史紀錄）
- 每筆紀錄連結至對應的 `CLOSED_*` 來源文件

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
