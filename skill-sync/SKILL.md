---
name: skill-sync
description: "Auto-triggered at conversation start and when rules are added to CLAUDE.md or Memory: (1) If .claude/skills/ is missing but skill_general/ or ../Skill-personal/ exists, auto-init skills and generate CLAUDE.md from template. (2) Sync ../Skill-personal/ with remote (fetch → pull → merge → push). (3) Evaluate whether new CLAUDE.md/Memory rules should be added to skills or skill_general/. Also triggered when user adds new rules, preferences, or workflow conventions."
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(git *), Bash(ls *), Bash(cp *), Bash(mkdir *), Bash(date *)
---

# Skill Sync — Skill 環境初始化、遠端同步、規則評估

## 觸發時機

1. **對話開始時**（自動）：檢查 Skill 環境是否就緒、遠端是否同步
2. **新增規則至 CLAUDE.md 或 Memory 時**（自動）：評估是否應加入 Skill
3. **修改 skill_general/ 時**（自動）：同步至 Skill-personal 遠端倉庫
4. **手動呼叫** `/skill-sync`：強制執行完整同步流程

---

## 流程一：新專案自動初始化

**觸發條件**：專案有 `skill_general/`（或同層級有 `../Skill-personal/`）但無 `.claude/skills/`

### 步驟

1. **Clone 遠端倉庫**（若 `../Skill-personal/` 不存在）
   ```bash
   cd .. && git clone https://github.com/SWSekai/Skill-personal.git
   ```

2. **建立 `.claude/skills/`**
   - 從 `skill_general/`（優先）或 `../Skill-personal/` 複製所有 Skill
   - 每個 Skill 資料夾必須包含 `SKILL.md` + `README.md`

3. **客製化專案 Skill**
   - 讀取專案結構（`docker-compose.yml`、`package.json`、目錄結構）
   - 調整各 SKILL.md 中的專案特定設定：
     - 修改日誌路徑
     - 服務名稱與容器拓撲
     - Commit 訊息慣例
     - 語言偏好

4. **生成 CLAUDE.md**
   - 從通用模板生成，包含以下通用規則：
     - 語言與格式（留空讓使用者填入）
     - 修改前影響評估
     - 修改後品質檢查
     - Commit 前自動化日誌
     - Commit 前 .gitignore 安全檢查
     - Commit 後容器重啟評估（若專案有容器化）
     - README 維護
     - Skill 動態更新
     - Memory/Skill/skill_general 三向連動
     - Skill 完整性檢查
     - 新專案自動初始化（本規則）
     - 遠端同步（本規則）
     - 資訊查詢時主動建立文件
   - 根據專案特性填入具體值（偵測到的語言、服務名、路徑）
   - 附加可用 Skills 列表

5. **執行完整性檢查**
   - 每個 Skill 資料夾有 `SKILL.md` + `README.md`
   - `.claude/skills/README.md` 已建立
   - `CLAUDE.md` 已建立且包含可用 Skills 列表

---

## 流程二：Skill-personal 遠端同步

**觸發條件**：每次對話開始時、操作 `skill_general/` 前

### 步驟

1. **Fetch 遠端**
   ```bash
   cd ../Skill-personal && git fetch origin
   ```

2. **比較本地與遠端**
   ```bash
   git log HEAD..origin/main --oneline
   git log origin/main..HEAD --oneline
   ```

3. **若不同步 — Pull 並揉合**
   ```bash
   git pull --rebase origin main
   ```
   - 若有衝突：分析雙方內容，保留兩方有效規則，移除重複
   - 揉合原則：
     - 新增的規則 → 保留
     - 修改的規則 → 取較新或較完整的版本
     - 刪除的規則 → 確認是否為有意移除
   - 揉合完成後 commit

4. **Push 至遠端**
   ```bash
   git push origin main
   ```
   - 若 push 失敗 → 提示使用者手動處理

