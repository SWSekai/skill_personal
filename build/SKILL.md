---
name: dev
description: "開發全流程一站式入口：需求分析 → 方案設計 → 實作 → 測試 → 品質檢查 → commit → push → 重啟評估。子命令路由 flow / plan / impl / test / commit / quality / log / restart / eval。"
model: sonnet
effort: medium
argument-hint: "<flow|plan|impl|test|commit|quality|log|restart|eval> [args...]"
allowed-tools: Read, Write, Edit, Glob, Grep, Agent, Bash(git *), Bash(docker *), Bash(ls *), Bash(date *), Bash(sleep *), Bash(mkdir *), Bash(npm *), Bash(npx *), Bash(pytest *), Bash(python *)
---

# /dev — 開發全流程 Skill

涵蓋從需求分析到部署的完整開發生命週期。透過第一個參數決定子命令。

## 子命令路由

### 開發前期（需求 → 實作 → 驗證）

| 子命令 | 用途 |
|---|---|
| `/dev flow <feature>` | **全流程串接**：plan → impl → test → commit，自動銜接每個階段 |
| `/dev plan <feature>` | 需求分析 + 方案設計 + 步驟拆解，產出方案文件 |
| `/dev impl [plan-ref]` | 按方案逐步實作，自動勾對進度、偵測偏離 |
| `/dev test [scope]` | 測試驗證：自動跑測試 + 手動 checklist + 邊界情境 |

### 提交後期（品質 → commit → 部署）

| 子命令 | 用途 |
|---|---|
| `/dev commit [msg]` | 完整提交流程（品質檢查 → 日誌 → README → commit → push → 重啟評估） |
| `/dev quality [files...]` | 獨立品質審計（commit 前由 commit 子命令自動觸發） |
| `/dev log [topic]` | 建立 / 更新本地修改日誌 |
| `/dev restart [services...]` | 執行容器重啟與自動修復 |
| `/dev eval [commit-range]` | 僅評估哪些容器需重啟 / 重建（不執行） |

無參數時預設執行 `commit`。

---

## F. `/dev flow` — 全流程串接

**自動銜接** plan → impl → test → commit 四個階段，中間不需手動呼叫下一步。

### 流程

```
/dev flow <feature description>
    │
    ├─ Step 1: /dev plan（方案設計）
    │   └─ 使用者透過 AskUserQuestion 確認方案
    │       ├─ 確認 → 進入 impl
    │       └─ 修改 → 調整方案後重新確認
    │
    ├─ Step 2: /dev impl（逐步實作）
    │   └─ 所有步驟完成
    │
    ├─ Step 3: /dev test（測試驗證）
    │   └─ 全部通過
    │       ├─ 是 → 進入 commit
    │       └─ 否 → 列出失敗項，回到 impl 修復
    │
    └─ Step 4: /dev commit（提交推送）
        └─ 完成
```

### 中斷與恢復

- 任何階段中斷後，方案文件保留在 `.local/docs/plans/`
- 恢復方式：`/dev impl <plan-file>` 從上次進度繼續
- 方案文件中的 checkbox 記錄完成狀態，中斷後可識別未完成步驟

---

## G. `/dev plan` — 需求分析與方案設計

收到功能訴求時，**先設計完整方案，確認後才實作**（對齊 CLAUDE.md 核心規則）。

### Step 1：需求理解

1. **解析使用者描述**：提取核心功能訴求、驗收標準、約束條件
2. **釐清模糊點**：使用 AskUserQuestion 追問不明確的需求
   - 只問真正影響方案方向的問題
   - 可由程式碼推導的細節不問，直接在方案中說明假設

### Step 2：現況掃描

1. **相關程式碼**：Grep / Glob 找出與需求相關的現有實作
2. **架構認識**：讀 compose、package.json、目錄結構，理解系統分層
3. **DB schema**：若涉及資料面，掃描 models / migrations / collection 定義
4. **相關 API**：找出會被影響的 endpoint、前端呼叫點

### Step 3：影響範圍評估

| 維度 | 檢查內容 |
|---|---|
| 檔案影響 | 列出所有需新增 / 修改的檔案 |
| 服務影響 | 哪些 container / service 會被動到 |
| DB 影響 | 是否需要新增 collection / table / column / index |
| API 影響 | 新增或修改哪些 endpoint、request / response 結構 |
| 前端影響 | 哪些頁面 / 元件需要調整 |
| 向下相容 | 既有功能是否會受影響 |

### Step 4：方案設計

**若存在多種做法**：列出替代方案與優缺點比較表

```markdown
| 方案 | 說明 | 優點 | 缺點 |
|---|---|---|---|
| A | ... | ... | ... |
| B | ... | ... | ... |
```

**最終方案**需包含：
- 技術選型與理由
- 資料流設計（若涉及跨服務）
- 錯誤處理策略
- 效能考量（若涉及大量資料）

### Step 5：步驟拆解

將方案拆成**可逐步執行的實作清單**，每步對應具體的程式碼變更：

```markdown
## 實作步驟

- [ ] §1 建立 DB model / schema
  - 檔案：`backend/models/xxx.py`
  - 新增：XxxModel class，欄位定義
  
- [ ] §2 建立 API endpoint
  - 檔案：`backend/routers/xxx.py`
  - 新增：GET /api/xxx, POST /api/xxx
  - 依賴：§1

- [ ] §3 前端頁面
  - 檔案：`frontend/src/pages/xxx.vue`
  - 新增：列表頁 + 表單
  - 依賴：§2
```

