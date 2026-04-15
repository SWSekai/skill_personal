# build — 開發全流程

## 功能說明

整合需求分析、方案設計、實作引導、測試驗證，加上提交推送、品質檢查、修改日誌、容器重啟評估與執行。

## 使用方式

```
/build <flow|plan|impl|test|commit|quality|log|restart|eval> [args...]
```

## Model

- **建議 model**: `sonnet`
- **Effort**: `medium`
- **理由**: 多步驟編排流程，需要判斷力但不需跨檔深度分析（quality 子命令內部以 deeper thinking 處理）

## 觸發條件

手動呼叫

## 執行流程

| 子命令 | 用途 |
|---|---|
| `flow <feature>` | 全流程串接：plan → impl → test → commit |
| `plan <feature>` | 需求分析 + 方案設計 + 步驟拆解 |
| `impl [plan-ref]` | 按方案逐步實作 |
| `test [scope]` | 測試驗證 |
| `commit [msg]` | 完整提交流程（品質 → 日誌 → README → commit → push → 重啟評估） |
| `quality [files]` | 獨立品質審計 |
| `log [topic]` | 建立 / 更新本地修改日誌 |
| `restart [services]` | 容器重啟與自動修復 |
| `eval [range]` | 重啟評估（不執行） |

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