5. **反向同步至 skill_general/**
   - 若遠端有 `skill_general/` 缺少的更新（來自其他專案的回流）
   - 將差異合併回當前專案的 `skill_general/`

---

## 流程三：規則評估與歸類

**觸發條件**：新增規則至 CLAUDE.md 或 Memory 時

### 評估決策樹

```
新規則 / 偏好 / 流程
    │
    ├─ 僅限當前對話？ → 不儲存
    │
    ├─ 跨對話但僅限本專案？ → CLAUDE.md 或 Memory
    │
    └─ 通用（適用所有專案）？
        │
        ├─ 屬於既有 Skill 職責？ → 更新該 Skill 的 SKILL.md
        │   └─ 同步更新 skill_general/ 對應 Skill（移除專案硬編碼）
        │
        ├─ 屬於新的可重複流程？ → 評估是否建立新 Skill
        │   └─ 建立後執行完整性檢查
        │
        └─ 屬於行為準則（非流程）？ → 加入 CLAUDE.md 通用模板
            └─ 更新 skill-sync 的 CLAUDE.md 模板區段
```

### 評估時必須回答的問題

1. **這條規則是否可從程式碼推導？** → 若是，不需儲存
2. **這條規則是否只在特定專案有意義？** → 若是，只放 CLAUDE.md / Memory
3. **這條規則是否改變了某個既有 Skill 的行為？** → 若是，更新該 Skill
4. **這條規則是否定義了新的可重複流程？** → 若是，評估建立新 Skill
5. **更新後是否需要同步至 skill_general/?** → 移除專案硬編碼後回流

### 同步流程

規則確認歸類後：
1. 更新本專案 `.claude/skills/` 對應檔案
2. 評估通用性 → 若通用，同步至 `skill_general/`（移除專案硬編碼）
3. `skill_general/` 有更新 → 觸發流程二同步至 Skill-personal
4. 更新相關 README

---

## CLAUDE.md 通用模板

初始化新專案時，CLAUDE.md 應包含以下結構：

```markdown
# [專案名稱] — Claude Code 專案規範

## 語言與格式
- Commit 訊息、修改日誌、README：**[語言]**
- Commit prefix：`feat:`, `fix:`, `ui:`, `docs:`, `refactor:`
- 所有 commit 附加：`Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>`

## 核心行為規則

### 1. 每次修改前 — 影響評估
- 主動檢查改動對現有功能、架構的影響或衝突
- 主動提出潛在風險（向下相容、競態條件、資料遺失）
- 若無風險，明確說明「無潛在風險」

### 2. 每次修改後 — 品質檢查
- 掃描冗餘程式碼、死碼、未使用的 import
- 驗證是否符合專案現有設計模式
- 檢查 JSON 序列化風險

### 3. 每次 Commit 前 — 自動化日誌
- **必須**在 `[日誌路徑]` 建立修改紀錄
- 必備欄位：日期時間、版本號、更動原因、檔案影響行數、影響範圍、容器重啟需求

### 4. 每次 Commit 前 — .gitignore 安全檢查與狀態總覽
- 讀取 `.gitignore`，確認即將 stage 的檔案不在忽略清單中
- 列出所有待處理狀態：未暫存修改、已暫存未 commit、已 commit 未 push
- 向使用者確認後才執行 commit

### 5. 每次 Commit 後 — 容器重啟評估
- 根據改動檔案列出需重啟的容器及指令

### 6. README 維護
- 具備功能的資料夾下必須有 `README.md`
- 新增任何資料夾時，必須同步建立 `README.md`
- Commit 時若改動影響目錄結構或功能，主動更新對應 README

### 7. Skill 動態更新
- 當對話中出現新規則或偏好時，主動詢問是否更新至 Skill 規範
- 獲得確認後修改 `.claude/skills/` 對應文件

### 8. Memory、Skill、skill_general 三向連動
- 寫入 Memory 時，評估是否應同步加入 Skill
- 更新 `.claude/skills/` 或 Memory 時，評估是否應回流至 `skill_general/`
- `skill_general/` 更新後，自動同步至 `../Skill-personal/`

### 9. 新增 Skill 後 — 完整性檢查
- Skill 資料夾包含 `SKILL.md` 和 `README.md`
- `.claude/skills/README.md` 已更新
- `skill_general/` 對應資料夾已同步
- CLAUDE.md 可用 Skills 列表已更新

### 10. 新專案自動初始化 Skill
- 進入新專案時，自動偵測並初始化 Skill 環境
- 觸發 `/skill-sync` 執行完整初始化流程

### 11. Skill-personal 遠端同步與衝突處理
- 每次對話開始時自動同步
- 觸發 `/skill-sync` 執行遠端同步流程

### 12. 資訊查詢時主動建立文件
- 被詢問系統架構、功能、資料流等問題時，自動觸發 `/sys-info`

## 可用 Skills
- `/commit-push` — 提交推送（含品質檢查、日誌、README 更新、容器評估）
- `/modify-log` — 建立修改日誌（commit 前自動觸發）
- `/restart-eval` — 容器重啟評估（commit 後自動觸發）
- `/trace-flow` — 資料流端到端追蹤
- `/quality-check` — 程式碼品質與影響檢查（commit 前自動觸發）
- `/sys-info` — 系統資訊查詢與文件管理
- `/skill-sync` — Skill 環境初始化、遠端同步、規則評估（對話開始時自動觸發）
```
