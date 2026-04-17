---
name: hello
description: "對話初始化入口 — 自動拉取專案 + Skill 更新、恢復 context、顯示狀態摘要。取代舊有的對話開始自動同步機制。"
model: sonnet
effort: low
argument-hint: ""
allowed-tools: Read, Glob, Grep, Bash(git *), Bash(ls *), Bash(date *), Bash(docker *)
---

# /hello — 對話初始化

每次新對話開始時呼叫，一站式完成：拉取更新 → 同步 Skill → 恢復 context → 狀態總覽。

**取代 CLAUDE.md Rule 12 舊有的「對話開始自動同步」機制** — 改為使用者主動呼叫，更可控。

---

## Step 1：拉取專案更新

```bash
# 專案本身
git fetch origin
git status
```

- 若有 upstream 更新 → 顯示 `origin/HEAD` 領先幾個 commit，**不自動 merge**（避免衝突）
- 告知使用者：「遠端有 N 個新 commit，需要時可 `git pull`」
- 若已是最新 → 顯示「專案已是最新」

---

## Step 2：同步 Skill 更新（合併原 `/setup sync` 流程一）

> 本步驟整合原 `/setup sync` 的「流程一：遠端同步」邏輯。
> `/setup sync` 仍保留「流程二：規則評估與三向連動」供 Memory 寫入時使用。

### 2.1 檢查 flowback.pull 設定

Read `.claude/settings.local.json` 的 `sekai_workflow.flowback.pull`：

| 狀態 | 行為 |
|---|---|
| `true`（預設） | 進入 2.2 |
| `false` | 跳過遠端 pull，僅做本地同步（2.3） |

### 2.2 執行 sp-sync.sh（遠端同步）

```bash
bash Sekai_workflow/_bootstrap/sp-sync.sh
```

腳本行為（與原 `/setup sync` 流程一相同）：
1. `git fetch origin` 取得遠端更新
2. 比較本地與遠端 commit
3. 若有更新 → `git pull --rebase origin main`
4. 逐一比對 `Sekai_workflow/` 與 `.claude/skills/` 各 skill 的 SKILL.md / README.md
5. 自動複製新增或差異 skill 到 `.claude/skills/`
6. 輸出 Added / Updated / No change 摘要

**腳本無法處理**：
- Pull 衝突 → 中止，告知使用者手動 resolve
- 新增 skill → 腳本只複製檔案，需手動更新 CLAUDE.md 可用 Skills

### 2.3 補充同步（腳本未覆蓋的項目）

腳本完成後，Claude 補充檢查：
- `sekai-workflow/manifest.json` 是否有新 skill 不在 `.claude/skills/` → 補複製
- `.claude/skills/README.md` 是否需更新 → 提示使用者

輸出同步摘要：

```
Skill 同步：
  更新：commit-push, team-office（2 個）
  新增：hello（1 個）
  跳過：build（本地較新）
  無變更：ask, context-guard, setup, memory-portable
```

---

## Step 3：恢復 Context

### 3.1 讀取最新 context_summary

掃描 `.local/context_summary/*.md`（不含 `current_topic.md`），按檔名日期排序，讀取最新 1~2 份：

- 有摘要 → 顯示「上次工作摘要」精簡版（3~5 行）
- 無摘要 → 跳過

### 3.2 讀取 current_topic

讀��� `.local/context_summary/current_topic.md`：

- 有 → 顯示「當前主題：<topic>」
- 無 → 跳過

### 3.3 讀取待辦

讀取 `.local/collab/TODO.md`：

- 有 Pending / In Progress 項目 → 摘要顯示前 3~5 項
- 無 → 跳過

---

## Step 4：狀態總覽

輸出精簡的專案狀態（一屏內可讀完）：

```
━━━ /hello ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

專案：<PROJECT_NAME>
分支：<branch> (↑N ↓M vs origin)
上次 commit：<hash> <message> (<time ago>)

Skill 同步：✓ 已同步（N 個更新）
Context：<上次主題>
待辦：N 項 pending

未提交變更：N 個檔案
未 push commit：N 個

━━━━━━━━��━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Step 5：環境健康檢查（可選，有 Docker 才執行）

若專案有 `docker-compose.yml`：

```bash
docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Service}}" 2>/dev/null
```

- 有服務 → 摘要列出 running / stopped / unhealthy 數量
- 無 Docker / Docker 未啟動 → 跳過（不報錯）

---

## 與其他 Skill 的關係

| Skill | 關係 |
|---|---|
| `/setup sync` | `/hello` Step 2 復用 sync 邏輯；sync 仍可獨立呼叫做完整同步（含衝突解決）|
| `/context-guard` | `/hello` Step 3 讀取 context-guard 產出的摘要 |
| `/team-office todo` | `/hello` Step 3 讀取 TODO 狀態 |
| `/setup pack` | 互斥：pack 後環境已清除，/hello 無法執行 |
| `/team-office handoff` | 互補：handoff 產出的 AI bundle 可在新對話 `/hello` 後手動指示 AI 讀取 |

---

Arguments: $ARGUMENTS
