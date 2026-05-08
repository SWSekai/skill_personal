# Skill 文件產出參考表

> 所有 Skill 會自動產生的文件、觸發時機、存放位置、用途一覽。
>
> Last updated: 2026-05-08（v2.4 路徑扁平化 — `.hanschen/docs/` 中介層移除）
>
> ⚠️ **路徑權威來源已遷移至** `.hanschen/.history/README.md` §1.1（`.hanschen/` ↔ `.local/` 邊界）。本表保留為跨 skill 文件產出的快速索引；遇路徑歧異時以 `.hanschen/.history/README.md` 為準。

---

## 命名原則（對齊 CLAUDE.md Rule 25 + `.hanschen/.history/README.md` §1）

- **`.hanschen/` = 跨機器共享文件（入專案 git）**：decision、board、journal、guides、handoff、modify_log、report
- **`.local/` = 機器專屬狀態（不入版控）**：context_summary、bag、docs/plan（實作工作檔）、model_dispatch.log、resumption_prompt.md
- 所有子目錄使用**名詞單數**（decision / board / guide / handoff / modify_log / report）；例外：`guides`（多檔合集，2026-05-06 從 `guide` 重命名）
- 2026-05-08 移除 `.hanschen/docs/` 中介層：`.hanschen/docs/{board,decision,living,guides,handoff}/` 全部上移至 `.hanschen/{board,decision,journal,guides,handoff}/`；`living` → `journal`

---

## 跨機器共享文件（入專案 git，在 `.hanschen/` 下）

### 給人讀的互動文件

| Skill | 子命令 / 步驟 | 觸發時機 | 檔名格式 | 存放位置 | 用途 |
|---|---|---|---|---|---|
| **team** | `decide` | 手動觸發 | `YYMMDD_<topic>_decision.md` | `.hanschen/decision/` | 互動式決策表（結案後 rename `CLOSED_*`）|
| **team** | `board` | 3 輪未收斂 / 手動 | `YYMMDD_<topic>_board.md` | `.hanschen/board/` | 白板討論紀錄（結案後 rename `CLOSED_*`）|
| **team** | `journal` | board/decide 結案自動 | `PROJECT_JOURNAL.md` | `.hanschen/journal/` | append-only 索引（CLOSED 摘要連結）|
| **team** | `note` | 手動 | `<topic>.md` | `.hanschen/guides/` | 專案專屬技術筆記、排錯指南 |
| **commit-push** | Step 10 | commit 後若含踩坑經驗 | `<topic>.md` | `.hanschen/guides/` | 實戰經驗指南（症狀→原因→解法→注意事項）|
| **team** | `handoff` | 手動（下班 / 休假前）| `YYMMDD_handoff.md` | `.hanschen/handoff/` | 人類交接文件（進度 + 環境 + 待辦 + 恢復指引）|
| **team** | `handoff` Step 3 | 同上 | `YYMMDD_ai-context/` 目錄 | `.hanschen/handoff/<date>_ai-context/` | AI context bundle（CLAUDE.md + memory + 決策摘要 + guides + modify_log + TODO）|

### AI 運維紀錄（`.local/` 根）

| Skill | 子命令 / 步驟 | 觸發時機 | 檔名格式 | 存放位置 | 用途 |
|---|---|---|---|---|---|
| **commit-push** | Step 5 | commit 後（Haiku 內嵌）| `YYMMDD_<主題>.md` | `.hanschen/modify_log/` | 修改日誌（格式對齊原版 +N -M）|
| **clean** | 系統壓縮 / 手動 `/clean` / 對話開始 | — | `YYMMDD_HHMM_<主題>.md` | `.local/context_summary/` | Context 工作狀態摘要（繼承 context-guard 功能）|
| **clean** | 同上 | — | `current_topic.md` | `.local/context_summary/` | 當前工作主題（任務切換偵測）|
| **team** | `report --daily` | 手動 / board 結案 / decide 結案 / commit-push Step 11 自動 | `YYMMDD_daily_report.md` | `.hanschen/report/` | 每日 Teams 報告 |
| **team** | `todo` | 手動 / btw 入 Pending | `TODO.md` | 專案根 | AI 待辦事項清單（含 Pending / In Progress / Completed）|
| **build** | `do` | 衍生任務時 | 追加至 TODO.md | 專案根 | 從 do 發現的衍生 TODO |
| **build** | `plan` | 方案設計完成 | `YYMMDD_<feature>.md` | `.local/docs/plan/` | 實作方案文件（機器專屬，含 checkbox 步驟清單）|
| **skm** | `pack` | 手動 `/skm pack` | 打包結果 + `manifest.txt` | `.local/bag/` | AI 上下文打包（含 memory、guides、project-skills）|

