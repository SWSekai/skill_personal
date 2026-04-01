# Claude Code General Skills — 通用自動化指令集

A portable set of Claude Code skills that work with **any project**. No project-specific logic — just copy into your `.claude/skills/` directory.

通用版 Claude Code Skill，不含任何專案相關邏輯，可直接複製到任何專案的 `.claude/skills/` 目錄使用。

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
2. 若**無**專案專屬 Skill → 自動複製一份至 `.claude/skills/`，並根據專案特性進行客製化調整（如：修改日誌路徑、服務名稱、commit 慣例、語言偏好）
3. 若**已有**專案專屬 Skill → 比對通用版與專案版的差異，將通用版的新功能或修正合併至專案版（保留專案特化的設定）
4. **`.skill_personal` 僅作為通用模板持續更新**，不直接作為專案執行用 Skill
5. **確保 `.gitignore` 排除 `CLAUDE.md`、`.claude/skills/`、`.skill_personal/`、修改日誌目錄**

### 規則 2：專案 Skill 更新回流至通用版

當在專案中對 `.claude/skills/` 進行改進時：

1. 判斷該改進是否為**通用性改進**（適用於所有專案）或**專案特化修正**（僅適用於當前專案）
2. 若為**通用性改進**（如：新增檢查項目、改善流程邏輯、修正 Skill 缺陷）→ 同步更新回 `.skill_personal/` 及遠端倉庫
3. 若為**專案特化修正**（如：特定路徑、服務名稱、專案慣例）→ **不回流**，僅保留在專案的 `.claude/skills/` 中
4. 回流更新時，移除所有專案特定的硬編碼，確保通用性
5. **Skill 變更不進入專案版控**，僅透過本遠端倉庫管理

### 規則 3：自動同步至遠端倉庫

- **遠端倉庫地址**：`https://github.com/SWSekai/Skill-personal.git`
- **本地路徑**：專案內的 `.skill_personal/`（自身即為 git repo）
- **同步時機**：每次 `.skill_personal/` 有任何更新時，自動執行以下流程：
  1. 進入 `.skill_personal/` 目錄
  2. 在 `.skill_personal/` 中 stage、commit（訊息與當前專案 commit 對應）
  3. Push 至遠端 `https://github.com/SWSekai/Skill-personal.git`
  4. 若 push 失敗，提示使用者手動處理

### 規則 4：新專案自動初始化

當 Claude 進入一個新專案目錄時：

1. 檢查是否存在 `.skill_personal/`（專案內，自身為 git repo）
2. 若存在但專案**沒有** `.claude/skills/` → 自動建立 `.claude/skills/` 並從模板複製
3. 根據專案特性客製化（路徑、服務名稱、commit 慣例、語言偏好）
4. 若 `.skill_personal/` 尚未初始化為 git repo → 執行 `git init` 並 `git remote add origin https://github.com/SWSekai/Skill-personal.git`
5. **確保 `.gitignore` 排除所有 Claude Code 相關檔案**
6. 初始化完成後執行 Skill 完整性檢查

### 規則 5：自動偵測遠端差異並同步

每次對話開始時（或操作 `.skill_personal/` 前）：

1. 進入 `.skill_personal/` 執行 `git fetch origin`
2. 比較本地 `HEAD` 與 `origin/main`，若不同步則 `git pull --rebase origin main`
3. 若有衝突，揉合本地與遠端規則（保留雙方有效內容，移除重複）
4. 揉合完成後 commit 並 `git push origin main`
5. 若遠端有 `.skill_personal/` 缺少的更新，自動合併回專案內的 `.skill_personal/`
6. 若 push 失敗，提示使用者手動處理

---

## Installation / 安裝

### 方法 1：一鍵建置（推薦）

```bash
# 在目標專案資料夾中執行 sp-init.bat
cd /path/to/your-project
D:\git\Skill-personal\sp-init.bat

# 或傳入專案路徑作為參數
D:\git\Skill-personal\sp-init.bat D:\git\your-project
```

