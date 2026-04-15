---
name: build
description: "開發全流程一站式入口：需求分析 → 方案設計 → 實作 → 測試 → 品質檢查 → review → deploy。Commit 推送走獨立 `/commit-push`。子命令路由 flow / plan / impl / test / quality / review / deploy。"
model: sonnet
effort: medium
argument-hint: "<flow|plan|impl|test|quality|review|deploy> [args...]"
allowed-tools: Read, Write, Edit, Glob, Grep, Agent, Bash(git *), Bash(docker *), Bash(ls *), Bash(date *), Bash(sleep *), Bash(mkdir *), Bash(npm *), Bash(npx *), Bash(pytest *), Bash(python *)
---

# /build — 開發全流程 Skill

涵蓋從需求分析到部署驗證的完整開發生命週期。透過第一個參數決定子命令。

**架構說明**：commit 流程已獨立為 `/commit-push`（主要入口）。`/build` 負責 commit **前**的開發工作與 commit **後**的部署驗證。

## 子命令路由

### 開發前期（需求 → 實作 → 驗證）

| 子命令 | 用途 | Model |
|---|---|---|
| `/build flow <feature>` | **全流程串接**：plan → impl → test → review → `/commit-push` → deploy | sonnet |
| `/build plan <feature>` | 需求分析 + 方案設計 + 步驟拆解，產出方案文件 | **opus** |
| `/build impl [plan-ref]` | 按方案逐步實作，自動勾對進度、偵測偏離 | sonnet |
| `/build test [scope]` | 測試驗證：自動跑測試 + 手動 checklist + 邊界情境 | sonnet |

### 提交前後（品質 → review → deploy）

| 子命令 | 用途 | Model |
|---|---|---|
| `/build quality [files...]` | 獨立品質審計（可獨立呼叫，`/commit-push` Step 1 亦會內嵌） | **opus** |
| `/build review` | Commit 前最後人工確認 checklist（大改動時強烈建議） | sonnet |
| `/build deploy [--plan\|--run] [services...]` | 合併重啟評估 + 執行。預設先列計畫再執行 | sonnet |

無參數時 → 要求使用者指定子命令。

**Commit 推送**：使用 `/commit-push`（獨立 Skill，內含品質檢查 / 修改日誌 / README / commit / push / deploy --plan / context 清理）。

---

## F. `/build flow` — 全流程串接

**自動銜接** plan → impl → test → review → `/commit-push` → deploy 六個階段，中間不需手動呼叫下一步。

### 流程

```
/build flow <feature description>
    │
    ├─ Step 1: /build plan（Opus 方案設計）
    │   └─ 使用者透過 AskUserQuestion 確認方案
    │       ├─ 確認 → 進入 impl
    │       └─ 修改 → 調整方案後重新確認
    │
    ├─ Step 2: /build impl（Sonnet 逐步實作）
    │   └─ 所有步驟完成
    │
    ├─ Step 3: /build test（測試驗證）
    │   └─ 全部通過
    │       ├─ 是 → 進入 review
    │       └─ 否 → 列出失敗項，回到 impl 修復
    │
    ├─ Step 4: /build review（人工最後確認 checklist）
    │   └─ 使用者勾選完成 → 進入 commit-push
    │
    ├─ Step 5: /commit-push（品質 → 日誌 → commit → push）
    │   └─ 完成
    │
    └─ Step 6: /build deploy（重啟評估 + 執行）
        └─ 完成
```

### 中斷與恢復

- 任何階段中斷後，方案文件保留在 `.local/docs/plans/`
- 恢復方式：`/build impl <plan-file>` 從上次進度繼續
- 方案文件中的 checkbox 記錄完成狀態，中斷後可識別未完成步驟

---

## G. `/build plan` — 需求分析與方案設計（Opus）

收到功能訴求時，**先設計完整方案，確認後才實作**（對齊 CLAUDE.md 核心規則）。

本子命令屬於「評估 / 規劃 / 架構決策」屬性，建議透過 Agent 工具呼叫 Opus 子任務（對齊 CLAUDE.md 第 18 條）。

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
2. 若在 `/build flow` 中 → 自動進入 `/build impl`
3. 若獨立呼叫 → 告知使用者「方案已存，可用 `/build impl` 開始實作」

---

## H. `/build impl` — 按方案實作（Sonnet）

### 使用方式

| 用法 | 行為 |
|---|---|
| `/build impl` | 讀取最近的方案文件，從未完成步驟繼續 |
| `/build impl <plan-file>` | 指定方案文件 |
| 由 `/build flow` 串接進入 | 自動帶入剛確認的方案 |

### Step 1：載入方案

