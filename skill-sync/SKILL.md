---
name: skill-sync
description: "Remote sync and rule evaluation only. Initial setup is handled by setup.bat, NOT this skill. (1) Sync skill_personal/ with remote (fetch → pull → merge → push). (2) Evaluate whether new CLAUDE.md/Memory rules should be added to skills or skill_personal/. Triggered when rules change or user calls /skill-sync."
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(git *), Bash(ls *), Bash(cp *), Bash(mkdir *), Bash(date *), Bash(bash *)
---

# Skill Sync — 遠端同步、規則評估

## 版控邊界（重要）

**所有 Skill 相關檔案不屬於專案版控：**

| 路徑 | 版控歸屬 | 說明 |
|------|---------|------|
| `.claude/skills/` | 不入版控 | 專案專屬 Skill，僅本地使用 |
| `skill_personal/` / `.skill_personal/` | skill_personal 遠端倉庫 | 通用 Skill 模板 |
| `CLAUDE.md` | 不入版控 | Claude Code 專案規範，僅本地使用 |

**原則：專案 git 僅追蹤專案程式碼。Skill 變更統一透過 `skill_personal/`（自身為 git repo）推送至遠端倉庫管理。**

**版控保護由 `setup.bat` 安裝的 pre-commit hook 強制執行（不依賴規則約束）。**

---

## 初始化 vs 同步的分工

| 任務 | 負責工具 | 說明 |
|------|---------|------|
| 新專案初始化 | `skill_personal/setup.bat` | 建立 `.claude/skills/`、`skill_personal/`、`CLAUDE.md`、`.gitignore`、pre-commit hook |
| 驗證環境完整性 | `skill_personal/verify.bat` | 檢查所有保護層是否就位 |
| 遠端同步 | `/skill-sync`（本 Skill） | Fetch/pull/merge/push skill_personal 遠端 |
| 規則歸類評估 | `/skill-sync`（本 Skill） | 評估新規則應放入 Skill / CLAUDE.md / Memory |

> **不要用 `/skill-sync` 做初始化。** 若環境未就緒，請執行 `skill_personal/setup.bat`。

---

## 觸發時機

1. **新增規則至 CLAUDE.md 或 Memory 時**（自動）：評估是否應加入 Skill
2. **修改 skill_personal/ 時**（自動）：同步至 skill_personal 遠端倉庫
3. **手動呼叫** `/skill-sync`：強制執行完整同步流程
4. **對話開始時**（可選）：檢查遠端是否同步（僅執行流程一）

---

## 流程一：skill_personal 遠端同步

**觸發條件**：每次對話開始時、操作 `skill_personal/` 前

### 執行方式

**直接執行自動化腳本：**
```bash
bash skill_personal/setup/sp-sync.sh
```

腳本會自動完成以下所有步驟：
1. `git fetch origin` — 取得遠端更新
2. 比較本地與遠端 commit 差異
3. 若有更新 → `git pull --rebase origin main`
4. 逐一比對 `skill_personal/` 與 `.claude/skills/` 下每個 skill 的 SKILL.md / README.md
5. 自動複製新增或有差異的 skill 到 `.claude/skills/`
6. 輸出同步摘要（Added / Updated / No change）

### 腳本無法處理的情況（需手動介入）

- **Pull 衝突**：腳本會中止並提示，需手動 resolve 後重新執行
- **新增 skill**：腳本會複製檔案，但需手動更新 CLAUDE.md「Available Skills」清單
- **Push 本地變更**：腳本不會自動 push，需確認後手動執行 `cd skill_personal && git push origin main`

---

## 流程二：規則評估與歸類

**觸發條件**：新增規則至 CLAUDE.md 或 Memory 時

### 強制執行約束

