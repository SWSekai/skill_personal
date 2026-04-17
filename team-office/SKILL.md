---
name: team-office
description: "互動協作一站式入口：AI TODO 處理、即時白板、Markdown 互動式決策表、技術筆記整理。子命令路由 todo / board / decide / notes。"
model: sonnet
effort: medium
argument-hint: "<todo|board|decide|notes> [args...]"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(git *), Bash(ls *), Bash(date *), Bash(mkdir *)
---

# /team-office — 互動協作合併 Skill

整合四種與使用者互動的協作模式。透過第一個參數決定子命令。

## 子命令路由

| 子命令 | 用途 | 對應原 Skill |
|---|---|---|
| `/team-office todo [add/list/<n>]` | 處理 AI TODO 清單 | todo |
| `/team-office board [topic]` | 即時白板（諮詢／規劃類對話） | whiteboard |
| `/team-office decide <topic>` | Markdown 互動式決策表 | md-collab |
| `/team-office notes [topic]` | 結構化技術筆記 | tech-notes |

無參數時要求使用者指定子命令。

---

## A. `/team-office todo` — AI TODO 處理

### 用法

| 用法 | 行為 |
|---|---|
| `/team-office todo` | 處理待辦項目（依優先度由高至低） |
| `/team-office todo add <desc>` | 快速新增（支援 `@high` / `@low`） |
| `/team-office todo list` | 列出所有待辦 |
| `/team-office todo <n>` | 處理指定編號 |

### Step 1：讀取與解析

讀取 `.local/collab/TODO.md`（或專案指定路徑），解析「Pending」區的所有項目，提取描述、優先度標籤、縮排筆記。  
若為 `add` / `list` → 執行對應分支後即結束。

### Step 2：排序與選擇

排序：`@high` → 無標 → `@low`；同優先度先進先做。列出排序後清單，請使用者選擇要處理哪幾項（預設第 1 項；可指定編號；可回 `all`）。

### Step 3：細節確認（追問）

**需追問**：描述模糊（「最佳化效能」→ 哪個服務？哪個 endpoint？）、有多種實作方式、範圍不明、缺驗收條件。  
**跳過追問**：已含具體檔案/函式/行為；bug fix 含錯誤訊息；筆記已足夠。

一次列完所有問題。使用者回「你決定」→ 依現有架構判斷，先一句話說明決策再執行。

### Step 4：執行

1. 將項目從 Pending 移到 In Progress：
   ```markdown
   ## In Progress
   - [~] description — processing (YYYY-MM-DD HH:MM)
   ```
2. 實際完成工作（讀程式碼、修改、遵循專案慣例）
3. 衍生任務 → 自動加入 Pending，標 `(derived from: ...)`
4. 遇阻 → 暫停、說明原因、移回 Pending 並標 blocker

### Step 5：完成

```markdown
## Completed
- [x] description — done YYYY-MM-DD HH:MM
  - commit: `hash` message
  - affected: file1, file2
```

選 `all` → 繼續下一項；否則詢問是否續做。

### Step 6：收尾

呈現處理摘要（完成 / 延後 / 衍生），有未 commit 變更時提示可呼叫 `/build commit`。

---

## B. `/team-office board` — 即時白板

諮詢、規劃、排錯類對話建立持續更新的 markdown，作為即時白板。

### 觸發

**自動觸發**：對話屬於系統諮詢、方案評估、問題排查、需追蹤多步進度的討論。  
**不觸發**：純程式碼修改、單次問答、已有明確 task 的執行工作。

### Step 1：建立白板

- 路徑：`.local/docs/whiteboard/YYMMDD_主題描述.md`
- 同主題同日 → 更新既存檔，不另開
- 結構原則：
  - **待辦**：純 checkbox 清單，一眼看完剩什麼要做
  - **操作步驟**：用 §編號與待辦對應的具體做法
  - **已完成**：精簡一行一項，已完成的操作步驟一併移除

初始模板可參考過往白板或自行設計（無需外部 asset）。