每步須標明：
- 目標檔案與行為（新增 / 修改）
- 依賴關係（§ 編號互引）
- 預估影響行數（粗略即可）

### Step 6：方案確認

使用 **AskUserQuestion** 向使用者呈現方案：
- 第一選項：`開始執行 (Recommended)`
- 第二選項：`我要調整`（進入修改流程）
- 第三選項：`換方案`（若有替代方案）

確認後：
1. 將方案寫入 `.local/docs/plans/YYMMDD_<feature>.md`
2. 若在 `/dev flow` 中 → 自動進入 `/dev impl`
3. 若獨立呼叫 → 告知使用者「方案已存，可用 `/dev impl` 開始實作」

---

## H. `/dev impl` — 按方案實作

### 使用方式

| 用法 | 行為 |
|---|---|
| `/dev impl` | 讀取最近的方案文件，從未完成步驟繼續 |
| `/dev impl <plan-file>` | 指定方案文件 |
| 由 `/dev flow` 串接進入 | 自動帶入剛確認的方案 |

### Step 1：載入方案

1. 讀取方案文件（`.local/docs/plans/YYMMDD_<feature>.md`）
2. 解析實作步驟清單與 checkbox 狀態
3. 找到第一個未勾選（`- [ ]`）的步驟作為起始點
4. 若全部已勾 → 告知實作已完成，提示 `/dev test`

### Step 2：逐步執行

對每個步驟：

1. **宣告正在執行的步驟**（一句話告知使用者）
2. **讀取相關檔案**：先理解現有程式碼
3. **執行實作**：按方案描述新增或修改程式碼
4. **偏離偵測**：
   - 若實作過程發現方案有誤或遺漏 → 暫停，向使用者說明偏離原因
   - 使用者確認調整方向後，**更新方案文件**再繼續
5. **勾對完成**：在方案文件中將 `- [ ]` 改為 `- [x]`，附 timestamp

```markdown
- [x] §1 建立 DB model / schema ✓ 2026-04-10 14:30
```

6. **衍生任務**：若實作過程發現額外需要做的事：
   - 屬於本功能範圍 → 在方案文件末尾新增步驟
   - 不屬於本功能 → 加入 `.local/collab/TODO.md`（標 `derived from: <feature>`）

### Step 3：實作完成

所有步驟勾對後：

1. 更新方案文件狀態為 `## 狀態：實作完成`
2. 列出實作摘要（修改了哪些檔案、新增了什麼）
3. 若在 `/dev flow` 中 → 自動進入 `/dev test`
4. 若獨立呼叫 → 提示「實作完成，建議 `/dev test` 驗證」

---

## I. `/dev test` — 測試驗證

### 使用方式

| 用法 | 行為 |
|---|---|
| `/dev test` | 自動偵測專案測試框架，跑全部 + 手動 checklist |
| `/dev test <scope>` | 只跑指定範圍的測試 |
| 由 `/dev flow` 串接進入 | 自動執行 |

### Step 1：偵測測試框架

掃描專案結構判斷可用的測試工具：

| 偵測條件 | 測試框架 | 執行指令 |
|---|---|---|
| `pytest.ini` / `pyproject.toml[tool.pytest]` / `tests/` | pytest | `pytest --tb=short` |
| `jest.config.*` / `package.json[jest]` | Jest | `npx jest` |
| `vitest.config.*` | Vitest | `npx vitest run` |
| `cypress/` / `playwright/` | E2E | 列出但不自動執行 |
| 無測試框架 | — | 跳至 Step 3 手動 checklist |

### Step 2：執行自動化測試

```bash
# 依偵測結果選擇
pytest --tb=short -q 2>&1 | tail -20
# 或
npx jest --ci 2>&1 | tail -30
```

**結果處理**：
- 全通過 → 進 Step 3
- 有失敗 → 列出失敗的 test case 與錯誤訊息，分析原因：
  - **實作 bug** → 標記需修復的檔案和行號
  - **測試本身過時** → 說明需要更新測試
  - **環境問題** → 說明需要的環境配置

### Step 3：手動驗證 Checklist

根據方案文件（若存在）或本次改動，生成需人工驗證的清單：

```markdown
## 手動驗證 Checklist

### 功能驗證
- [ ] 核心功能正常運作（描述具體操作步驟）
- [ ] 相關聯功能未受影響

### 邊界情境
- [ ] 空值 / null 輸入
- [ ] 超長字串 / 超大數值
- [ ] 並行操作（多使用者同時觸發）
- [ ] 網路中斷 / 外部服務不可用

### UI 驗證（若有前端變更）
- [ ] 不同解析度 / 瀏覽器
- [ ] Loading 狀態與錯誤提示

### 安全性
- [ ] 權限控制（未授權使用者不可存取）
- [ ] 輸入驗證（無 injection 風險）
```

**僅列出與本次改動相關的項目**，不列無關的 boilerplate。

### Step 4：測試報告

```markdown
## 測試結果

| 類別 | 結果 | 備註 |
|---|:---:|---|
| 自動化測試 | ✓ 32 passed | pytest |
| 手動 checklist | ◯ 待驗證 | 5 項需人工確認 |
| 邊界情境 | ✓ 已確認 | 無風險 |
```

**流程決策**：
- 自動化全通過 + 無 High 風險 → 可進入 commit
- 有失敗 → 若在 `/dev flow` 中：回到 impl 修復 → 重測
- 有手動 checklist 待驗證 → 提示使用者完成後再 commit

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
3. 告知使用者「已寫入 `.local/docs/<guide>.md`，/admin pack 時會帶走」

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