---

## 入版控文件

| Skill | 觸發時機 | 產出檔案 | 存放位置 | 用途 |
|---|---|---|---|---|
| **commit-push** | Step 2 | `README.md` | 變更目錄下 | 自動更新目錄說明文件 |

---

## Skill / 設定檔（由 skm 管理）

| Skill | 觸發時機 | 產出 | 存放位置 | 用途 |
|---|---|---|---|---|
| **skm** | `sync` 或 `/hello` Step 2 | `SKILL.md` + `README.md` | `.claude/skills/<name>/` | 同步 sekai-workflow 至專案 |
| **skm** | `new` | `SKILL.md` + `README.md` | `.claude/skills/<name>/` + `sekai-workflow/<name>/` | 建立新 Skill 定義 |

---

## Memory 相關（非 `.local/`）

| 類型 | 存放位置 | 管理者 |
|---|---|---|
| 專案 Memory | `~/.claude/projects/<encoded-path>/memory/` | auto memory system + `memory_skill_sync` hook |
| 跨專案 Portable Memory | `sekai-workflow/memory-portable/` | `/skm pack` 回寫 + `sp-init.bat` Step 8 還原 |

---

## 目錄結構總覽

```
.hanschen/                      ← 跨機器共享文件（入專案 git）
├── decision/                   #team decide（含 CLOSED_*_decision.md）
├── board/                      #team board（含 CLOSED_*_board.md）
├── journal/                    #team journal（PROJECT_JOURNAL.md，append-only）
├── guides/                     #team note + commit-push Step 10 經驗指南
├── handoff/                    #team handoff（含 YYMMDD_ai-context/ 子目錄）
├── modify_log/                 #commit-push Step 5（Haiku 內嵌產出）
├── report/                     #team report --daily
└── .history/                   #refactor.jsonl + 邊界規則 README.md

.local/                         ← 機器專屬狀態（不入版控）
├── docs/
│   └── plan/                   #build plan（單次實作工作檔）
├── context_summary/            ← clean 摘要與 current_topic.md
├── bag/                        ← skm pack 打包結果（Skill 退出歸檔專用）
├── resumption_prompt.md        ← clean 一次性恢復檔（注入後刪除）
└── model_dispatch.log          ← Agent 派遣稽核軌跡

專案根/
└── TODO.md                     ← team todo + build do 衍生任務
```

---

## 備註

- `.local/` 整個目錄由 `.gitignore` 排除，不入專案版控
- `.hanschen/` 由專案 git 追蹤；是否 push 至公開分支由使用者決定
- 目錄由各 Skill 首次使用時自動建立
- `/team report --daily` 依賴 `.hanschen/modify_log/` 的內容來生成報告
- `/skm pack` 會收集 `.local/bag/` 與 `.hanschen/` 重要文件打包供新專案還原
- 路徑歷史與邊界規則的權威來源：`.hanschen/.history/README.md`

## v2.4 變更記錄（2026-05-08）

- **路徑扁平化**：`.hanschen/docs/{board,decision,living,guides,handoff}/` → `.hanschen/{board,decision,journal,guides,handoff}/`（移除 `docs/` 中介層）
- **living → journal**：對齊 `/team journal` 子命令名（2026-04-24 已改名，現一併改路徑）
- 移除過時的 `.local/docs/{summary,tech-note,guide,knowledge}/` 引用（早已遷至 `.hanschen/` 或合併入 handbook/）

## v2.2 變更記錄（2026-04-15）

- 子目錄統一**名詞單數**：`plans → plan`、`decisions → decision`、`summaries → summary`、`whiteboards → whiteboard`、`tech-notes → tech-note`、`guides → guide`、`modify_logs → modify_log`、`reports → report`
- 新增 `.local/samples/` 慣例：使用者提供的參考樣本統一存放位置
- 清除 `.hanschen/modify_log/` 中原用於格式參考的 48 份歷史樣本（依 §1.4.d 決策）

## v2.1 變更記錄（2026-04-15 先前）

- `.local/summary/` → `.local/context_summary/`（明確名）
- `.local/asks/` → `.local/docs/knowledge/`（併入 docs/ 大目錄）
- `.local/docs/` 散落 guide → `.local/docs/guide/`（明確子目錄）
- 確立 `.local/docs/` = 人讀文件 vs `.local/` 根 = AI 運維紀錄 的語義分層