### Step 2：Follow-up 動態更新

每次使用者追問或繼續討論：

1. **Read** 既有白板
2. **Edit** 增量更新（不是覆寫）：
   - 新完成項：從待辦移到已完成，打勾
   - 新待辦：加入待辦事項區
   - 新決策：加入決策紀錄表
   - 新備註：追加到備註區
   - 更新「最後更新」日期
3. 討論方向轉變 → 新增章節，但保持同一份文件

### Step 3：結束與歸檔

1. 狀態改為 **已完成** 或 **暫停**
2. 確認所有待辦有負責人或後續計畫
3. 文件留在 `.local/docs/`，不入版控
4. 含可重用經驗 → 評估寫入 guide（同 `/build commit` Step 9）

### 設計原則

- 一個討論主題 = 一份文件
- 增量更新 > 覆寫
- 結構化 > 流水帳
- 即時性：每次回覆都應反映到文件
- 完成即收合：已完成步驟收合為 `~~標題~~ ✅ 已完成` + 一行結果

---

## C. `/team-office decide` — Markdown 互動式決策表

產生結構化 markdown 讓使用者勾選、Claude 讀回實作。

### Step 1：分析主題

- **掃描相關程式碼**：找出與主題相關的現有實作、設定檔、API
- **識別決策項目**：列出所有需使用者決定的項目
- **整理現狀**：每項記錄目前狀態作為參考欄位

### Step 2：生成互動式 Markdown

預設位置 `.local/docs/decision/<topic>.md`，使用者可指定。

格式規範：
- 核取方塊 `[ ]` / `[x]`
- **預填建議值**：根據分析結果預先勾選，降低使用者負擔
- **現狀欄位**：顯示目前實際狀態方便對比
- **編號連續**：跨區塊全域編號（方便口頭引用「第 17 項改成 B」）
- **分類分組**：相關項目歸入同區塊，區塊間以 `---` 分隔
- 表頭語義清楚（不要只用 A/B/C）
- **每個決策區塊末尾必須附 `補充說明` 欄位**（引用區塊或空 `> _（請填寫）_`），讓使用者於選項之外自由填寫情境、理由、反例；讀取決策時需一併解析該欄位內容
- **【強制】分支問題必須拆成可勾選選項**：任何有條件分支的問題（例：「資料可否外送？」下有 A/B/C 三種可能答案），必須列成多個互斥 `[ ]` 子項讓使用者勾選，**禁止**寫成 `[ ] 條件說明` 後留白要使用者自填字串（如 `[不可外送]`）。自由填寫格式僅限純數值／字串輸入題（如「每天處理幾份」）

支援四種互動模式：
- **單選矩陣**：每列一項目，每行一選項，每列勾一個
- **多選清單**：每項可勾多個 feature flag
- **自由填寫**：需要使用者輸入字串/數字
- **混合模式**：表格中混用單選與填寫欄位

### Step 3：引導使用者編輯

```
已建立互動式配置表：`<path>`

請開啟檔案，依照表頭說明勾選各項目的設定值。
預填值為根據現狀的建議配置，可自行調整。
完成後回覆「OK」或「完成」，我會讀取並實作。
```

### Step 4：讀取決策

1. 重新 Read 檔案
2. 解析勾選結果
3. 與現狀差異比對
4. 生成變更摘要表：

   ```markdown
   ## 變更摘要
   | # | 項目 | 現狀 | → 新值 |
   |---|---|---|---|
   | 3 | 標註圖片選單 | user | → view |
   ```

### Step 5：確認與實作

1. 展示變更摘要給使用者
2. 逐項實作（修改程式碼/設定）
3. 完成後回頭比對原始決策表，確保無遺漏

### Step 6：摘要持久化 + 清理決策文件（強制，不可跳過）

> **此步驟為強制執行**。Step 5 實作完成後，**必須在同一回覆中**完成摘要 + 刪除。
> 禁止：實作後直接回覆使用者而不寫摘要、將摘要留到下一回覆、等使用者提醒才補做。

