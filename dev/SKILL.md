---
name: dev
description: "開發流程一站式入口：commit-push、品質檢查、修改日誌、容器重啟評估與執行。子命令路由 commit / quality / log / restart。"
model: sonnet
effort: medium
argument-hint: "<commit|quality|log|restart|eval> [args...]"
allowed-tools: Read, Write, Edit, Glob, Grep, Agent, Bash(git *), Bash(docker *), Bash(ls *), Bash(date *), Bash(sleep *), Bash(mkdir *)
---

# /dev — 開發流程合併 Skill

整合提交流程、品質審計、修改日誌、容器生命週期五項職能。透過第一個參數決定子命令。

## 子命令路由

| 子命令 | 用途 | 對應原 Skill |
|---|---|---|
| `/dev commit [msg]` | 完整提交流程（品質檢查 → 日誌 → README → commit → push → 重啟評估） | commit-push |
| `/dev quality [files...]` | 獨立品質審計（commit 前由 commit 子命令自動觸發） | quality-check |
| `/dev log [topic]` | 建立 / 更新本地修改日誌 | modify-log |
| `/dev restart [services...]` | 執行容器重啟與自動修復 | restart-volumn |
| `/dev eval [commit-range]` | 僅評估哪些容器需重啟 / 重建（不執行） | restart-eval |

無參數時預設執行 `commit`。

---

## A. `/dev commit` — 完整提交流程

依序執行以下步驟，**不可跳步**。

### Step 1：品質檢查（呼叫 `/dev quality`）

進入 B 區的 quality 子命令邏輯，對暫存／工作區內所有改動執行：
- 死碼、冗餘、硬編碼掃描
- 架構一致性檢查
- 上下游影響評估
- 風險報告（High／Medium／Low）
- 實作後資料流重讀（Step 5c）

若出現 High 風險或 ✗ 項目，**停止 commit**，先修復。

### Step 2：自動更新 README.md

掃描變更檔所屬目錄，若該目錄含 `README.md` 且結構/功能受影響，同步更新。  
**新增功能性目錄** → 建立 README，包含用途、檔案結構、關鍵功能。

### Step 3：狀態總覽與 staging

```bash
git status
git diff --stat
git log --oneline origin/$(git rev-parse --abbrev-ref HEAD)..HEAD
```

向使用者列出：
- 未暫存修改（含一句話摘要）
- 已暫存未 commit
- 已 commit 未 push

讀取 `.gitignore` 確認待 stage 檔案不在忽略清單。**禁止使用 `git add -f` 或 `git add -A`**，僅 stage 具體檔名。

### Step 4：Commit

採 Conventional Commits 風格，HEREDOC 格式，附 `Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>`。Prefix 用 `feat / fix / ui / docs / refactor`。

### Step 5：建立修改日誌（呼叫 `/dev log`）

進入 C 區的 log 子命令邏輯，使用剛產生的 commit hash，寫入 `.local/modify_logs/YYMMDD_TopicDescription.md`。**僅本地，不入版控**。

### Step 6：Push

```bash
git push
```

push 失敗時報告錯誤與建議，不嘗試 `--force`。

### Step 7：同步 `.skill_personal/` 至遠端

若本次有變更 `.skill_personal/` 內容：

```bash
cd .skill_personal
git add <files>
git commit -m "<mirrored message>"
git push
```

push 失敗 → 告知使用者，不阻塞主流程。

### Step 8：服務重啟評估（呼叫 `/dev eval`）

進入 E 區的 eval 子命令邏輯，輸出指令清單。若有需重啟服務，提示可直接 `/dev restart` 執行。

### Step 9：經驗回流至 guide

若本次改動含**非顯而易見的根因、繞道方法、設定差異**：
1. 加入或新建 `.local/docs/<guide>.md`
2. 格式：**症狀 → 原因 → 解決方式 → 注意事項**
3. 告知使用者「已寫入 `.local/docs/<guide>.md`，/skill pack 時會帶走」

---

## B. `/dev quality` — 品質審計

