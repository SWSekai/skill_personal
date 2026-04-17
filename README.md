# Sekai_workflow — Claude Code 通用自動化指令集

A portable set of Claude Code skills that work with **any project**. No project-specific logic — just copy into your `.claude/skills/` directory.

通用版 Claude Code Skill，不含任何專案相關邏輯，可直接複製到任何專案的 `.claude/skills/` 目錄使用。

> **2026-04-10 重構**：原本 17 個獨立 Skill 合併為 **6 個**（4 個子命令式 + 2 個獨立），透過子命令路由保留所有原有職能。`skill_personal` 更名為 `Sekai_workflow`，基礎設施目錄由 `setup/` 改為 `_bootstrap/`。

---

## 版控邊界（重要）

**所有 Skill 相關檔案不屬於專案版控：**

| 路徑 | 版控歸屬 | 說明 |
|------|---------|------|
| `.claude/skills/` | 不入版控 | 專案專屬 Skill，僅本地使用 |
| `Sekai_workflow/` | **本倉庫** | 通用 Skill 模板，透過本遠端倉庫管理 |
| `CLAUDE.md` | 不入版控 | Claude Code 專案規範，僅本地使用 |
| 修改日誌目錄 | 不入版控 | 本地工作紀錄 |

**原則：**
- 專案 git 僅追蹤專案程式碼，所有 Claude Code 相關檔案皆為本地或個人倉庫管理
- **禁止使用 `git add -f`**：所有在 `.gitignore` 中的檔案一律不得以任何方式加入專案版控
- 修改日誌僅存放於本地，不加入任何 git 版控

---

## Skill 同步規則

### 規則 1：導入專案時自動建置專案專屬 Skill

1. 檢查該專案是否已有 `.claude/skills/` 資料夾
2. 若**無** → 自動複製至 `.claude/skills/`，根據專案特性客製化
3. 若**已有** → 比對差異，合併新功能
4. **`Sekai_workflow/` 僅作為通用模板**，不直接作為專案執行用 Skill
5. **確保 `.gitignore` 排除 `CLAUDE.md`、`.claude/skills/`、`Sekai_workflow/`、`.local/`**

### 規則 2：專案 Skill 更新回流至通用版

- **通用性改進** → 同步更新回 `Sekai_workflow/` 及遠端倉庫
- **專案特化修正** → 不回流，僅保留在 `.claude/skills/`
- 回流時移除所有專案特定的硬編碼

### 規則 3：自動同步至遠端倉庫

- **遠端**：`https://github.com/SWSekai/sekai-workflow.git`
- **本地**：專案內的 `Sekai_workflow/`（自身為 git repo）
- **時機**：每次 `Sekai_workflow/` 有變更時，stage、commit、push

### 規則 4：新專案自動初始化

進入新專案時：
1. 檢查是否存在 `Sekai_workflow/`
2. 若存在但專案無 `.claude/skills/` → 從模板複製
3. 根據專案特性客製化
4. 若 `Sekai_workflow/` 尚未初始化 → `git init` + `git remote add origin`

### 規則 5：對話開始自動同步遠端

- `git fetch origin` → 比較 → `git pull --rebase` → 衝突揉合 → `git push`

---

## Installation / 安裝

### 方法 1：一鍵建置（推薦）

```cmd
REM 在目標專案根目錄開啟 cmd 執行（資料夾名為 sekai-workflow，小寫+連字號）
sekai-workflow\_bootstrap\sp-init.bat

REM 或從任意位置帶目標路徑執行
D:\path\to\sekai-workflow\_bootstrap\sp-init.bat D:\your-project
```