**先摘要、再刪除**（對齊 CLAUDE.md 第 17 條）：

#### 6.1 建立摘要（必須）

寫入 `.local/docs/summary/YYMMDD_<topic>_summary.md`（永久保留）：

```markdown
# 摘要 — <主題>

> **建立日期**：YYYY-MM-DD
> **狀態**：✅ 已執行完成
> **Commits**：`<hash>`（若有）
> **原決策文件**：`.local/docs/decision/<filename>`（已刪除）

---

## 背景
（觸發原因，1~3 句）

## 最終決策
| § | 選項 | 採納 |
|---|---|---|
（每個決策區塊一行）

## 執行變更清單
| 檔案 | 變更 |
|---|---|

## 🔖 保留候選（未採納但可重啟）
（非單一路線決策才需要）
- **候選 X**：<描述>
  - 未選原因：...
  - 重啟時機：...

## 未解決遺留項
（若無則寫「無」）
```

#### 6.2 非單一路線判斷（必須）

判斷每組決策選項是否互斥：
- 選 A 就不能選 B → **單一路線** → 只記最終選擇
- 多個可共存 → **非單一路線** → 摘要中保留未選項（格式見上方模板）
- 候選清理：超過 6 個月未重啟或被新決策取代 → 標註「已作廢」，**不刪除**
- 新對話遇類似需求 → 先讀 summary/ 對應區塊的保留候選，能重啟就重啟

#### 6.3 刪除決策文件（必須）

- **主動刪除** `.local/docs/decision/<topic>.md`
- 決策文件為一次性產物，摘要才是持久紀錄
- 使用者若明示「保留決策紀錄」→ 跳過刪除並於回覆註明
- 需保留互動歷史（非決策結果）→ 改用 `/team-office board`（`whiteboard/` 類文件不刪除）

#### 6.4 自檢（必須）

Step 6 完成後，確認：
- [ ] `.local/docs/summary/YYMMDD_<topic>_summary.md` 已建立且非空
- [ ] 摘要包含：背景、決策表、變更清單、保留候選（若適用）、遺留項
- [ ] `.local/docs/decision/<topic>.md` 已刪除（或使用者明示保留）
- 任一未完成 → 立即補做，**不得結束回覆**

### 設計原則

- 降低認知負擔（預填合理值）
- 全域編號方便口頭引用
- 現狀可見
- 結構化輸出方便後續解析
- **一次性使用**：實作後立即清理；需長期追蹤請改用白板

---

## D. `/team-office notes` — 技術筆記整理

將對話中的技術問答整理成結構化筆記，存於 `.local/docs/tech-note/`。

### 觸發

**模式 A（手動，主要）**：使用者明確指定主題  
範例：「整理一篇 SQL JOIN 的技術筆記」「把剛才的 Git rebase 整理成文章」

**模式 B（偵測提醒，被動）**：偵測到對話含技術知識型問答時，**不直接生成**，先以訊息提醒：

> 偵測到可整理的技術主題：**{建議主題}**。正在整理技術筆記。

使用者確認後才執行。

### 輸出規範

- **路徑**：`.local/docs/tech-note/`
- **檔名**：`{主題類別}_{具體主題}.md`（例：`sql_comments.md`、`git_rebase.md`）
- **格式**：完整結構化文章，含目錄、架構、範例

```markdown
# {主題標題}

> 建立日期: YYYY-MM-DD | 最後更新: YYYY-MM-DD | 分類: {類別}

## 目錄
- [概述](#概述)
- [章節一](#章節一)

## 概述
這個技術是什麼、解決什麼問題、適用場景

## {章節一}
### {子章節}
語法說明 + 完整可執行的程式碼範例

## 常見陷阱與注意事項
## 最佳實踐
## 延伸閱讀
```

### 風格

- 依專案語言撰寫（預設對齊專案主要語言）
- 每個語法點附完整可執行範例
- 標註不同環境/資料庫差異
- 像教學文章而非筆記片段
- 由淺入深：基礎 → 進階