sp-init.bat 會自動完成以下步驟：
1. 建立 `.claude/skills/` 並複製所有 Skill
2. 建立 `.skill_personal/` 作為通用模板同步用
3. 生成 `CLAUDE.md` 專案規範（含所有核心行為規則）
4. 安裝 pre-commit hook（防止 Skill 檔案誤入專案版控）

### 方法 2：手動複製

```bash
# Copy entire folder into your project
cp -r skill_personal/* /path/to/your-project/.claude/skills/

# Or copy into personal global skills
cp -r skill_personal/* ~/.claude/skills/
```

---

## Skills Overview / 指令一覽

| Skill | Command | Description |
|---|---|---|
| **commit-push** | `/commit-push` | Full commit flow: quality check → modify log → README update → commit → push → service restart eval |
| **modify-log** | `/modify-log [topic]` | Create versioned change log (`YYYYMMDD_v1.md`) with structured fields |
| **restart-eval** | `/restart-eval [range]` | Evaluate which Docker services need restart/rebuild after changes |
| **restart-volumn** | `/restart-volumn [services]` | Execute container restart/rebuild with health checks & auto-recovery |
| **trace-flow** | `/trace-flow [field]` | Trace a data field end-to-end through the system (UI → API → DB → processing) |
| **quality-check** | `/quality-check [files]` | Code quality audit: dead code, redundancy, impact, architecture, security |
| **report** | `/report [range]` | Generate concise work report from modify logs for 2-3 min presentations |
| **sys-info** | `/sys-info [question]` | System info query & documentation lifecycle management |
| **skill-sync** | `/skill-sync` | Auto-init skill environment, sync .skill_personal remote, evaluate rule placement |
| **md-collab** | `/md-collab [topic]` | Generate structured Markdown with checkboxes/tables for interactive decision-making |
| **context-guard** | `/context-guard` | Monitor context window usage, auto-summarize & suggest /clear when exceeding 40% |

---

## 詳細說明

### `/commit-push` — 提交與推送

完整的提交流程，依序執行：
1. **品質檢查**：掃描冗餘程式碼、影響評估、架構一致性
2. **自動建立修改日誌**：版本化紀錄（`YYYYMMDD_v[版本號].md`）
3. **自動更新 README**：受影響目錄的 README.md 同步更新
4. **暫存與提交**：偵測專案的 commit 訊息慣例並遵循
5. **推送**：推送至遠端，失敗時提示手動處理
6. **服務重啟評估**：自動讀取 `docker-compose.yml` 分析掛載方式，列出重啟指令

### `/modify-log [主題]` — 修改日誌

建立結構化的修改紀錄：
- **檔名格式**：`YYYYMMDD_v[版本號].md`（同日多次自動遞增）
- **必備欄位**：日期時間、版本號、更動原因、檔案影響行數、技術說明、影響範圍、潛在風險
- 自動偵測專案語言慣例

### `/restart-eval [commit範圍]` — 服務重啟評估

自動分析 `docker-compose.yml` 掛載方式：
- Volume 掛載 + 有 auto-reload → 不需重啟
- Volume 掛載 + 無 auto-reload → `docker compose restart`
- 程式碼打包進映像 → 需重建
- 靜態檔案 → 瀏覽器重新整理
- DB 初始化腳本 → 手動 migration
- 無容器化專案 → 偵測 PM2 / systemd 等管理工具

### `/restart-volumn [服務名...]` — 容器重啟與自動修復

完整的容器重啟/重建執行流程（與 restart-eval 互補）：
1. **Pre-flight 檢查**：容器狀態、背景任務、串流服務、掛載 vs 映像判斷
2. **執行重啟**：volume 掛載用 restart，映像打包用 build + up
3. **健康檢查**：等待啟動完成，確認 Status
4. **日誌掃描**：偵測 ImportError / ConnectionRefused 等錯誤
5. **自動修復**：`--no-cache` 重建、等待依賴、埠號衝突處理
6. **最終驗證**：API 可達性、Worker 連線確認、輸出報告

