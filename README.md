# Claude Code General Skills — 通用自動化指令集

A portable set of Claude Code skills that work with **any project**. No project-specific logic — just copy into your `.claude/skills/` directory.

通用版 Claude Code Skill，不含任何專案相關邏輯，可直接複製到任何專案的 `.claude/skills/` 目錄使用。

> **2026-04-10 重構**：原本 17 個獨立 Skill 已合併為 **6 個**（4 個子命令式 + 2 個獨立），透過子命令路由保留所有原有職能。

---

## 版控邊界（重要）

**所有 Skill 相關檔案不屬於專案版控：**

| 路徑 | 版控歸屬 | 說明 |
|------|---------|------|
| `.claude/skills/` | 不入版控 | 專案專屬 Skill，僅本地使用 |
| `.skill_personal/` | **本倉庫** | 通用 Skill 模板，透過本遠端倉庫管理 |
| `CLAUDE.md` | 不入版控 | Claude Code 專案規範，僅本地使用 |
| 修改日誌目錄 | 不入版控 | 本地工作紀錄 |

**原則：**
- 專案 git 僅追蹤專案程式碼，所有 Claude Code 相關檔案皆為本地或個人倉庫管理
- **禁止使用 `git add -f`**：所有在 `.gitignore` 中的檔案一律不得以任何方式加入專案版控
- 修改日誌僅存放於本地，不加入任何 git 版控

---

## Skill 同步規則

### 規則 1：導入專案時自動建置專案專屬 Skill

當將本資料夾的 Skill 導入新專案時：

1. 檢查該專案是否已有 `.claude/skills/` 資料夾
2. 若**無**專案專屬 Skill → 自動複製一份至 `.claude/skills/`，並根據專案特性進行客製化調整
3. 若**已有**專案專屬 Skill → 比對通用版與專案版差異，將通用版的新功能或修正合併至專案版
4. **`.skill_personal` 僅作為通用模板**，不直接作為專案執行用 Skill
5. **確保 `.gitignore` 排除 `CLAUDE.md`、`.claude/skills/`、`.skill_personal/`、修改日誌目錄**

### 規則 2：專案 Skill 更新回流至通用版

- **通用性改進** → 同步更新回 `.skill_personal/` 及遠端倉庫
- **專案特化修正** → 不回流，僅保留在專案 `.claude/skills/`
- 回流時移除所有專案特定的硬編碼

### 規則 3：自動同步至遠端倉庫

- **遠端**：`https://github.com/SWSekai/Skill-personal.git`
- **本地**：專案內的 `.skill_personal/`（自身為 git repo）
- **時機**：每次 `.skill_personal/` 有變更時，stage、commit、push

### 規則 4：新專案自動初始化

進入新專案時：
1. 檢查是否存在 `.skill_personal/`
2. 若存在但專案無 `.claude/skills/` → 從模板複製
3. 根據專案特性客製化
4. 若 `.skill_personal/` 尚未初始化 → `git init` + `git remote add origin`

### 規則 5：對話開始自動同步遠端

- `git fetch origin` → 比較 → `git pull --rebase` → 衝突揉合 → `git push`

---

## Installation / 安裝

### 方法 1：一鍵建置（推薦）

```bash
# 在目標專案中執行
D:\git\Skill-personal\setup\sp-init.bat
```

sp-init.bat 自動完成：
1. 建立 `.claude/skills/` 並複製所有 Skill
2. 建立 `.skill_personal/` 作為通用模板同步用
3. 生成 `CLAUDE.md` 專案規範
4. 安裝 pre-commit hook（防止 Skill 誤入專案版控）

---

## Skills Overview / 指令一覽

| Skill | Command | Model | Description |
|---|---|:---:|---|
| **dev** | `/dev <commit\|quality\|log\|restart\|eval>` | sonnet | 開發流程：commit-push、品質檢查、修改日誌、容器重啟評估與執行 |
| **collab** | `/collab <todo\|board\|decide\|notes>` | sonnet | 互動協作：AI TODO、即時白板、Markdown 決策表、技術筆記 |
| **skill** | `/skill <new\|sync\|pack>` | sonnet | Skill 環境管理：建立新 Skill、遠端同步、專案打包 |
| **doc** | `/doc <info\|trace\|report>` | opus | 系統文件與報告：系統資訊、資料流追蹤、工作報告 |
| **context-guard** | `/context-guard` | sonnet | Context Window 管理（系統壓縮、手動、對話開始） |
| **memory-portable** | `/memory-portable` | sonnet | Memory 跨專案攜帶 |

---

## 詳細說明

### `/dev` — 開發流程合併

整合原 `commit-push` + `quality-check` + `modify-log` + `restart-eval` + `restart-volumn`。

| 子命令 | 用途 |
|---|---|
| `/dev commit [msg]` | 完整提交流程（品質檢查 → 日誌 → README → commit → push → 重啟評估） |
| `/dev quality [files]` | 獨立品質審計 |
| `/dev log [topic]` | 建立 / 更新本地修改日誌（僅本地） |
| `/dev restart [services]` | 容器重啟與自動修復 |
| `/dev eval [range]` | 重啟評估（不執行） |

