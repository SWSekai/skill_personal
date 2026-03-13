# Claude Code General Skills — 通用自動化指令集

A portable set of Claude Code skills that work with **any project**. No project-specific logic — just copy into your `.claude/skills/` directory.

通用版 Claude Code Skill，不含任何專案相關邏輯，可直接複製到任何專案的 `.claude/skills/` 目錄使用。

---

## Skill 同步規則

### 規則 1：導入專案時自動建置專案專屬 Skill

當將本資料夾的 Skill 導入新專案時：

1. 檢查該專案是否已有 `.claude/skills/` 資料夾
2. 若**無**專案專屬 Skill → 自動複製一份至 `.claude/skills/`，並根據專案特性進行客製化調整（如：修改日誌路徑、服務名稱、commit 慣例、語言偏好）
3. 若**已有**專案專屬 Skill → 比對通用版與專案版的差異，將通用版的新功能或修正合併至專案版（保留專案特化的設定）
4. **`skill_general` 僅作為通用模板持續更新**，不直接作為專案執行用 Skill

### 規則 2：專案 Skill 更新回流至通用版

當在專案中對 `.claude/skills/` 進行改進時：

1. 判斷該改進是否為**通用性改進**（適用於所有專案）或**專案特化修正**（僅適用於當前專案）
2. 若為**通用性改進**（如：新增檢查項目、改善流程邏輯、修正 Skill 缺陷）→ 同步更新回 `skill_general/` 及遠端倉庫
3. 若為**專案特化修正**（如：特定路徑、服務名稱、專案慣例）→ **不回流**，僅保留在專案的 `.claude/skills/` 中
4. 回流更新時，移除所有專案特定的硬編碼，確保通用性

### 規則 3：自動同步至遠端倉庫

- **遠端倉庫地址**：`https://github.com/SWSekai/Skill-personal.git`
- **本地路徑**：與當前專案同層級的 `../Skill-personal/`（若不存在則自動 clone）
- **同步時機**：每次 `skill_general/` 有任何更新時，自動執行以下流程：
  1. 將更新後的檔案複製至本地 `Skill-personal` 倉庫
  2. 在 `Skill-personal` 倉庫中 commit（訊息與當前專案 commit 對應）
  3. Push 至遠端 `https://github.com/SWSekai/Skill-personal.git`
  4. 若 push 失敗，提示使用者手動處理

---

## Installation / 安裝

```bash
# Copy entire folder into your project
cp -r skill_general/* /path/to/your-project/.claude/skills/

# Or copy into personal global skills
cp -r skill_general/* ~/.claude/skills/
```

---

## Skills Overview / 指令一覽

| Skill | Command | Description |
|---|---|---|
| **commit-push** | `/commit-push` | Full commit flow: quality check → modify log → README update → commit → push → service restart eval |
| **modify-log** | `/modify-log [topic]` | Create versioned change log (`YYYYMMDD_v1.md`) with structured fields |
| **restart-eval** | `/restart-eval [range]` | Evaluate which Docker services need restart/rebuild after changes |
| **trace-flow** | `/trace-flow [field]` | Trace a data field end-to-end through the system (UI → API → DB → processing) |
| **quality-check** | `/quality-check [files]` | Code quality audit: dead code, redundancy, impact, architecture, security |

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
├── README.md                       ← This file (含同步規則)
├── commit-push/
│   ├── README.md                   ← 提交與推送 — 功能說明
│   └── SKILL.md                    ← Skill 定義與執行流程
├── modify-log/
│   ├── README.md                   ← 修改日誌 — 功能說明
│   └── SKILL.md                    ← Skill 定義與日誌格式規範
├── restart-eval/
│   ├── README.md                   ← 服務重啟評估 — 功能說明
│   └── SKILL.md                    ← Skill 定義與評估規則
├── trace-flow/
│   ├── README.md                   ← 資料流追蹤 — 功能說明
│   └── SKILL.md                    ← Skill 定義與追蹤流程
└── quality-check/
    ├── README.md                   ← 品質與影響檢查 — 功能說明
    └── SKILL.md                    ← Skill 定義與檢查項目
```
