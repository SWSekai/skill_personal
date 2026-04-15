---
name: commit-push
description: "Commit & Push 獨立入口 — 品質檢查（Opus）→ 修改日誌（Haiku）→ README 同步 → commit → push → 重啟評估 → Context 清理。內建完整提交流程，所有日誌僅存本地不入版控。"
model: sonnet
effort: medium
argument-hint: "[commit 訊息覆蓋]"
allowed-tools: Read, Write, Edit, Glob, Grep, Agent, Bash(git *), Bash(ls *), Bash(date *), Bash(docker *)
---

# /commit-push — 完整提交推送流程

依序執行以下步驟，**不可跳步**。本 Skill 為**主要 commit 入口**，與 `/build` 其他子命令（flow / plan / impl / test / quality / log / review / deploy）互補。

**Model 分工（對應 CLAUDE.md 第 18 條）**：
- 本流程主體由 **Sonnet** 執行（標準開發任務、檔案讀寫、git 操作）
- Step 1「品質檢查」內嵌 **Opus** 深度分析（評估、規劃屬性）
- Step 5「修改日誌」內嵌 **Haiku** 結構化產出（純文字撰寫屬性）

---

## Step 1：品質檢查（內嵌 Opus 深度分析）

對暫存／工作區內所有改動執行完整品質審計。此步驟建議透過 Agent 工具呼叫 Opus 子任務以取得深度分析能力。

### 1.1 掃描項目

對每個改動檔檢查：

- **死碼**：未用 import、不可達分支、註解掉的程式碼
- **冗餘**：跨檔重複邏輯、應抽象的 copy-paste
- **硬編碼**：應放 config / constants 的魔術值
- **錯誤處理**：系統邊界（API、外部呼叫、檔案 IO）的 try/catch
- **型別一致性**：跨層資料型別不符
- **序列化風險**：JSON / protobuf / form 過程可能遺失的欄位
- **安全性**：SQL injection、XSS、命令注入、敏感資訊外洩、OWASP Top 10

### 1.2 架構一致性

讀取同目錄 3–5 個既有檔案理解慣例（命名、錯誤處理、log 風格、回應格式），條列偏離項並附既有範例。

### 1.3 影響評估（Upstream / Downstream 矩陣）

| 維度 | 問題 |
|---|---|
| Upstream | 誰呼叫這個 function / endpoint？會壞嗎？ |
| Downstream | 此函式呼叫誰？契約還有效嗎？ |
| State | 是否動到 DB schema、cache key、檔案路徑、env var？ |
| Concurrency | 多 user / multi-worker 下會有 race condition 嗎？ |
| Backward compat | 既有 DB 紀錄、saved config、cache value 還能用嗎？ |
| API contract | request / response shape 變了，所有 client 都更新了嗎？ |

### 1.4 風險報告

| Severity | File | Description | Mitigation |
|---|---|---|---|
| High / Med / Low | ... | ... | ... |

- **High**：可能造成資料遺失、crash、安全漏洞 → **停止 commit**，先修復
- **Medium**：可能造成行為錯誤或效能退化 → 告知使用者，請其決定是否阻斷
- **Low**：code smell 或小不一致 → 僅回報，不阻斷

無風險時明確輸出：「品質檢查通過，無風險」

### 1.5 Skill 更新提示（新模式偵測）

若本次改動引入**新的慣例、模式或工作流程需求**：

- 直接執行對應的 SKILL.md Edit，由 Tool Confirmation UI 處理 approve / deny（對齊 CLAUDE.md 第 15 條）
- **禁止**使用文字詢問「是否要更新 Skill 定義？」

### 1.6 Skill 完整性檢查（若改動 Skill 檔案）

若本次變更動到任何 SKILL.md / README.md / 新建 Skill 資料夾，逐項驗證：

1. **每個 skill 資料夾**同時含 `SKILL.md` 與 `README.md`
2. **Skills README 三段同步**：
   - `.claude/skills/README.md` 的命令總覽表已更新
   - 詳細描述段落已更新
   - 目錄結構樹已更新
3. **通用 vs 專案專屬判斷樹**：
   - 通用改進（不綁專案細節）→ 同步至 `sekai-workflow/`，**剝除所有專案特化硬編碼值**
   - 專案專屬修正 → 僅存 `.claude/skills/`，**不同步**
4. **通用 skills README** (`sekai-workflow/README.md`) 已更新
5. **CLAUDE.md 的「可用 Skills」列表**已更新
6. **明示聲明**：Skill 變更走 `sekai-workflow` 獨立遠端倉庫（`https://github.com/SWSekai/sekai-workflow.git`），**不進專案 git**