可獨立呼叫，亦由 commit 子命令在 Step 1 觸發。

### 1. 掃描項目

對每個改動檔檢查：
- **死碼**：未用 import、不可達分支、註解掉的程式碼
- **冗餘**：跨檔重複邏輯、應抽象的 copy-paste
- **硬編碼**：應放 config/constants 的魔術值
- **錯誤處理**：系統邊界（API、外部呼叫、檔案 IO）的 try/catch
- **型別一致性**：跨層資料型別不符
- **序列化風險**：JSON/protobuf/form 過程可能遺失的欄位
- **安全性**：SQL injection、XSS、命令注入、敏感資訊外洩、OWASP Top 10

### 2. 架構一致性

讀取同目錄 3-5 個既有檔案理解慣例（命名、錯誤處理、log 風格、回應格式），條列偏離項並附既有範例。

### 3. 影響評估

| 維度 | 問題 |
|---|---|
| Upstream | 誰呼叫這個 function/endpoint？會壞嗎？ |
| Downstream | 此函式呼叫誰？契約還有效嗎？ |
| State | 是否動到 DB schema、cache key、檔案路徑、env var？ |
| Concurrency | 多 user/multi-worker 下會有 race condition 嗎？ |
| Backward compat | 既有 DB 紀錄、saved config、cache value 還能用嗎？ |
| API contract | request/response shape 變了，所有 client 都更新了嗎？ |

### 4. 風險報告

| Severity | File | Description | Mitigation |
|---|---|---|---|
| High / Med / Low | ... | ... | ... |

- **High**：可能造成資料遺失、crash、安全漏洞
- **Medium**：可能造成行為錯誤或效能退化
- **Low**：code smell 或小不一致

無風險時明確輸出：「品質檢查通過，無風險」

### 5. Skill 完整性檢查（若改動 Skill 檔案）

每個 skill 資料夾須有 `SKILL.md` + `README.md`；`.claude/skills/README.md`、`CLAUDE.md`「可用 Skills」、`.skill_personal/manifest.json` 同步更新。

### 5c. 實作後資料流重讀

實作完畢、commit 前**重新讀取**修改過的程式碼，逐層走一次：

| 檢查項 | 結果 | 備註 |
|---|:---:|---|
| 資料流完整性 | ✓/✗ | |
| 跨層型別一致 | ✓/✗ | |
| 邊界情境處理 | ✓/✗ | |
| 未動邏輯不受影響 | ✓/✗ | |

任一 ✗ 必須先修，才能進入 commit 流程。

---

## C. `/dev log` — 修改日誌

由 commit 子命令於 Step 5 自動呼叫，亦可手動使用。**所有日誌僅存本地，永不入版控**。

### 檔名

`.local/modify_logs/YYMMDD_TopicDescription.md`（同日同主題 → 更新該檔；不同主題 → 另建）

### 內容

```bash
git log --oneline -1
git diff --stat HEAD~1
git diff --numstat HEAD~1
```

```markdown
# [標題]

## 變更資訊
- **日期時間**：YYYY-MM-DD HH:MM
- **版本**：`<git-short-hash>`
- **更動原因**：[動機 / 問題描述 / 需求來源]

## 變更明細
| 檔案 | 影響行數 | 說明 |
|---|---|---|

## 技術說明
（資料流、邏輯、架構決策）

## 影響範圍
- 受影響模組／功能
- 容器重啟需求（若有）
- DB migration 需求（若有）

## 潛在風險
- 邊界情境或相容性議題
- 無風險時：「無已知風險」
```

語言對齊專案慣例（vision-ai 為台灣繁體中文）。

---

## D. `/dev restart` — 容器重啟與自動修復

執行容器重啟/重建的完整生命週期。可在 `/dev eval` 後接續執行。

### Step 1：決定重啟目標

- 無參數 → 從 `git diff --name-only HEAD~1` + `docker-compose.yml` 自動推導
- `/dev restart all` → 全部容器
- `/dev restart svc1 svc2` → 指定服務