> **寫入 Memory 時，必須在同一回覆中完成三向連動評估與執行。**
> 不可僅寫入 Memory 就結束，不可拆成多步，不可等使用者提醒。
>
> Memory 記錄的多數為使用者開發習慣與行為偏好，這些偏好具備跨專案通用性。
> 僅存在 Memory 中的規則只對當前專案有效，無法隨 skill_personal 帶到新專案。
>
> **每次寫入 Memory 後立即判斷：**
> 1. 是否為可重複套用的行為約束或流程規則？ → 同步更新 CLAUDE.md
> 2. 是否具備跨專案通用性？ → 回流至 `skill_personal/` 模板並推送遠端
> 3. 是否僅適用當前專案？ → 僅 Memory，不回流

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
        │   └─ 同步更新 skill_personal/ 對應 Skill（移除專案硬編碼）→ push 至遠端
        │
        ├─ 屬於新的可重複流程？ → 評估是否建立新 Skill
        │   └─ 建立後執行完整性檢查 → 回流至 skill_personal/ → push 至遠端
        │
        └─ 屬於行為準則（非流程）？ → 加入 CLAUDE.md 通用模板
            └─ 更新 skill-sync 的 CLAUDE.md 模板區段
```

### 評估時必須回答的問題

1. **這條規則是否可從程式碼推導？** → 若是，不需儲存
2. **這條規則是否只在特定專案有意義？** → 若是，只放 CLAUDE.md / Memory
3. **這條規則是否改變了某個既有 Skill 的行為？** → 若是，更新該 Skill
4. **這條規則是否定義了新的可重複流程？** → 若是，評估建立新 Skill
5. **更新後是否需要同步至 skill_personal/?** → 移除專案硬編碼後回流，並 push 至遠端

### 同步流程

規則確認歸類後：
1. 更新本專案 `.claude/skills/` 對應檔案
2. 評估通用性 → 若通用，同步至 `skill_personal/`（移除專案硬編碼）
3. `skill_personal/` 有更新 → 觸發流程一同步至遠端
4. 更新相關 README
5. **以上所有變更不進入專案版控**

---

## CLAUDE.md 通用模板

初始化新專案時，CLAUDE.md 應包含以下結構：

```markdown
# [專案名稱] — Claude Code 專案規範

## 語言與格式
- Commit 訊息、修改日誌、README：**[語言]**
- Commit prefix：`feat:`, `fix:`, `ui:`, `docs:`, `refactor:`
- 所有 commit 附加：`Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>`

## 版控邊界（重要）

以下資料夾及檔案**不屬於專案版控**，由 `setup.bat` 安裝的 `.gitignore` + pre-commit hook 強制執行：

| 路徑 | 用途 | 版控歸屬 | 保護機制 |
|------|------|---------|---------|
| `CLAUDE.md` | Claude Code 專案規範 | 本地設定 | .gitignore + hook |
| `.claude/skills/` | 專案專屬 Skill 定義 | 本地設定 | .gitignore + hook |
| `.local/` | logs/ docs/ summary/ reports/ | 本地工作紀錄 | .gitignore + setup.bat |
| `skill_personal/` | 通用 Skill 模板 | skill_personal 遠端倉庫 | .gitignore + hook |

**原則：專案 git 僅追蹤專案程式碼。版控保護由腳本自動安裝，不依賴規則約束。**

## 核心行為規則
[由 setup.bat 生成的 CLAUDE.md 定義，此處不重複]
- 功能需求規劃先行：收到功能訴求時，必須先設計完整方案與步驟，呈獻使用者確認後才開始實作；如有多種做法，列出替代方案與優缺點供選擇
- 方案確認使用 AskUserQuestion 工具，「開始執行 (Recommended)」為首選項，使用者按 Enter 即可繼續執行

## 可用 Skills
- `/commit-push` — 提交推送（含品質檢查、日誌、README 更新、容器評估）
- `/modify-log` — 建立修改日誌（commit 後觸發，僅本地）
- `/restart-eval` — 容器重啟評估（commit 後觸發）
- `/trace-flow` — 資料流端到端追蹤
- `/quality-check` — 程式碼品質與影響檢查（commit 前觸發）
- `/report` — 從修改紀錄生成工作簡報
- `/sys-info` — 系統資訊查詢與文件管理
- `/skill-sync` — 遠端同步、規則評估（不負責初始化）
- `/context-guard` — Context Window 管理守衛
```
