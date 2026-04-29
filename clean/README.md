# clean — Context 清理入口

## 功能說明

繼承原 `context-guard` 的所有功能（摘要生成、狀態追蹤、任務切換偵測、摘要恢復），並新增：
- 執行 `/clear` 前自動清理舊摘要
- **生成單次消費的 `resumption_prompt.md`**：下一個 session 的 `UserPromptSubmit` hook 自動讀取注入並刪除，實現無縫接續
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

| 步驟 | 說明 |
|---|---|
| 1. 觸發條件判定 | 解析參數（check / force / 無引數）|
| 2. 記錄工作狀態 | 寫入 `.local/context_summary/YYMMDD_HHMM_Topic.md` |
| 2b. 生成 resumption_prompt.md | 緊湊型單次消費檔案，供 `UserPromptSubmit` hook 注入用；`check` 模式跳過 |
| 2c. Hook 安裝提示 | 若 `inject_context_on_resume.cjs` 不存在則提醒 |
| 3. 更新 topic state file | 寫入 `.local/context_summary/current_topic.md` |
| 4. 任務切換偵測 | 半自動，比對 current_topic 與新請求 |
| 5. 摘要恢復與生命週期 | 對話開始時由 `/hello` 串聯 |
| 6. Commit 確認 | 透過 tool confirmation UI；`force` 跳過 |
| 7. 清理舊摘要 | 保留本次 Step 2 產生的新摘要，刪除其餘 |
| 8. 執行 `/clear` | 清除 context；輸出 hook 行為說明 |

## Hook 自動提醒

### 能力說明

| 功能 | 可行性 | 說明 |
|------|:------:|------|
| 偵測舊摘要存在 → 提醒 | 可行 | Stop hook 偵測 `.local/context_summary/` 中的舊摘要 |
| **清除後自動注入 context** | **可行** | `UserPromptSubmit` hook 讀取 `resumption_prompt.md` → 注入至第一則訊息 → 刪除（單次消費） |
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
├── current_topic.md            ← 當前主題追蹤
├── YYMMDD_HHMM_主題描述.md    ← 完整摘要（供 /hello Step 3 讀取）
└── resumption_prompt.md        ← 單次消費注入檔（hook 讀後刪除）
```

## 需要安裝的 Hook

`UserPromptSubmit` hook：`inject_context_on_resume.cjs`
- 來源：`Sekai_workflow/hooks/inject_context_on_resume.cjs`（需透過 sp-init 或手動安裝）
- 綁定：`.claude/settings.local.json` 的 `UserPromptSubmit` 項目
- 行為：第一則訊息時注入 resumption_prompt.md 內容並刪除，後續訊息不觸發

---

## 相關 Skills 與檔案

- **呼叫**：`/clear`（內建指令；`/clean` 引導使用者執行）
- **被呼叫**：`/commit-push` Step 9（自動摘要與 `/clear` 提示）、Stop hook `check_context_reminder.cjs`（偵測舊摘要並提醒）
- **共用資源**：`.local/context_summary/`（工作摘要 + `current_topic.md`）、`.local/resumption_prompt.md`（由 `hooks/inject_context_on_resume.cjs` 注入）
- **改名歷史（本 skill 自身）**：繼承原 `context-guard` skill 的職責（已合併入 `/clean`）；全域改名請見 `_bootstrap/RENAME_HISTORY.md`