列出目標後**直接執行**，不發確認訊息（讓 tool permission UI 處理）。

### Step 2：Pre-flight

```bash
docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Service}}"
```

- **背景任務檢查**（worker / queue 服務）：偵測 Celery / Sidekiq / Bull 等的 active task，有任務就警告
- **串流服務檢查**（WebSocket / RTSP / SSE）：警告連線會中斷
- **掛載類型判斷**：volume mount → restart；image baked → build + up

### Step 3：執行

```bash
# Volume mount
docker compose restart <svc>

# Image baked
docker compose build <svc1> <svc2>
docker compose up -d <svc1> <svc2>
```

### Step 4：健康檢查

```bash
sleep 8
docker compose ps | grep -E "<services>"
```

期望 `Up X seconds (healthy)`；若 `Restarting` / `Exited` → 進 Step 5。

### Step 5：日誌掃描

```bash
docker compose logs --tail=30 <service>
```

| Keyword | Severity |
|---|---|
| `Error` / `ERROR` | HIGH |
| `ImportError` / `ModuleNotFoundError` / `Cannot find module` | HIGH |
| `ConnectionRefusedError` | MEDIUM |
| `WARNING` | LOW |
| `Application startup complete` / `Listening on` / `ready` | OK |

### Step 6：自動修復

| 症狀 | 自動修復 | Fallback |
|---|---|---|
| ImportError / Module not found | `docker compose build --no-cache <svc>` | 釘版本 |
| ConnectionRefused | `docker compose up -d --wait <dep>` → restart | 查 dep log |
| Port 衝突 | `docker compose down <svc>` → `up -d` | 找 PID kill |
| DB migration error | 報告需要的 DDL | 手動執行 |
| 無法自動修復 | 完整 log 摘要 + 根因 + 手動修復步驟 | — |

### Step 7：最終驗證

- API 健康：`curl http://localhost:<port>/health` 或 `/docs`
- Worker 連線：`celery -A <app> inspect ping`

輸出：

```
| Service | Action | Status | Duration |
|---|---|---|---|
```

---

## E. `/dev eval` — 重啟評估（不執行）

僅做評估，輸出指令清單，使用者再決定是否 `/dev restart`。

### Step 1：找出變更檔

```bash
git diff --name-only HEAD~1     # 預設
git diff --name-only $RANGE      # 若 $ARGUMENTS 是 commit range
```

### Step 2：讀 compose 拓撲

```bash
cat docker-compose.yml 2>/dev/null || cat compose.yml 2>/dev/null
```

對每個 service 判斷：volume mount paths / baked-in paths / auto-reload 能力 / 靜態檔案。

### Step 3：分類

| Mount type | Auto-reload | Action |
|---|---|---|
| Volume mount | yes (`--reload`) | 不需動作 |
| Volume mount | no | `docker compose restart <svc>` |
| Baked image | N/A | `build + up -d` |
| 靜態檔（web server） | N/A | 瀏覽器重整 |
| DB init script | N/A | 手動 migration |
| Dockerfile | N/A | rebuild |
| compose 檔本身 | N/A | `docker compose up -d` |

### Step 4：輸出

1. 變更檔 → 服務 → 動作 對照表
2. 去重後的指令清單，按執行順序
3. 副作用警告（停機、連線中斷、job 中斷）
4. 若 DB init script 改動且 DB 已存在 → 列出需手動跑的 migration

### 非容器化專案

偵測 PM2 / systemd / supervisor / nodemon / watchdog / air，給對應重啟指令。

---

## 各子命令的 Model 使用建議

| 子命令 | 建議 effort |
|---|---|
| commit | medium（流程順序固定） |
| quality | high（需深度分析，必要時呼叫 Agent） |
| log | low（結構化填表） |
| restart | low |
| eval | low |

子命令本身共用 Skill model `sonnet`。需要更深思考時於該子命令內以 deeper thinking 完成。

Arguments: $ARGUMENTS （第一個 token 為子命令，其餘為該子命令參數）
