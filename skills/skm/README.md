# skm — Skill 管理（Skill Management）

> **2026-04-24 改名**：`/skill` → `/skm`（避免與 Claude Code 內建 `/skills` 對話框混淆，且符合「skill management」縮寫語義）。舊名 `/skill` 已停用，無 alias。
> **2026-04-17 前一次改名**：`/setup` → `/skill`（當時更準確對應「只管 Skill 環境」的職能）。

## 功能說明

整合建立新 Skill、遠端同步與規則評估、專案打包、使用者確認式 Skill 改進捕捉、**Skill 重大概念重構**五項職能。

## 使用方式

```
/skm <new|sync|pack|update|refactor> [args...]
```

## Model

- **建議 model**: `sonnet`
- **Effort**: `medium`
- **理由**: 多檔生成 + 索引註冊 + Git 同步，需要判斷力

## 觸發條件

- `new`：手動呼叫（收尾 Step 10 強制走 AskUserQuestion → `/commit-push --meta`，見 CLAUDE.md Rule 20）
- `sync`：對話開始自動 / 手動
- `pack`：手動呼叫
- `update`：**僅手動呼叫**（刻意避免 AI 自判，由使用者明確觸發，2026-04-17 新增）
- `refactor`：**僅手動呼叫**（使用者主動提供新概念，Claude 評估保留規則並重寫 skill，2026-04-29 新增）

## 執行流程

| 子命令 | 用途 |
|---|---|
| `new [name] [desc]` | 建立新 Skill（互動式定義 → 檔案生成 → 索引更新 → 同步 → Step 10 commit 詢問） |
| `sync` | Sekai_workflow 遠端同步、規則評估與三向連動；含 Rule 23 非 skill 目錄變更檢查（`handbook/`、`docs/` 等）|
| `pack` | 專案打包（四階段：Memory/Skill/CLAUDE.md 審計 → 收集至 `bag/` → Changeset Review 使用者確認 → 執行清理），確認前不寫入 |
| `update [hint]` | 使用者確認式 Skill 改進：對話中浮現的規則 → 使用者下 `/skm update` → Gap + Ecosystem 稽核 → 明確 diff 預覽 → 套用 + 三向同步 |
| `refactor <skill> <concept>` | Skill 重大重構：使用者提供新核心概念 → Claude 評估各步驟保留/調整/移除/新增 → 輸出計畫 → 執行完整改寫 |

## 目錄結構

```
skm/
├── SKILL.md
├── README.md
├── references/
│   ├── model-selection-guide.md          ← Model 選擇決策樹
│   ├── evaluation-decision-tree.md       ← 規則評估歸類決策樹
│   └── version-control-boundaries.md     ← 版控邊界說明
└── assets/
    ├── SKILL.md.template                 ← 新 Skill 的 SKILL.md 模板
    └── README.md.template                ← 新 Skill 的 README.md 模板
```

## 整合來源

| 原 Skill | 對應子命令 |
|---|---|
| create-skill | `new` |
| skill-sync | `sync` |
| pack | `pack` |

---

## 相關 Skills 與檔案

- **呼叫**：`/commit-push --meta`（`/skm new` Step 10 自動觸發、`/skm update` Step 7 鏡像 commit）、讀取 `_bootstrap/manifest.json` 與 `_bootstrap/sp-*.{bat,sh}`
- **被呼叫**：`/hello` Step 2（吸收 `/skm sync` Flow 1：遠端拉取 + skill diff）
- **共用資源**：`_bootstrap/RENAME_HISTORY.md`（全域改名歷史 single source of truth，Rule 24.3）、`_bootstrap/CLAUDE.md.template`（傳遞至新專案的模板）
- **改名歷史（本 skill 自身）**：`/setup` → `/skill`（2026-04-17）→ `/skm`（2026-04-24，避免與內建 `/skills` 衝突）；全域改名請見 `_bootstrap/RENAME_HISTORY.md`