1. 讀取方案文件（`.local/docs/plans/YYMMDD_<feature>.md`）
2. 解析實作步驟清單與 checkbox 狀態
3. 找到第一個未勾選（`- [ ]`）的步驟作為起始點
4. 若全部已勾 → 告知實作已完成，提示 `/build test`

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
3. 若在 `/build flow` 中 → 自動進入 `/build test`
4. 若獨立呼叫 → 提示「實作完成，建議 `/build test` 驗證」

---

## I. `/build test` — 測試驗證（Sonnet）

### 使用方式

| 用法 | 行為 |
|---|---|
| `/build test` | 自動偵測專案測試框架，跑全部 + 手動 checklist |
| `/build test <scope>` | 只跑指定範圍的測試 |
| 由 `/build flow` 串接進入 | 自動執行 |

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
- 自動化全通過 + 無 High 風險 → 可進入 review
- 有失敗 → 若在 `/build flow` 中：回到 impl 修復 → 重測
- 有手動 checklist 待驗證 → 提示使用者完成後再進 review

---

## B. `/build quality` — 品質審計（Opus）

獨立的深度品質審計入口。**建議透過 Agent 工具呼叫 Opus** 子任務（對齊 CLAUDE.md 第 18 條，品質分析屬於評估 / 思考屬性）。

`/commit-push` Step 1 會內嵌呼叫類似邏輯；此處提供獨立入口供「不想跑完整 commit 流程，只想做品質掃描」的情境。

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

### 5. Skill 更新偵測

若本次改動引入新的慣例、模式或工作流程需求：
- **直接執行對應 SKILL.md 的 Edit**，由 Tool Confirmation UI 處理 approve / deny（對齊 CLAUDE.md 第 15 條）
- **禁止**文字詢問「是否要更新 Skill 定義？」

### 5b. Skill 完整性檢查（若改動 Skill 檔案）

若本次變更動到任何 SKILL.md / README.md / 新建 Skill 資料夾，逐項驗證：

1. **每個 skill 資料夾**同時含 `SKILL.md` 與 `README.md`
2. **Skills README 三段同步**：
   - `.claude/skills/README.md` 的命令總覽表已更新
   - 詳細描述段落已更新
   - 目錄結構樹已更新
3. **通用 vs 專案專屬判斷樹**：
   - 通用改進（不綁專案細節）→ 同步至 `sekai-workflow/`，**剝除所有專案特化硬編碼值**
   - 專案專屬修正 → 僅存 `.claude/skills/`，**不同步**
4. **通用 skills README** 已更新
5. **CLAUDE.md 的「可用 Skills」列表**已更新
6. **明示聲明**：Skill 變更走 `sekai-workflow` 獨立遠端倉庫，**不進專案 git**

任一項未符合 → 停止流程，要求使用者補齊。

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

## R. `/build review` — Commit 前最後人工確認（Sonnet）

用於 **大改動前的最後 checklist 關卡**。與 `/build quality` 的差異：

| 差異點 | `/build quality` | `/build review` |
|---|---|---|
| 目的 | 深度程式碼品質掃描 | 架構 / 規則層人工確認 |
| Model | Opus | Sonnet |
| 輸出 | 風險報告 | 待確認 checklist |
| 是否阻斷 | High 風險會阻斷 | 僅列清單不阻斷 |
| 使用時機 | 每次 commit 都應跑 | 改到 CLAUDE.md / SKILL.md / 架構檔時 |

### Step 1：掃描變更檔

```bash
git status --short
git diff --stat
```

辨識**架構層變更**：
- `CLAUDE.md` — 專案規則
- `*/SKILL.md`、`*/README.md` — Skill 定義
- 根目錄 config（`docker-compose.yml`、`package.json`、`pyproject.toml`）
- Database schema / migrations

### Step 2：生成人工確認 Checklist

針對掃描結果，列出**本次改動可能需要同步更新但尚未處理**的項目：

```markdown
## Commit 前人工確認 Checklist

### 規則層同步（改到 CLAUDE.md / SKILL.md 時）
- [ ] 新規則是否已寫入 Memory（對齊 CLAUDE.md 第 9 條三向連動）
- [ ] 對應 SKILL.md 是否同步更新
- [ ] `.claude/skills/` 與 `sekai-workflow/` 是否雙向同步
- [ ] manifest.json 是否更新
- [ ] 可用 Skills 列表（CLAUDE.md 第 18 條後）是否更新

### 架構層同步（改到 config / schema 時）
- [ ] docker-compose 變更是否需更新部署文件
- [ ] DB schema 變更是否有對應 migration
- [ ] 環境變數新增是否有 .env.example 對應項

### 文件層同步
- [ ] 受影響目錄的 README.md 是否更新
- [ ] 若為新功能 → 是否有對應的 .local/docs/<guide>.md
```

### Step 3：互動確認