### `/collab` — 互動協作合併

整合原 `todo` + `whiteboard` + `md-collab` + `tech-notes`。

| 子命令 | 用途 |
|---|---|
| `/collab todo [add\|list\|<n>]` | 處理 AI TODO 清單 |
| `/collab board [topic]` | 即時白板（諮詢、規劃類對話自動觸發） |
| `/collab decide <topic>` | Markdown 互動式決策表（核取／填寫） |
| `/collab notes [topic]` | 結構化技術筆記 |

### `/skill` — Skill 環境管理合併

整合原 `create-skill` + `skill-sync` + `pack`。

| 子命令 | 用途 |
|---|---|
| `/skill new [name] [desc]` | 互動式建立新 Skill |
| `/skill sync` | `.skill_personal/` 遠端同步、規則評估 |
| `/skill pack` | 專案打包並清除 skill 環境 |

### `/doc` — 系統文件與報告合併

整合原 `sys-info` + `trace-flow` + `report`。

| 子命令 | 用途 |
|---|---|
| `/doc info [topic]` | 系統資訊查詢與文件管理（自動觸發於系統相關問題） |
| `/doc trace <field>` | 端到端資料流追蹤 |
| `/doc report [scope]` | 從修改紀錄生成簡報用工作報告 |

### `/context-guard` — Context Window 管理

監控 context window 使用狀況，系統壓縮通知時自動摘要、手動呼叫整理、對話開始恢復。

### `/memory-portable` — Memory 跨專案攜帶

協助 Memory 規則在不同專案之間攜帶與整理。

---

## 文件存放位置總覽

所有 Skill 產生的本地工作文件皆存放於 `.local/` 下，由 `.gitignore` 排除，不入專案版控。

### 本地工作文件（不入版控）

```
.local/
├── modify_logs/   ← /dev log（含 /dev commit、/dev restart 報告）
├── docs/          ← /doc info、/doc trace、/collab board、/collab decide、/collab notes
│   ├── whiteboards/
│   ├── decisions/
│   └── tech-notes/
├── summary/       ← /context-guard
├── reports/       ← /doc report
├── collab/        ← /collab todo（TODO.md）
└── ai-context/    ← /skill pack 打包輸出
```

### 入版控文件

| 場景 | 檔案說明 | 存放位置 |
|---|---|---|
| `/dev commit` | 目錄 README.md 自動更新 | 變更目錄下的 README.md |

### Skill 設定檔（由 `/skill sync` 管理）

| 檔案 | 位置 | 備註 |
|---|---|---|
| 各 SKILL.md | `.claude/skills/<name>/SKILL.md` | 同步至 `.skill_personal` 遠端 |
| `CLAUDE.md` 規則 | 專案根目錄 | 僅在規則評估需要時更新 |

### 僅控制台輸出（不存檔）

| 子命令 | 輸出內容 |
|---|---|
| `/dev quality` | Risk Report 表格（Severity / File / Mitigation） |
| `/doc trace` | 端到端資料流表格（Layer / File:Line / Variable / Type / Risk） |
| `/dev eval` | 服務重啟分類 + 執行指令清單 |
| `/dev restart` | 重啟報告（Service / Action / Status / Duration） |

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
.skill_personal/
├── README.md                   ← This file
├── manifest.json               ← Skill 結構索引（含 model 分配）
├── references/
│   └── model-routing.md
│
├── setup/                      ← 建置與基礎設施
│   ├── sp-init.bat / sp-sync.sh / sp-verify.bat / sp-pack.sh
│   ├── hooks/pre-commit
│   └── templates/CLAUDE.md.template
│
├── docs/QUICKSTART.md          ← 快速上手指南
│
├── dev/                        ← [sonnet] 開發流程合併
│   ├── SKILL.md
│   └── README.md
├── collab/                     ← [sonnet] 互動協作合併
│   ├── SKILL.md
│   └── README.md
├── skill/                      ← [sonnet] Skill 環境管理合併
│   ├── SKILL.md
│   └── README.md
├── doc/                        ← [opus] 系統文件與報告合併
│   ├── SKILL.md
│   └── README.md
├── context-guard/              ← [sonnet] Context Window 管理
│   ├── SKILL.md
│   └── README.md
└── memory-portable/            ← [sonnet] Memory 跨專案攜帶
    ├── SKILL.md
    └── README.md
```

---

## 重構對應表（17 → 6）

| 原 Skill | 新位置 |
|---|---|
| commit-push | `/dev commit` |
| quality-check | `/dev quality` |
| modify-log | `/dev log` |
| restart-volumn | `/dev restart` |
| restart-eval | `/dev eval` |
| todo | `/collab todo` |
| whiteboard | `/collab board` |
| md-collab | `/collab decide` |
| tech-notes | `/collab notes` |
| create-skill | `/skill new` |
| skill-sync | `/skill sync` |
| pack | `/skill pack` |
| sys-info | `/doc info` |
| trace-flow | `/doc trace` |
| report | `/doc report` |
| context-guard | `/context-guard`（保持獨立） |
| memory-portable | `/memory-portable`（保持獨立） |
