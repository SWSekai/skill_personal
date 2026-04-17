# clean — Context 清理入口

## 功能說明

繼承原 `context-guard` 的所有功能（摘要生成、狀態追蹤、任務切換偵測、摘要恢復），並新增：
- 執行 `/clear` 前自動清理舊摘要
- 透過 Stop hook 偵測前一 session 遺留摘要，自動提醒使用者執行 `/clean`

取代原有的 `/context-guard`，合併清理流程為單一入口。

## 使用方式

```
/clean           # 完整流程：摘要 → 清理舊摘要 → /clear
/clean check     # 僅檢查狀態，不產生摘要、不清理
/clean force     # 跳過 commit 確認，直接執行完整流程
```

## Model

- **建議 model**: `sonnet`
- **Effort**: `low`
- **理由**: 摘要生成為固定模板流程，不需要深度分析

## 觸發條件

| 觸發方式 | 說明 |
|----------|------|
| 手動 `/clean` | 使用者主動呼叫 |
| 系統壓縮通知 | 收到 context compressed 訊息時自動觸發 |
| 對話開始 | 由 `/hello` 串聯，檢查待恢復摘要 |
| Stop hook 提醒 | 偵測到舊摘要時輸出提醒（不自動執行） |

## 執行流程

1. 觸發條件判定（含參數解析）
2. 記錄當前工作狀態至 `.local/context_summary/`
3. 更新 topic state file
4. 任務切換偵測（半自動）
5. 摘要恢復與生命週期管理（對話開始時）
6. Commit 確認（透過 tool confirmation UI）
7. **清理舊摘要**（新增功能）
8. 執行 `/clear` 清除 context

## Hook 自動提醒

### 能力說明

| 功能 | 可行性 | 說明 |
|------|:------:|------|
| 偵測舊摘要存在 → 提醒 | 可行 | Stop hook 偵測 `.local/context_summary/` 中的舊摘要 |
| 自動讀取 context 用量 % | 不可行 | Claude Code 無提供 API 讀取 context 使用率 |
| Hook 自動執行 `/clean` | 不可行 | Hook 無法直接呼叫 slash command |
| 對話結束提醒 | 可行 | Stop hook 在每次回應結束時檢查，搭配冷卻機制避免過度提醒 |

### Hook 運作機制

`check_context_reminder.cjs`（Stop hook）：
1. 掃描 `.local/context_summary/` 中的 `.md` 檔案（排除 `current_topic.md`）
2. 若存在舊摘要 → 檢查冷卻檔（`.local/.clean_reminder_cooldown`）
3. 冷卻期（30 分鐘）未過 → 靜默通過
4. 冷卻期已過 → 輸出提醒訊息，更新冷卻時間戳

## 與 context-guard 的差異

| 項目 | context-guard（已廢棄） | clean |
|------|------------------------|-------|
| 清理舊摘要 | 手動 `clean` 參數 | 自動包含於流程中 |
| 執行 /clear | 僅提示 | 直接執行 |
| Stop hook 提醒 | 無 | 內建 |
| Commit 確認方式 | 文字詢問 | Tool confirmation UI |

## 目錄結構

```
clean/
├── SKILL.md
└── README.md
```

## 摘要儲存位置

```
.local/context_summary/
├── current_topic.md
└── YYMMDD_HHMM_主題描述.md
```
