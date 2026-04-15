# context-guard — Context Window 管理

## 功能說明

監控 context window 使用狀況，系統壓縮通知時自動摘要、手動呼叫整理、對話開始恢復。

## 使用方式

```
/context-guard [check|clean]
```

## Model

- **建議 model**: `sonnet`
- **Effort**: `low`
- **理由**: 摘要生成，固定模板流程

## 觸發條件

- 系統壓縮通知（自動）
- 手動呼叫
- 對話開始時（由 `/setup sync` 串聯）

## 執行流程

1. 觸發條件判定
2. 記錄當前工作狀態至 `.local/summary/`
3. 更新 topic state file
4. 任務切換偵測（半自動）
5. 摘要恢復與生命週期管理
6. 確認 commit 與 /clear

## 目錄結構

```
context-guard/
├── SKILL.md
└── README.md
```

## 摘要儲存位置

```
.local/summary/
├── current_topic.md
└── YYMMDD_HHMM_主題描述.md
```
