---
name: Commit Message 與 Modify Log 嚴格格式
description: 11 個 prefix、動態 Co-Author、modify_log 原版標準模板（+N -M 空格格式、章節順序固定）
type: feedback
originSessionId: dddfa0de-6667-4adc-83a2-bc6db4a98bad
---
## Commit Message 格式

**Prefix 集合（11 個，完整 Conventional Commits）**：
`feat / fix / ui / docs / refactor / test / chore / perf / build / ci / revert`

完整對照表與範例見 `sekai-workflow/commit-push/references/commit-conventions.md`。

**格式規則**：
- 第一行：`<type>: <短摘要>`，72 字元以內
- 空行
- Body：bullet points 要點列表
- 空行
- Co-Authored-By 行

**動態 Co-Author**（根據實際執行 model）：
- Sonnet → `Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>`
- Opus → `Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>`
- Haiku → `Co-Authored-By: Claude Haiku 4.5 <noreply@anthropic.com>`
- 多 model 協作 → 最多兩行（主執行者 + 次要貢獻者）
- **禁止**無版本字串 `Claude <noreply@anthropic.com>`

## Modify Log 格式（對齊使用者 `.\modify_log\` 原版標準模板）

**檔名**：`.local/modify_log/YYMMDD_主題描述.md`（6 位日期 + 描述性主題）

**章節順序固定**（與重構後版本不同，必須對齊原版）：

```markdown
# [標題 — 一句描述]

## 基本資訊
- **日期時間**：YYYY-MM-DD HH:MM
- **Git 版本**：`<short-hash>`
- **更動原因**：<動機>

## 影響檔案
| 檔案 | 變更行數 | 說明 |
|------|---------|------|
| `path/to/file` | +N -M | 做了什麼、為什麼 |

## 影響範圍
- 模組 / 容器重啟 / DB migration

## 技術說明（可選）
## 潛在風險（可選）
```

**關鍵格式特徵**（重構時遺失，必須精準對齊原版）：
1. 行數格式 **`+N -M`**（空格分隔，**不是** `+N/-M`）
2. 章節順序：**影響範圍在技術說明之前**（與 `/build log` 中間版本順序相反）
3. 欄位命名：**Git 版本**（非「版本」）
4. 所有日誌 **僅存本地**，永不入版控
5. 語言對齊專案慣例（本專案台灣繁體中文）
6. 非顯而易見變更附 code snippet；before/after 用表格；資料流用 ASCII 圖

**Why:** 2026-04-15 對話中，使用者檢查出 `sekai-workflow` refactor `4c878a5`（17→6 合併）遺失多項 commit / modify log 細節，包括原版 modify-log `## Rules` 段、`+N -M` 格式、章節順序、checkmark 動態 Co-Author 規則。使用者提供 `.\modify_log\` 目錄 48 份實例作為 ground truth，明示必須對齊原版。

**How to apply:**
- 每次 `/commit-push` Step 5 產出 log → 使用上述標準模板
- 每次 commit → 依執行 model 選 Co-Author 字串
- 每次建立新 log 檔名 → YYMMDD（6 位）+ 主題（繁中可）
- 若發現現有 modify log 格式不一致 → 以此規則為準統一修正
