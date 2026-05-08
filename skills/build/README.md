# build — 開發全流程

## 功能說明

整合需求分析、方案設計、實作引導、測試驗證，加上提交推送、品質檢查、修改日誌、容器重啟評估與執行。

## 使用方式

```
/build <all|plan|do|test|check|review|deploy> [--no-subagent] [args...]
```

### Flag

| Flag | 用途 |
|---|---|
| `--no-subagent` | 1M context 模式：所有 Agent 子任務改為主 session 內嵌執行（適用於 Opus 4.7 1M context 未啟用 `/extra-usage`，或需要單一 transcript 完整稽核軌跡時）；可與 `/build all` 結合，串接的 `/commit-push` 自動繼承此 flag。對齊 CLAUDE.md Rule 26 跨 skill 標準 |

## Model

- **建議 model**: `sonnet`
- **Effort**: `medium`
- **理由**: 多步驟編排流程，需要判斷力但不需跨檔深度分析（quality 子命令內部以 deeper thinking 處理）

## 觸發條件

手動呼叫

## 執行流程

| 子命令 | 用途 |
|---|---|
| `all <feature>` | 全流程串接：plan → do → test → review → `/commit-push` → deploy |
| `plan <feature>` | 需求分析 + 方案設計 + 步驟拆解（產出計畫文件至 `.local/docs/plan/`）|
| `do [plan-ref]` | 按方案逐步實作，自動檢查進度，偵測偏差 |
| `test [scope]` | 測試驗證：自動跑測試 + 手動 checklist + 邊界案例 |
| `check [files...]` | 獨立品質審計（亦內嵌於 `/commit-push` Step 1）|
| `review` | commit 前最終手動確認 checklist（建議大改動時使用）|
| `deploy [--plan\|--run] [services...]` | 重啟評估 + 執行（預設先 `--plan` 列出計畫，再執行）|

> **commit & push**：使用獨立的 `/commit-push`（包含品質檢查 / 修改日誌 / README / commit / push / deploy --plan / context 清理）。原 `/build commit`、`/build log`、`/build restart`、`/build eval` 已重整至 `/commit-push` 與 `/build deploy`。

## 目錄結構

```
build/
├── SKILL.md
├── README.md
└── references/
    ├── commit-conventions.md    ← commit 格式規範
    ├── gitignore-safety.md      ← .gitignore 安全規則
    ├── severity-guide.md        ← 風險嚴重等級定義 + 實作後驗證
    ├── error-recovery.md        ← 容器錯誤自動修復流程
    └── log-keywords.md          ← 日誌關鍵字嚴重等級
```

## 整合來源

| 原 Skill | 對應子命令 |
|---|---|
| commit-push | `commit` |
| quality-check | `quality` |
| modify-log | `log` |
| restart-volumn | `restart` |
| restart-eval | `eval` |

---

## 相關 Skills 與檔案

- **呼叫**：`/commit-push`（`deploy` 子指令委派 commit 階段）、`/team decide`（`plan` 子指令開啟決策表）
- **被呼叫**：無（使用者主動觸發）
- **共用資源**：`team/assets/decision-template.md`（plan 決策共用模板）、`commit-push/references/commit-conventions.md`（commit 規範）
- **改名歷史（本 skill 自身）**：2026-04-24 子指令重整（移除 `commit` 改交 `/commit-push`、`eval` → `deploy`）；全域改名請見 `_bootstrap/RENAME_HISTORY.md`
