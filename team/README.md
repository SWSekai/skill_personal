# team — 互動協作

## 功能說明

整合八種與使用者互動的協作模式：AI TODO 處理、即時白板、Markdown 互動式決策表、技術筆記整理、交接文件產出、工作報告、專案活文件維護、既有互動檔接續（follow-up）。

> **2026-04-17 改名**：`/team-office` → `/team`（名稱過長、補全體驗差）；`notes` 子命令改為單數 `note`。
> **2026-04-17 新增**：`report` 子命令從 `/ask` 搬入（工作報告屬於協作產出）。
> **2026-04-22 新增**：`living` 子命令，白板/決策表結案時自動維護的專案活文件；白板與決策表結案流程強制主動化（`CLOSED_` 前綴更名 + 活文件更新）。
> **2026-04-22 新增**：`follow-up` 子命令 — 以 `/team follow-up <file>` 一鍵接續既有 whiteboard / decision 檔；白板檔名加 `_board` 後綴；決策檔檔名補 `YYMMDD_<topic>_decision.md` 規範；新增 `references/naming.md`、`references/followup.md` 拆分細節規則。
> **2026-04-24 新增**：`report --daily` 模式 — 每日 Teams 日報，輸出 `.local/report/YYMMDD_brief.md`；資料源含 whiteboard/decision 結案摘要 + TODO 變化 + modify_log + 使用者交接；board 結案 Step 3.5、decide 結案 Step 6.6、`/commit-push` Step 11 **自動呼叫更新**；`/hello` Step 3.4 跨日檢查未處理交接；新增 `references/daily-brief.md` + `assets/brief-template.md`。

## 使用方式

```
/team <todo|board|decide|note|handoff|report|living|follow-up> [args...]
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
| `report --daily [date]` | **每日 Teams 日報**（完成／進行中／待辦／交接／決策五段，輸出 `.local/report/YYMMDD_brief.md`） |
| `living [view\|regen]` | 專案活文件（自動維護；手動查看或重建） |
| `follow-up <file>` | 接續既有 whiteboard / decision 檔（支援省略副檔名 + 前綴模糊匹配；`CLOSED_*` 自動過濾） |

## 結案流程更新（2026-04-22）

白板與決策表在結案時新增兩個強制步驟：

### 白板結案（`/team board` Step 3）
1. 更新文件狀態（Completed / Paused）
2. **更名**：`YYMMDD_topic.md` → `CLOSED_YYMMDD_topic.md`
3. **新增結案摘要章節**：包含關鍵成果、決策紀錄、未解決事項
4. **更新活文件**（`.local/docs/living/PROJECT_JOURNAL.md`）
5. **更新每日 brief**（Step 3.5，2026-04-24 新增）：`.local/report/YYMMDD_brief.md` 的決策與完成區塊

### 決策表結案（`/team decide` Step 6）
1. 於原檔末尾 **append 內嵌結案摘要**（2026-04-22 改版：取代獨立 summary 檔）
2. **更名**：`decision/YYMMDD_<topic>_decision.md` → `decision/CLOSED_YYMMDD_<topic>_decision.md`
3. **更新活文件**（`.local/docs/living/PROJECT_JOURNAL.md`）
4. **更新每日 brief**（Step 6.6，2026-04-24 新增）：`.local/report/YYMMDD_brief.md` 的決策與完成區塊

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
│   ├── interaction-modes.md     ← 四種互動模式說明（單選/多選/填寫/混合）
│   ├── naming.md                ← 檔名格式、時間同步（Bash date 強制）、CLOSED 前綴與區塊結案規則
│   ├── followup.md              ← /team follow-up 完整流程、檔名匹配、AskUserQuestion 互動、自由輸入題處理
│   └── daily-brief.md           ← /team report --daily 每日 Teams 日報完整規格（資料源、格式、觸發、跨日）
└── assets/
    ├── collab-template.md       ← 決策表初始模板
    ├── whiteboard-template.md   ← 白板初始模板
    └── brief-template.md        ← 每日 Teams 日報模板
```

## References 目錄導覽

> 依 CLAUDE.md Rule 19 規範，每個 skill 的 `references/` 子目錄都需提供本類導覽表，讓 Claude 與使用者快速定位規則文件。

| 檔名 | 用途 | 何時 Read | 依賴 |
|---|---|---|---|
| `interaction-modes.md` | 四種互動模式（單選/多選/填寫/混合）語法與表格範例 | `/team decide` 生成決策表時；`/team follow-up` 解析自由輸入題時 | 無（獨立參考） |
| `naming.md` | 檔名格式統一規範、Bash date 時間同步、CLOSED 前綴與 `✅ / <!--closed-->` 區塊結案、內嵌結案摘要模板、skill 子目錄職責 | 所有子指令產生新檔前；結案時（append 內嵌摘要 + rename）；使用者提出新檔時驗證命名 | 無 |
| `followup.md` | `/team follow-up` 完整流程、檔名匹配策略、AskUserQuestion 互動、decision/whiteboard 處理器、自由輸入題處理 | `/team follow-up` 呼叫時 | 依賴 `naming.md`（檔名規範、CLOSED 過濾）、`interaction-modes.md`（自由輸入題語法） |
| `daily-brief.md` | `/team report --daily` 每日 Teams 日報：資料源（whiteboard/decision 結案 + TODO + modify_log + handoff）、格式、觸發掛接點（board Step 3.5 / decide Step 6.6 / commit-push Step 11 / hello Step 3.4）、跨日行為、解析規則、modify_log 缺失警示 | `/team report --daily` 呼叫時；board/decide 結案自動呼叫時；`/commit-push` Step 11 時；`/hello` Step 3.4 跨日檢查時 | 依賴 `naming.md`（CLOSED 檔名、結案摘要解析）、`assets/brief-template.md`（輸出模板） |

## 整合來源

| 原 Skill / 子命令 | 對應子命令 |
|---|---|
| todo | `todo` |
| whiteboard | `board` |
| md-collab | `decide` |
| tech-notes | `note`（原 `notes`） |
| handoff | `handoff` |
| `/ask report` | `report`（2026-04-17 搬入） |