### 流程

1. 確認 `.local/docs/tech-note/` 存在
2. 檢查同主題文件 → 有則更新補充，無則新建
3. 撰寫完整結構化文章
4. 告知使用者檔案路徑

---

## E. `/team-office handoff` — 交接與環境轉換（Opus）

離開前（下班、休假、轉交專案、換環境）產出**兩類文件**：人類交接文件 + AI context bundle。環境**不破壞**（與 `/setup pack` 的差異：pack 會刪除 skill 環境）。

**本子命令屬於「評估 / 摘要 / 風險」屬性，建議透過 Agent 工具呼叫 Opus 子任務**（對齊 CLAUDE.md 第 18 條）。

### `/setup pack` vs `/team-office handoff` 差異

| 面向 | `/setup pack` | `/team-office handoff` |
|---|---|---|
| 目的 | Skill 退出歸檔 | 交接 / 環境轉換 |
| 環境 | **清除** .claude/skills/ + Sekai_workflow/ + CLAUDE.md | **保留**，環境不動 |
| 產出對象 | 機器（還原用 manifest） | 人（交接文件）+ AI（context bundle） |
| 產出位置 | `.local/ai-context/` | `.local/docs/handoff/` 或 `docs/handoff/`（`--share`）|
| 使用時機 | 專案結束、長期封存 | 週末下班、休假、同事接手、換開發機 |

### 觸發

| 用法 | 行為 |
|---|---|
| `/team-office handoff` | 產出至 `.local/docs/handoff/`（僅本機） |
| `/team-office handoff --share` | 產出至 `docs/handoff/`（入版控，同事可 pull） |

### Step 1：收集專案狀態

並行讀取以下資訊來源：

| 資訊 | 來源 | 用途 |
|---|---|---|
| 專案概要 | `CLAUDE.md` / 根目錄 `README.md` | 人讀 §A / AI bundle |
| 近期工作 | `.local/modify_log/*.md`（最近 10~20 份）| 人讀 §B |
| 待辦事項 | `.local/collab/TODO.md` | 人讀 §C |
| 進行中方案 | `.local/docs/plan/*.md`（未完成步驟）| 人讀 §C |
| 風險紀錄 | `.local/modify_log/` 的「潛在風險」段 | 人讀 §D |
| 環境架構 | `docker-compose.yml` / `.env` / config | 人讀 §E / AI bundle |
| Git 狀態 | `git status` / `git log origin..HEAD` / `git branch` | 人讀 §F |
| 決策歷史 | `.local/docs/summary/*.md` | AI bundle |
| Memory | `~/.claude/projects/<proj>/memory/*.md` | AI bundle |
| 經驗指南 | `.local/docs/guide/*.md` | AI bundle |
| Context 摘要 | `.local/context_summary/` 最新 | AI bundle |

### Step 2：產生人類交接文件（`YYMMDD_handoff.md`）

```markdown
# 專案交接文件

> 產生日期：YYYY-MM-DD HH:MM
> 產生者：Claude（/team-office handoff）
> 專案：<PROJECT_NAME>

---

## A. 專案概要

（從 CLAUDE.md / README 摘取 3~5 句，讓不熟悉的人快速了解專案做什麼）

## B. 當前進度

### 已完成（近期）
（從 modify_log 按功能分組，每組 1~2 句摘要）

| 功能領域 | 完成項目 | 最後 commit |
|---|---|---|

### 進行中
（WIP 分支、未完成的 plan 步驟、TODO 的 In Progress 項目）

## C. 預計辦理事項

### 優先順序建議
（從 TODO + plan 未完成步驟整合，依優先度排序）

| # | 項目 | 來源 | 優先度 | 預估複雜度 |
|---|---|---|---|---|

### 接手建議
（若是同事接手，建議從哪開始；若是自己回來，提醒最關鍵的接續點）

## D. 已知風險與阻塞

| 風險 | 來源 | 影響 | 建議處置 |
|---|---|---|---|

## E. 環境資訊

### Docker 服務
| 服務 | Port | 啟動指令 | 備註 |
|---|---|---|---|

### 關鍵連線
| 類型 | Key | 來源 | 值 |
|---|---|---|---|
| DB | DB_HOST | .env | *** |

（環境變數值一律 `***` 遮蔽，僅列 key + 來源；若專案無 Docker 則省略）

### 第三方整合
| 服務 | 用途 | 設定來源 |
|---|---|---|

## F. 如何恢復工作

1. **分支**：目前在 `<branch>`，upstream 為 `<remote/branch>`
2. **啟動服務**：`docker compose up -d`（列出需要的服務）
3. **未 push 變更**：有/無（若有，列出 commit）
4. **未提交變更**：有/無（若有，列出檔案）
5. **環境準備**：需設定的 env var / 需跑的 migration
6. **第一步**：接手後建議先做什麼（具體到檔案 + 行為）

## G. AI Context Bundle

此次交接同時產出 AI 可讀的 context bundle，位於同目錄下 `YYMMDD_ai-context/`。
新對話開始時可指示 AI 閱讀該目錄以快速恢復專案知識。
```

