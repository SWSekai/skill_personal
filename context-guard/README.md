# context-guard — Context Window 管理守衛

## 功能概述

監控對話的 context window 使用狀態，當超過 40% 時自動整理摘要並建議 /clear，確保對話始終保持簡潔高效。支援任務切換偵測與摘要生命週期管理。

## 目錄結構

```
.claude/skills/context-guard/
├── README.md     ← 本文件
└── SKILL.md      ← Context 管理規範
```

## 使用方式

```
/context-guard              # 完整檢查 + 產生摘要
/context-guard check        # 僅檢查狀態，不產生摘要
/context-guard clean        # 清理過時的摘要檔案
```

## 執行流程

| 步驟 | 動作 | 說明 |
|------|------|------|
| 1 | 評估 context | 判斷使用量是否超過 40% |
| 2 | 產生摘要 | 輸出至 `./context_summary/YYMMDD_HHMM_主題.md` |
| 3 | 確認提交 | 詢問使用者是否需要先 commit |
| 4 | 建議 /clear | 確認後提示使用者執行 /clear |

## 自動觸發條件

- 對話輪數超過 20 輪
- 系統 context 壓縮通知
- 偵測到任務切換
- 手動呼叫

## 摘要生命週期

- 新對話開始時自動讀取未處理的摘要
- 工作完成後自動清理過時摘要
- 過程中可主動更新摘要以保持最新狀態

## 摘要儲存位置

```
./context_summary/
└── YYMMDD_HHMM_主題描述.md
```