### `/trace-flow [欄位名]` — 資料流追蹤

追蹤指定欄位從前端到後端的完整路徑：
- 自動偵測專案架構（讀取 compose、package.json 等）
- 逐層記錄：變數名稱、型別、預設值、序列化風險
- 輸出摘要表格，標註每個節點的資料遺失風險
- 最終判定：值是否能可靠地端到端傳遞

### `/quality-check [檔案]` — 品質與影響檢查

提交前品質審計（也可獨立呼叫）：
- 死碼 / 冗餘邏輯 / 硬編碼值
- 架構一致性（讀取同目錄現有檔案比對慣例）
- 上下游影響評估 / 向下相容性
- 安全性掃描（OWASP Top 10）
- 風險報告（High / Medium / Low）
- Skill 自我更新建議
- Skill 完整性檢查（README、.skill_personal 同步、CLAUDE.md 更新）

### `/report [範圍]` — 工作報告生成

從修改紀錄統整生成簡報用工作報告：
- `/report` 全量、`/report weekly` 週報、`/report YYMMDD YYMMDD` 期間
- 依功能領域分類，表格導向，2～3 分鐘可講完
- 輸出結構：摘要→分類統整→技術亮點→服務影響→待追蹤

### `/sys-info [問題]` — 系統資訊查詢與文件管理

回答系統問題並管理文件生命週期：
- 搜尋現有文件引導用戶至具體段落
- 文件不足時自動擴充
- 無相關文件時新建
- 自動執行冗餘檢查避免文件重複

### `/md-collab [主題]` — Markdown 互動式協作

透過結構化 Markdown 檔案進行互動式決策協作：
1. **分析主題**：掃描相關程式碼，識別決策項目，記錄現狀
2. **生成決策表**：核取方塊 / 填寫欄位，預填建議值
3. **引導編輯**：告知檔案位置與規則，使用者修改後回覆
4. **讀取與實作**：差異比對 → 變更摘要 → 確認後逐項實作
- 支援四種模式：單選矩陣、多選清單、自由填寫、混合模式

### `/skill-sync` — Skill 環境初始化、遠端同步、規則評估

對話開始時自動觸發，確保 Skill 環境就緒：
- **自動初始化**：偵測缺少 `.claude/skills/` 的專案，從 .skill_personal 模板建立並生成 CLAUDE.md
- **遠端同步**：檢查 `.skill_personal/` 與遠端差異，pull → 揉合 → push
- **規則評估**：新增至 CLAUDE.md 或 Memory 的規則，評估是否應納入 Skill 或 .skill_personal

---

## 文件存放位置總覽

所有 Skill 產生的本地工作文件皆存放於 `.local/` 下，由 `.gitignore` 排除，不入專案版控。

### 本地工作文件（不入版控）

```
.local/
├── logs/          ← modify-log、restart-eval、restart-volumn
├── docs/          ← sys-info、trace-flow、md-collab
├── summary/       ← context-guard
└── reports/       ← report
```

| Skill | 檔案說明 | 存放位置 |
|-------|----------|----------|
| modify-log | 變更紀錄 `YYMMDD_TopicDescription.md` | `.local/logs/` |
| restart-eval | 服務重啟評估（可選存檔） | `.local/logs/` |
| restart-volumn | 重啟執行報告（可選存檔） | `.local/logs/` |
| sys-info | 系統文件 `[topic_description].md` | `.local/docs/` |
| trace-flow | 資料流追蹤（可選存檔） | `.local/docs/` |
| md-collab | 互動式決策表 | `.local/docs/`（預設） |
| context-guard | 上下文摘要 `YYMMDD_HHMM_Topic.md` + `current_topic.md` | `.local/summary/` |
| report | 工作報告 `YYMMDD_[type]_report.md` | `.local/reports/` |