逐項詢問使用者（使用 AskUserQuestion 或直接列清單等回覆），未完成項目 → 回到對應 Skill 補齊後再進 commit-push。

**本子命令不阻斷 commit** — 只負責提醒。使用者可選擇「全部確認」直接跳過。

---

## D. `/build deploy` — 部署評估與執行（合併原 restart + eval）

**統一入口**，根據 flag 決定行為：

| 呼叫方式 | 行為 |
|---|---|
| `/build deploy` | **預設**：先 eval 列出計畫 → 等待確認 → 執行 restart |
| `/build deploy --plan` | 僅 eval 不執行（等同舊 `/build eval`） |
| `/build deploy --run` | 跳過 eval 直接執行（等同舊 `/build restart`） |
| `/build deploy svc1 svc2` | 指定服務 |
| `/build deploy --run all` | 全部容器 |

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

### Step 3：分類（Eval 階段）

| Mount type | Auto-reload | Action |
|---|---|---|
| Volume mount | yes (`--reload`) | 不需動作 |
| Volume mount | no | `docker compose restart <svc>` |
| Baked image | N/A | `build + up -d` |
| 靜態檔（web server） | N/A | 瀏覽器重整 |
| DB init script | N/A | 手動 migration |
| Dockerfile | N/A | rebuild |
| compose 檔本身 | N/A | `docker compose up -d` |

### Step 4：輸出計畫

1. 變更檔 → 服務 → 動作 對照表
2. 去重後的指令清單，按執行順序
3. 副作用警告（停機、連線中斷、job 中斷）
4. 若 DB init script 改動且 DB 已存在 → 列出需手動跑的 migration

### Step 5：Pre-flight（Run 階段）

```bash
docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Service}}"
```

- **背景任務檢查**（worker / queue 服務）：偵測 Celery / Sidekiq / Bull 等的 active task，有任務就警告
- **串流服務檢查**（WebSocket / RTSP / SSE）：警告連線會中斷
- **掛載類型判斷**：volume mount → restart；image baked → build + up

### Step 6：執行

```bash
# Volume mount
docker compose restart <svc>

# Image baked
docker compose build <svc1> <svc2>
docker compose up -d <svc1> <svc2>
```

列出目標後**直接執行**，不發確認訊息（讓 tool permission UI 處理，對齊 CLAUDE.md 第 15 條）。

### Step 7：健康檢查

```bash
sleep 8
docker compose ps | grep -E "<services>"
```

期望 `Up X seconds (healthy)`；若 `Restarting` / `Exited` → 進 Step 8。

### Step 8：日誌掃描

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

### Step 9：自動修復

| 症狀 | 自動修復 | Fallback |
|---|---|---|
| ImportError / Module not found | `docker compose build --no-cache <svc>` | 釘版本 |
| ConnectionRefused | `docker compose up -d --wait <dep>` → restart | 查 dep log |
| Port 衝突 | `docker compose down <svc>` → `up -d` | 找 PID kill |
| DB migration error | 報告需要的 DDL | 手動執行 |
| 無法自動修復 | 完整 log 摘要 + 根因 + 手動修復步驟 | — |

### Step 10：最終驗證

- API 健康：`curl http://localhost:<port>/health` 或 `/docs`
- Worker 連線：`celery -A <app> inspect ping`

輸出：

```
| Service | Action | Status | Duration |
|---|---|---|---|
```

### 非容器化專案

偵測 PM2 / systemd / supervisor / nodemon / watchdog / air，給對應重啟指令。

---

## 各子命令的 Model 使用建議（對齊 CLAUDE.md 第 18 條）

| 子命令 | 建議 model | 原因 |
|---|---|---|
| flow | sonnet | 串接元命令，主體為 Sonnet 執行 |
| **plan** | **opus** | 需求分析 / 方案設計 / 架構決策（thinking 屬性） |
| impl | sonnet | 逐步執行（execution 屬性） |
| test | sonnet | 多步驟執行 + 檢查 |
| **quality** | **opus** | 深度品質審計 / 架構評估（thinking 屬性） |
| review | sonnet | 列 checklist / 互動確認 |
| deploy | sonnet | 容器操作執行 |

Skill 本體 `model: sonnet`。需要 Opus 深度分析的子命令（plan / quality）建議透過 **Agent 工具**呼叫 Opus 子任務，不改變 Skill 本體 model 設定。

**三層分層原則**（CLAUDE.md 第 18 條）：
- **Opus**：評估、規劃、架構決策、深度品質分析
- **Sonnet**：多步驟執行、檔案讀寫、中低複雜度任務
- **Haiku**：結構化文字撰寫、模板填充、日誌產生

Arguments: $ARGUMENTS （第一個 token 為子命令，其餘為該子命令參數）