> ⚠️ 請勿在 `sekai-workflow\` 或其子目錄（例如 `_bootstrap\`）內雙擊執行，
> 腳本會偵測到並以錯誤碼結束；若是雙擊執行，視窗會立即關閉看不到訊息。

> ℹ️ 首次執行完成後，`sekai-workflow\` 會被自動更名為 `.sekai-workflow\`（直接 rename，不複製）。
> 後續若要重跑請改用 `.sekai-workflow\_bootstrap\sp-init.bat`。

sp-init.bat 自動完成：
1. 建立 `.claude/skills/` 並複製所有 Skill
2. 建立 `Sekai_workflow/` 作為通用模板同步用
3. 生成 `CLAUDE.md` 專案規範
4. 安裝 pre-commit hook（防止 Skill 誤入專案版控）

---

## Skills Overview / 指令一覽

| Skill | Command | Model | Description |
|---|---|:---:|---|
| **hello** | `/hello` | sonnet | 對話初始化：拉取更新 + Skill 同步 + context 恢復 + 狀態總覽 |
| **build** | `/build <all\|plan\|do\|test\|check\|review\|deploy>` | sonnet | 開發全流程：需求分析 → 方案設計 → 實作 → 測試 → 品質檢查 → review → 部署驗證 |
| **team** | `/team <todo\|board\|decide\|note\|handoff\|report>` | sonnet | 互動協作：AI TODO、即時白板、Markdown 決策表、技術筆記、交接文件、工作報告 |
| **skill** | `/skill <new\|sync\|pack>` | sonnet | Skill 環境管理：建立新 Skill、規則評估、專案打包 |
| **ask** | `/ask <info\|trace>` | opus | 系統文件追蹤：系統資訊查詢、資料流追蹤 |
| **clean** | `/clean [check\|force]` | sonnet | Context 清理入口：繼承 context-guard 所有功能，清理舊摘要後執行 /clear，Stop hook 自動提醒 |
| **memory-portable** | `/memo` | sonnet | Memory 跨專案攜帶 |
| **commit-push** | `/commit-push [msg]` | sonnet | 獨立 commit & push 入口（品質檢查 → 日誌 → commit → push → deploy 評估）|

---

## 詳細說明

### `/build` — 開發全流程

整合需求分析、方案設計、實作引導、測試驗證、品質審計、review、部署評估。

| 子命令 | 用途 |
|---|---|
| `/build all <feature>` | **全流程串接**：plan → do → test |
| `/build plan <feature>` | 需求分析 + 方案設計 + 步驟拆解（Opus） |
| `/build do [plan-ref]` | 按方案逐步實作，checkbox 勾對進度 |
| `/build test [scope]` | 測試驗證（自動 + 手動 checklist） |
| `/build check [files]` | 獨立品質審計（Opus） |
| `/build review` | commit 前互動式人工確認 checklist |
| `/build deploy [--plan\|--run]` | 部署評估：plan 階段（分類 + 計畫，不執行）；run 階段（重啟 + 健康檢查 + 自動修復） |

> **2026-04-17 清理**：移除已合併的 4 個舊子命令 — `/build commit` 由 `/commit-push` 接手；`/build log` 為 `/commit-push` Step 5 內嵌 Haiku 產出；`/build restart` = `/build deploy --run`、`/build eval` = `/build deploy --plan`。

### `/team` — 互動協作

整合原 `todo` + `whiteboard` + `md-collab` + `tech-notes`。

| 子命令 | 用途 |
|---|---|
| `/team todo [add\|list\|<n>]` | 處理 AI TODO 清單 |
| `/team board [topic]` | 即時白板（諮詢、規劃類對話自動觸發） |
| `/team decide <topic>` | Markdown 互動式決策表（核取／填寫） |
| `/team note [topic]` | 結構化技術筆記 |

### `/skill` — Skill 環境管理

整合原 `create-skill` + `skill-sync` + `pack`。

| 子命令 | 用途 |
|---|---|
| `/skill new [name] [desc]` | 建立新 Skill |
| `/skill sync` | `Sekai_workflow/` 遠端同步、規則評估 |
| `/skill pack` | 專案打包並清除 skill 環境 |

### `/ask` — 系統文件與資料流追蹤

整合原 `sys-info` + `trace-flow`（原 `report` 子命令已搬移至 `/team report`）。

| 子命令 | 用途 |
|---|---|
| `/ask info [topic]` | 系統資訊查詢與文件管理（系統相關問題時自動觸發） |
| `/ask trace <field>` | 端到端資料流追蹤 |

### `/clean` — Context 清理入口

繼承 `context-guard` 所有功能（摘要生成、任務切換偵測、摘要恢復），新增：清理舊摘要後執行 `/clear`、Stop hook 偵測舊摘要時提醒使用者。

| 參數 | 說明 |
|------|------|
| `/clean` | 完整流程：摘要 → 清舊摘要 → /clear |
| `/clean check` | 僅檢查狀態 |
| `/clean force` | 跳過 commit 確認 |

### `/memo` — Memory 跨專案攜帶

協助 Memory 規則在不同專案之間攜帶與整理。

---

## 文件存放位置總覽

所有 Skill 產生的本地工作文件皆存放於 `.local/` 下，由 `.gitignore` 排除，不入專案版控。

### 本地工作文件（不入版控）

```
.local/
├── modify_log/       ← /commit-push Step 5（Haiku 內嵌產出）
├── docs/             ← 給人讀的文件（ask / team / commit-push guide）
│   ├── plan/         ← /build plan
│   ├── decision/     ← /team decide（一次性，執行後刪除）
│   ├── summary/      ← /team decide 執行後持久化（永久）
│   ├── whiteboard/   ← /team board
│   ├── tech-note/    ← /team note
│   ├── guide/        ← /commit-push Step 10 經驗指南
│   └── knowledge/    ← /ask info 系統知識庫
├── context_summary/  ← /clean 摘要 + current_topic.md
├── report/           ← /team report
├── collab/           ← /team todo（TODO.md）
├── samples/          ← 使用者提供的參考樣本（按需建立）
└── ai-context/       ← /skill pack 打包輸出
```

### 入版控文件

| 場景 | 檔案說明 | 存放位置 |
|---|---|---|
| `/build commit` | 目錄 README.md 自動更新 | 變更目錄下的 README.md |

### Skill 設定檔（由 `/skill sync` 管理）

| 檔案 | 位置 | 備註 |
|---|---|---|
| 各 SKILL.md | `.claude/skills/<name>/SKILL.md` | 同步至 `Sekai_workflow` 遠端 |
| `CLAUDE.md` 規則 | 專案根目錄 | 僅在規則評估需要時更新 |

### 僅控制台輸出（不存檔）

| 子命令 | 輸出內容 |
|---|---|
| `/build check` | Risk Report 表格（Severity / File / Mitigation） |
| `/ask trace` | 端到端資料流表格（Layer / File:Line / Variable / Type / Risk） |
| `/build eval` | 服務重啟分類 + 執行指令清單 |
| `/build restart` | 重啟報告（Service / Action / Status / Duration） |

---

## Customization / 客製化

These skills are designed to be project-agnostic. To customize for a specific project:

1. Copy to `.claude/skills/` in your project
2. Edit the `SKILL.md` files to add project-specific:
   - Directory paths
   - Service names and container topology
   - Commit message conventions
   - Language preferences

---

## Directory Structure / 目錄結構

```
Sekai_workflow/
├── README.md                   ← 本文件
├── manifest.json               ← Skill 結構索引（含 model 分配、合併對照表）
├── references/
│   └── model-routing.md        ← Model routing 共用規則
│
├── _bootstrap/                 ← 建置與基礎設施
│   ├── sp-init.bat / sp-sync.sh / sp-verify.bat / sp-pack.sh
│   ├── hooks/pre-commit
│   └── templates/CLAUDE.md.template
│
├── docs/                       ← 使用者文件
│   ├── QUICKSTART.md
│   └── file-output-reference.md
│
├── hooks/                      ← Claude Code hooks
│   ├── check_skill_sync.cjs
│   ├── check_yn_question.cjs
│   ├── check_context_reminder.cjs
│   └── memory_skill_sync.cjs
│
├── build/                      ← [sonnet] 開發全流程
│   ├── SKILL.md
│   ├── README.md
│   └── references/
│       ├── commit-conventions.md
│       ├── gitignore-safety.md
│       ├── severity-guide.md
│       ├── error-recovery.md
│       └── log-keywords.md
│
├── team/                       ← [sonnet] 互動協作
│   ├── SKILL.md
│   ├── README.md
│   ├── references/
│   │   └── interaction-modes.md
│   └── assets/
│       ├── collab-template.md
│       └── whiteboard-template.md
│
├── skill/                      ← [sonnet] Skill 環境管理
│   ├── SKILL.md
│   ├── README.md
│   ├── references/
│   │   ├── model-selection-guide.md
│   │   ├── evaluation-decision-tree.md
│   │   └── version-control-boundaries.md
│   └── assets/
│       ├── SKILL.md.template
│       └── README.md.template
│
├── ask/                        ← [opus] 系統文件與報告
│   ├── SKILL.md
│   └── README.md
│
├── clean/                      ← [sonnet] Context 清理入口（繼承 context-guard）
│   ├── SKILL.md
│   └── README.md
│
└── memo/                       ← [sonnet] Memory 跨專案攜帶
    ├── SKILL.md
    ├── README.md
    └── feedback_*.md           ← 可攜帶的 feedback memory
```

---

## 重構對應表（17 → 6）

| 原 Skill | 新位置 |
|---|---|
| commit-push | `/build commit` |
| quality-check | `/build check` |
| modify-log | `/build log` |
| restart-volumn | `/build restart` |
| restart-eval | `/build eval` |
| todo | `/team todo` |
| whiteboard | `/team board` |
| md-collab | `/team decide` |
| tech-notes | `/team note` |
| create-skill | `/skill new` |
| skill-sync | `/skill sync` |
| pack | `/skill pack` |
| sys-info | `/ask info` |
| trace-flow | `/ask trace` |
| report | `/team report` |
| context-guard | `/clean`（合併至 clean，含 /clear 整合） |
| memory-portable | `/memo`（保持獨立） |
