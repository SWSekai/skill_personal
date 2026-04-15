# Skill 文件產出參考表

> 所有 Skill 會自動產生的文件、觸發時機、存放位置、用途一覽。
>
> Last updated: 2026-04-15（v2.1 統一路徑方案）

---

## 命名原則（對齊 CLAUDE.md）

- **`.local/docs/` = 給人讀的文件**（plans、decisions、summaries、whiteboards、tech-notes、guides、knowledge）
- **`.local/` 根 = AI 運維紀錄**（modify_logs、context_summary、reports、collab、ai-context）
- 所有子目錄使用**名詞複數**（plans / decisions / summaries / whiteboards / modify_logs / guides）
- 例外：`tech-notes`（已是名詞形式）、`ai-context`（pack 產出）、`knowledge`（抽象名詞）

---

## 本地工作紀錄（不入版控，在 `.local/` 下）

### 給人讀的文件（`.local/docs/`）

| Skill | 子命令 / 步驟 | 觸發時機 | 檔名格式 | 存放位置 | 用途 |
|---|---|---|---|---|---|
| **build** | `plan` | 方案設計完成 | `YYMMDD_<feature>.md` | `.local/docs/plans/` | 實作方案文件（含 checkbox 步驟清單）|
| **team-office** | `decide` | 手動觸發 | `<topic>.md` | `.local/docs/decisions/` | 互動式決策表（執行後刪除，摘要留 summaries）|
| **team-office** | `decide` Step 6 | 決策執行完成 | `YYMMDD_<topic>_summary.md` | `.local/docs/summaries/` | 決策摘要（永久保留，含非單一路線的保留候選）|
| **team-office** | `board` | 手動觸發 | `YYMMDD_<topic>.md` | `.local/docs/whiteboards/` | 白板討論紀錄（不刪除）|
| **team-office** | `notes` | 手動觸發 | `<topic>.md` | `.local/docs/tech-notes/` | 技術問答結構化筆記 |
| **commit-push** | Step 10 | commit 後若含踩坑經驗 | `<topic>.md` | `.local/docs/guides/` | 實戰經驗指南（症狀→原因→解法→注意事項）|
| **ask** | `query` | 自動（查詢時）/ 手動 | `<topic_description>.md` | `.local/docs/knowledge/` | 系統知識庫（架構、資料流、設定）|

### AI 運維紀錄（`.local/` 根）

| Skill | 子命令 / 步驟 | 觸發時機 | 檔名格式 | 存放位置 | 用途 |
|---|---|---|---|---|---|
| **commit-push** | Step 5 | commit 後（Haiku 內嵌）| `YYMMDD_<主題>.md` | `.local/modify_logs/` | 修改日誌（格式對齊原版 +N -M）|
| **context-guard** | 系統壓縮 / 手動 / 對話開始 | — | `YYMMDD_HHMM_<主題>.md` | `.local/context_summary/` | Context 工作狀態摘要 |
| **context-guard** | 同上 | — | `current_topic.md` | `.local/context_summary/` | 當前工作主題（任務切換偵測）|
| **ask** | `report` | 手動 `/ask report` | `YYMMDD_<type>_report.md` | `.local/reports/` | 從 modify_logs 統整的工作報告（簡報用）|
| **team-office** | `todo` | 手動 `/team-office todo` | `TODO.md` | `.local/collab/` | AI 待辦事項清單 |
| **build** | `impl` | 衍生任務時 | 追加至 TODO.md | `.local/collab/` | 從 impl 發現的衍生 TODO |
| **setup** | `pack` | 手動 `/setup pack` | 打包結果 + `manifest.txt` | `.local/ai-context/` | AI 上下文打包（含 memory、guides、project-skills）|

---

## 入版控文件

| Skill | 觸發時機 | 產出檔案 | 存放位置 | 用途 |
|---|---|---|---|---|
| **commit-push** | Step 2 | `README.md` | 變更目錄下 | 自動更新目錄說明文件 |

---

## Skill / 設定檔（由 setup 管理）

| Skill | 觸發時機 | 產出 | 存放位置 | 用途 |
|---|---|---|---|---|
| **setup** | `sync` 或對話開始 | `SKILL.md` + `README.md` | `.claude/skills/<name>/` | 同步 sekai-workflow 至專案 |
| **setup** | `new` | `SKILL.md` + `README.md` | `.claude/skills/<name>/` + `sekai-workflow/<name>/` | 建立新 Skill 定義 |

---

## Memory 相關（非 `.local/`）

| 類型 | 存放位置 | 管理者 |
|---|---|---|
| 專案 Memory | `~/.claude/projects/<encoded-path>/memory/` | auto memory system + `memory_skill_sync` hook |
| 跨專案 Portable Memory | `sekai-workflow/memory-portable/` | `/setup pack` 回寫 + `sp-init.bat` Step 8 還原 |

---

## 目錄結構總覽

```
.local/
├── docs/                       ← 給人讀的文件
│   ├── plans/                  #build plan
│   ├── decisions/              #team-office decide（一次性，執行後刪除）
│   ├── summaries/              #team-office decide 執行後持久化（永久）
│   ├── whiteboards/            #team-office board
│   ├── tech-notes/             #team-office notes
│   ├── guides/                 #commit-push Step 10 經驗指南
│   └── knowledge/              #ask query 系統知識庫
│
├── modify_logs/                ← commit-push Step 5（Haiku 內嵌產出）
├── context_summary/            ← context-guard 摘要與 current_topic.md
├── reports/                    ← ask report
├── collab/
│   └── TODO.md                 ← team-office todo + build impl 衍生任務
└── ai-context/                 ← setup pack 打包結果（含 memory 子目錄）
```

---

## 備註

- `.local/` 整個目錄由 `.gitignore` 排除，不入專案版控
- 目錄由各 Skill 首次使用時自動建立
- `/ask report` 依賴 `.local/modify_logs/` 的內容來生成報告
- `/setup pack` 會收集 `.local/` 下所有子目錄打包至 `.local/ai-context/`
- `/setup pack` 另外收集 Memory 至 `.local/ai-context/memory/`，由 `sp-init.bat` Step 8b 自動還原

## v2.1 變更記錄

- `.local/summary/` → `.local/context_summary/`（明確名）
- `.local/asks/` → `.local/docs/knowledge/`（併入 docs/ 大目錄）
- `.local/docs/` 散落 guide → `.local/docs/guides/`（明確子目錄）
- `modify_log/modify_log/*` → `.local/modify_logs/`（48 份歷史實例遷入）
- 確立 `.local/docs/` = 人讀文件 vs `.local/` 根 = AI 運維紀錄 的語義分層