### Step 3：產生 AI Context Bundle（`YYMMDD_ai-context/`）

在交接文件同目錄下建立子目錄，收集 AI 快速掌握專案所需的全部資料：

```
YYMMDD_ai-context/
├── CLAUDE.md                  ← 專案規範快照
├── project-summary.md         ← AI 專用摘要（下方模板）
├── memory/                    ← Memory 快照（*.md）
├── decision-history/          ← .local/docs/summary/*.md 複製
├── guides/                    ← .local/docs/guide/*.md 複製
├── recent-modify-logs/        ← .local/modify_log/ 最近 10 份
├── todo-snapshot.md           ← .local/collab/TODO.md 複製
└── context-snapshot.md        ← .local/context_summary/ 最新摘要
```

#### `project-summary.md`（AI 專用，由 Opus 摘要產出）

```markdown
# AI Quick-Start：專案快速掌握指南

> 本文件供 AI（Claude）在新對話中快速恢復專案知識，非人類閱讀用。
> 產生日期：YYYY-MM-DD HH:MM

## 專案定位與架構
（從 CLAUDE.md + README 提煉：專案做什麼、技術棧、服務拓撲）

## 目前狀態
（WIP / 已完成里程碑 / 下一步）

## 決策歷史摘要
（從 .local/docs/summary/*.md 提煉每個決策的一行摘要 + 保留候選提示）

| 日期 | 決策 | 採納方案 | 有保留候選？ |
|---|---|---|---|

## 慣例與偏好
（從 Memory 提煉：commit 格式、語言偏好、model 分層、回流開關狀態等）

## 已知陷阱
（從 guides + modify_log 風險段提煉：遇過的坑 + 解法提示）

## 環境快照
（Docker / DB / env key 清單 — 值遮蔽）
```

### Step 4：輸出與確認

1. 寫入人類交接文件：
   - 預設：`.local/docs/handoff/YYMMDD_handoff.md`
   - `--share`：`docs/handoff/YYMMDD_handoff.md`
2. 寫入 AI context bundle 至同目錄下 `YYMMDD_ai-context/`
3. 告知使用者兩個產出的路徑
4. 若 `--share`：提示可 `git add docs/handoff/` 推送給同事
5. 提示：「新對話中可指示 AI 讀取 `YYMMDD_ai-context/` 目錄快速恢復知識」

### 設計原則

- **雙受眾**：人類文件（同事友善）+ AI 文件（新對話恢復知識）
- **環境不破壞**：與 `/setup pack` 最大差異 — handoff 後使用者可繼續工作
- **遮蔽敏感值**：環境變數只列 key，不列值
- **可行動**：每個區段結尾都有「下一步建議」
- **決策可追溯**：AI bundle 含完整決策歷史，新 AI 可查閱保留候選而非重新設計

---

Arguments: $ARGUMENTS （第一個 token 為子命令，其餘為該子命令參數）