### 入版控文件

| Skill | 檔案說明 | 存放位置 |
|-------|----------|----------|
| commit-push | 目錄 `README.md` 自動更新 | 變更目錄下的 `README.md` |

### Skill / 設定檔（由 skill-sync 管理）

| Skill | 檔案說明 | 存放位置 | 備註 |
|-------|----------|----------|------|
| skill-sync | `.claude/skills/` 各 `SKILL.md` | `.claude/skills/[name]/SKILL.md` | 同步至 `.skill_personal` remote |
| skill-sync | `CLAUDE.md` 規則更新 | 專案根目錄 `CLAUDE.md` | 僅在規則評估需要時更新 |
| quality-check | Skill 定義更新（條件觸發） | `.claude/skills/` | 僅在修改 Skill 定義時觸發 |

### 僅控制台輸出（不存檔）

| Skill | 輸出內容 |
|-------|----------|
| quality-check | Risk Report 表格（Severity/File/Mitigation） |
| trace-flow | 端到端資料流表格（Layer/File:Line/Variable/Type/Risk） |
| restart-eval | 服務重啟分類 + 執行指令清單 |
| restart-volumn | 重啟報告（Service/Action/Status/Duration） |

---

## Customization / 客製化

These skills are designed to be project-agnostic. To customize for a specific project:

1. Copy to `.claude/skills/` in your project
2. Edit the `SKILL.md` files to add project-specific:
   - Directory paths (e.g., log directory location)
   - Service names and container topology
   - Commit message conventions
   - Language preferences

---

## Directory Structure / 目錄結構

```
Skill-personal/
├── README.md                       ← This file（含同步規則）
├── sp-init.bat                     ← 一鍵建置腳本
├── sp-verify.bat                   ← 環境驗證腳本
├── templates/
│   └── CLAUDE.md.template          ← CLAUDE.md 通用模板（sp-init.bat 使用）
├── hooks/
│   └── pre-commit                  ← Git pre-commit hook（防止 Skill 檔案誤入版控）
├── commit-push/
│   ├── README.md                   ← 提交與推送 — 功能說明
│   └── SKILL.md                    ← Skill 定義與執行流程
├── modify-log/
│   ├── README.md                   ← 修改日誌 — 功能說明
│   └── SKILL.md                    ← Skill 定義與日誌格式規範
├── restart-eval/
│   ├── README.md                   ← 服務重啟評估 — 功能說明
│   └── SKILL.md                    ← Skill 定義與評估規則
├── restart-volumn/
│   ├── README.md                   ← 容器重啟與自動修復 — 功能說明
│   └── SKILL.md                    ← Skill 定義與執行修復流程
├── trace-flow/
│   ├── README.md                   ← 資料流追蹤 — 功能說明
│   └── SKILL.md                    ← Skill 定義與追蹤流程
├── quality-check/
│   ├── README.md                   ← 品質與影響檢查 — 功能說明
│   └── SKILL.md                    ← Skill 定義與檢查項目
├── report/
│   ├── README.md                   ← 工作報告生成 — 功能說明
│   └── SKILL.md                    ← Skill 定義與報告格式規範
├── sys-info/
│   ├── README.md                   ← 系統資訊查詢 — 功能說明
│   └── SKILL.md                    ← Skill 定義與文件管理流程
├── md-collab/
│   ├── README.md                   ← Markdown 互動式協作 — 功能說明
│   └── SKILL.md                    ← Skill 定義與協作流程
├── context-guard/
│   ├── README.md                   ← Context Window 管理 — 功能說明
│   └── SKILL.md                    ← Skill 定義與管理流程
└── skill-sync/
    ├── README.md                   ← Skill 環境初始化 — 功能說明
    └── SKILL.md                    ← Skill 定義與同步流程
```