任一項未符合 → 停止 commit，要求使用者補齊。

### 1.7 實作後資料流重讀

實作完畢、commit 前**重新讀取**修改過的程式碼，逐層走一次：

| 檢查項 | 結果 | 備註 |
|---|:---:|---|
| 資料流完整性 | ✓/✗ | |
| 跨層型別一致 | ✓/✗ | |
| 邊界情境處理 | ✓/✗ | |
| 未動邏輯不受影響 | ✓/✗ | |

任一 ✗ 必須先修，才能進入 commit 流程。

---

## Step 2：自動更新 README.md

掃描變更檔所屬目錄，若該目錄含 `README.md` 且結構 / 功能受影響，同步更新。

**新增功能性目錄** → 建立 README，包含：
- 目錄用途
- 檔案 / 子目錄結構
- 關鍵功能概述

---

## Step 3：狀態總覽與 staging

### 3.1 顯示完整待處理狀態

```bash
git status
git diff --stat
git log --oneline origin/$(git rev-parse --abbrev-ref HEAD)..HEAD
```

向使用者列出：

- **未暫存修改**：每檔附一句話摘要
- **已暫存未 commit**：同上
- **已 commit 未 push**：列出 commit hash + message
- 若完全沒有待處理 → 告知使用者並停止

### 3.2 讀取 `.gitignore` 確認安全

讀取 `.gitignore`，確認即將 stage 的檔案不在忽略清單中。完整規則見 `references/gitignore-safety.md`。

**禁止指令**：
- `git add -f`（force 加入被忽略檔案）
- `git add -A` / `git add .`（可能意外加入敏感檔或二進位）

### 3.3 Stage 檔案

- 使用 `git add <file>` 具體檔名
- 含任何更新過的 README.md

### 3.4 直接進入 staging + commit（不額外發確認訊息）

列出摘要後**直接**執行 `git add` + `git commit`。使用者透過 Tool Confirmation UI 判斷 approve / deny（對齊 CLAUDE.md 第 15 條）。**禁止**發出「是否繼續？」「要我執行嗎？」等文字確認。

---

## Step 4：Commit

採 **Conventional Commits** 格式 + HEREDOC 模板。完整規範見 `references/commit-conventions.md`。

### 4.1 Prefix 集合（11 個）

`feat / fix / ui / docs / refactor / test / chore / perf / build / ci / revert`

詳見 `references/commit-conventions.md` 的類型對照表。

### 4.2 動態 Co-Author 規則

根據**實際執行此 commit 的 Skill model** 填入 Co-Author 字串：

| 執行情境 | Co-Author |
|---|---|
| 本 Skill（`/commit-push`）直接執行 | `Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>` |
| 前置階段由 `/build plan` / `/ask` 等 Opus Skill 產出主要決策 | 附加 `Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>` 為第二行 |
| 若改動主要為文字 / 日誌 / 文件類（本 Skill 內 Step 5 的 modify log） | log 區塊由 Haiku 產出，但 commit 本身仍以 Sonnet 為主 Co-Author |

### 4.3 格式規則

- 第一行：短摘要，72 字元以內
- 空行
- Body：要點列表（bullet points）
- 空行
- Co-Authored-By 行

範例：

```bash
git commit -m "$(cat <<'EOF'
feat: 新增 Teams 告警通知節點

- 整合 webhook 推送機制
- 新增 alert_cooldown 欄位
- 測試涵蓋 9/9 容器

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Step 5：建立修改日誌（內嵌 Haiku 結構化產出）

建議透過 Agent 工具呼叫 Haiku 子任務產生日誌（結構化文字撰寫屬性）。

**所有日誌僅存本地，永不入版控。**

### 5.1 檔名規則

`.local/modify_log/YYMMDD_主題描述.md`（6 位日期 + 具描述性主題名）

範例：`260313_video_h264_reencode.md`

- **同日同主題** → 更新該檔
- **不同主題** → 另建新檔

### 5.2 取得變更資訊

```bash
git log --oneline -1                    # 取得 commit hash
git diff --stat HEAD~1                  # 變更統計
git diff --name-only HEAD~1             # 變更檔案清單
git diff --numstat HEAD~1               # 每檔新增 / 刪除行數
```

### 5.3 日誌格式（對齊使用者原版標準模板）

```markdown
# [標題 — 一句描述本次變更]

## 基本資訊
- **日期時間**：YYYY-MM-DD HH:MM
- **Git 版本**：`<short-hash>`（例如 `9fe154c`）
- **更動原因**：[動機 / 問題描述 / 需求來源]

