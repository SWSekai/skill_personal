# Skill 文件產出參考表

> 所有 Skill 會自動產生的文件、觸發時機、存放位置、用途一覽。
>
> Last updated: 2026-04-15（v2.2 單數命名 + samples 慣例）

---

## 命名原則（對齊 CLAUDE.md）

- **`.local/docs/` = 給人讀的文件**（plan、decision、summary、whiteboard、tech-note、guide、knowledge）
- **`.local/` 根 = AI 運維紀錄**（modify_log、context_summary、report、collab、samples、ai-context）
- 所有子目錄使用**名詞單數**（plan / decision / summary / whiteboard / tech-note / guide / modify_log / report）
- 例外：`knowledge`（抽象名詞）、`context_summary`（固有名）、`ai-context`（固有名）、`collab`（縮寫）

---

## 本地工作紀錄（不入版控，在 `.local/` 下）

### 給人讀的文件（`.local/docs/`）

| Skill | 子命令 / 步驟 | 觸發時機 | 檔名格式 | 存放位置 | 用途 |
|---|---|---|---|---|---|
| **build** | `plan` | 方案設計完成 | `YYMMDD_<feature>.md` | `.local/docs/plan/` | 實作方案文件（含 checkbox 步驟清單）|
| **team-office** | `decide` | 手動觸發 | `<topic>.md` | `.local/docs/decision/` | 互動式決策表（執行後刪除，摘要留 summary）|
| **team-office** | `decide` Step 6 | 決策執行完成 | `YYMMDD_<topic>_summary.md` | `.local/docs/summary/` | 決策摘要（永久保留，含非單一路線的保留候選）|
| **team-office** | `board` | 手動觸發 | `YYMMDD_<topic>.md` | `.local/docs/whiteboard/` | 白板討論紀錄（不刪除）|
| **team-office** | `notes` | 手動觸發 | `<topic>.md` | `.local/docs/tech-note/` | 技術問答結構化筆記 |
| **commit-push** | Step 10 | commit 後若含踩坑經驗 | `<topic>.md` | `.local/docs/guide/` | 實戰經驗指南（症狀→原因→解法→注意事項）|
| **ask** | `query` | 自動（查詢時）/ 手動 | `<topic_description>.md` | `.local/docs/knowledge/` | 系統知識庫（架構、資料流、設定）|
| **team-office** | `handoff` | 手動（下班 / 休假前）| `YYMMDD_handoff.md` | `.local/docs/handoff/`（預設）或 `docs/handoff/`（`--share`）| 人類交接文件（進度 + 環境 + 待辦 + 恢復指引）|
| **team-office** | `handoff` Step 3 | 同上 | `YYMMDD_ai-context/` 目錄 | 同上（子目錄）| AI context bundle（CLAUDE.md + memory + 決策摘要 + guide + modify_log + TODO）|

### AI 運維紀錄（`.local/` 根）

| Skill | 子命令 / 步驟 | 觸發時機 | 檔名格式 | 存放位置 | 用途 |
|---|---|---|---|---|---|
| **commit-push** | Step 5 | commit 後（Haiku 內嵌）| `YYMMDD_<主題>.md` | `.local/modify_log/` | 修改日誌（格式對齊原版 +N -M）|
| **clean** | 系統壓縮 / 手動 `/clean` / 對話開始 | — | `YYMMDD_HHMM_<主題>.md` | `.local/context_summary/` | Context 工作狀態摘要（繼承 context-guard 功能）|
| **clean** | 同上 | — | `current_topic.md` | `.local/context_summary/` | 當前工作主題（任務切換偵測）|
| **team** | `report` | 手動 `/team report` 或 commit-push Step 11 自動 | `YYMMDD_daily_report.md` | `.local/report/` | 每日 Teams 報告（原 `/ask report`） |
| **team** | `todo` | 手動 `/team todo` | `TODO.md` | `.local/collab/` | AI 待辦事項清單（原 team-office）|
| **build** | `impl` | 衍生任務時 | 追加至 TODO.md | `.local/collab/` | 從 impl 發現的衍生 TODO |
| （使用者手動） | — | 需要時提供範例 | `<類別>/*.md` | `.local/samples/` | 使用者提供的參考樣本（格式模板、範例檔等）|
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
.local/
├── docs/                       ← 給人讀的文件
│   ├── plan/                   #build plan
│   ├── decision/               #team-office decide（一次性，執行後刪除）
│   ├── summary/                #team-office decide 執行後持久化（永久）
│   ├── whiteboard/             #team-office board
│   ├── tech-note/              #team-office notes
│   ├── guide/                  #commit-push Step 10 經驗指南
│   ├── knowledge/              #ask query 系統知識庫
│   └── handoff/                #team-office handoff
│       ├── YYMMDD_handoff.md   #人類交接文件
│       └── YYMMDD_ai-context/  #AI context bundle
│
├── modify_log/                 ← commit-push Step 5（Haiku 內嵌產出）
├── context_summary/            ← clean（繼承 context-guard）摘要與 current_topic.md
├── report/                     ← team report --daily
├── collab/
│   └── TODO.md                 ← team todo + build impl 衍生任務
├── samples/                    ← 使用者提供的參考樣本（按需建立）
└── bag/                        ← skm pack 打包結果（Skill 退出歸檔專用）
```

---

## 備註

- `.local/` 整個目錄由 `.gitignore` 排除，不入專案版控
- 目錄由各 Skill 首次使用時自動建立
- `/ask report` 依賴 `.local/modify_log/` 的內容來生成報告
- `/skm pack` 會收集 `.local/` 下所有子目錄打包至 `.local/ai-context/`
- `/skm pack` 另外收集 Memory 至 `.local/ai-context/memory/`，由 `sp-init.bat` Step 8b 自動還原
- `.local/samples/` 是樣本專用資料夾：當使用者需要提供格式範例、模板參考時，統一丟到此目錄，AI 需要範例時只從這裡找

## v2.2 變更記錄（2026-04-15）

- 子目錄統一**名詞單數**：`plans → plan`、`decisions → decision`、`summaries → summary`、`whiteboards → whiteboard`、`tech-notes → tech-note`、`guides → guide`、`modify_logs → modify_log`、`reports → report`
- 新增 `.local/samples/` 慣例：使用者提供的參考樣本統一存放位置
- 清除 `.local/modify_log/` 中原用於格式參考的 48 份歷史樣本（依 §1.4.d 決策）

## v2.1 變更記錄（2026-04-15 先前）

- `.local/summary/` → `.local/context_summary/`（明確名）
- `.local/asks/` → `.local/docs/knowledge/`（併入 docs/ 大目錄）
- `.local/docs/` 散落 guide → `.local/docs/guide/`（明確子目錄）
- 確立 `.local/docs/` = 人讀文件 vs `.local/` 根 = AI 運維紀錄 的語義分層