## 影響檔案
| 檔案 | 變更行數 | 說明 |
|------|---------|------|
| `path/to/file.py` | +12 -5 | 做了什麼、為什麼 |
| `path/to/file.js` | +30 -8 | 做了什麼、為什麼 |

## 影響範圍
- 受影響模組 / 功能
- 容器重啟需求（若有）
- DB migration 需求（若有）

## 技術說明
（非顯而易見的變更才寫：資料流、邏輯說明、架構決策）

## 潛在風險
- 邊界情境或相容性議題
- 若無：「無已知風險」
```

**關鍵格式特徵**：
- 行數格式 `+N -M`（空格分隔，**不是** `+N/-M`）
- 章節順序：**影響範圍在技術說明之前**
- 欄位名稱：**Git 版本**（非「版本」）

### 5.4 Rules

- 語言對齊專案慣例（本專案為台灣繁體中文）
- **非顯而易見的變更**附 code snippet
- **before / after 比較**用表格
- **資料流 / 決策邏輯**用 ASCII 圖（特別適合 sys-info 類交接 / 說明文件）
- 同日同主題 → 更新該檔而非新建
- **僅存本地，永不入版控**

---

## Step 6：Push

```bash
git push
```

Push 失敗時（auth / hook / remote error）報告錯誤與建議，**不嘗試 `--force`**，不嘗試 `--no-verify`。

---

## Step 7：同步 `sekai-workflow/` 至遠端

若本次有變更 `sekai-workflow/` 內容：

```bash
cd sekai-workflow
git add <files>
git commit -m "<mirrored message>"
git push
```

Push 失敗 → 告知使用者，不阻塞主流程。

**若改動到 SKILL.md / README.md**，同步自動更新：
- `sekai-workflow/manifest.json` — 對應 skill 條目
- `sekai-workflow/README.md` — 命令表與描述

---

## Step 8：服務重啟評估（呼叫 `/build deploy --plan`）

進入 `/build deploy` 的評估模式，輸出指令清單：

```bash
# 偽指令，實際由 /build deploy --plan 處理
git diff --name-only HEAD~1
docker compose config
```

輸出：變更檔 → 服務 → 動作對照表 + 去重指令清單 + 副作用警告。

若有需執行 → 提示可直接 `/build deploy --run` 執行。若無容器化 → 跳過。

---

## Step 9：Context 清理與摘要（自動執行）

完成 commit-push 流程後（含 modify log），主動管理 context：

### 9.1 執行 context-guard 摘要

遵循 `context-guard` Skill Step 2~3 邏輯：

1. 檢查 `.local/context_summary/` 是否已有**同日同主題**摘要：
   - 有 → 合併（附加新 commit 資訊到既有摘要）
   - 無 → 新建 `YYMMDD_HHMM_主題描述.md`
2. 更新 `current_topic.md` 紀錄當前工作主題
3. 摘要內容：進行中工作、已完成工作、未提交變更、待辦項、關鍵決策、容器重啟需求

### 9.2 建立 README.md（供使用者快速查找）

在 context summary 目錄建立或**覆寫** README.md：
- 目錄用途
- 既有摘要檔案清單（掃描目錄）
- 每份摘要的主題與日期
- 使用說明（如何還原 context、如何清理過期摘要）

### 9.3 提示使用者執行 `/clear` ✗ 無法自動化

`/clear` 為內建 CLI 指令，無法由 Claude 程式化觸發。摘要存檔後，提示使用者：「摘要已存，建議執行 `/clear` 釋放 context window」。

---

## Step 10：經驗回流至 guide

若本次改動含**非顯而易見的根因、繞道方法、設定差異**：

1. **判斷標準**：
   - 問題花了可觀時間診斷？
   - 根因非顯而易見（例如 auth hang、環境差異）？
   - 設定與文件 / 預設不同？
   - 工具 / 平台限制的 workaround？

2. **若是**，更新對應的 `.local/docs/guide/<topic>.md`：
   - 加入對應的 troubleshooting / FAQ 區塊
   - 格式：**症狀** → **原因** → **解決方式** → **注意事項**
   - 無對應 guide → 於 `.local/docs/guide/` 新建

3. **告知使用者**：「已將此經驗寫入 `.local/docs/guide/<topic>.md`，`/setup pack` 時會一併帶走。」

確保運維知識沉澱於可攜帶文件，而非丟在對話歷史中。

---

Arguments: $ARGUMENTS （可選的 commit 訊息覆蓋）
