---
name: skill
description: "Skill 環境管理一站式入口：建立新 Skill、遠端同步、專案打包。子命令路由 new / sync / pack。"
model: sonnet
effort: medium
argument-hint: "<new|sync|pack> [args...]"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(git *), Bash(ls *), Bash(mkdir *), Bash(date *), Bash(cp *), Bash(bash *), Bash(cat *)
---

# /skill — Skill 環境管理合併 Skill

整合 create-skill、skill-sync、pack 三項職能。透過第一個參數決定子命令。

## 子命令路由

| 子命令 | 用途 | 對應原 Skill |
|---|---|---|
| `/skill new [name] [desc]` | 建立新 Skill | create-skill |
| `/skill sync` | 遠端同步 + 規則評估 | skill-sync |
| `/skill pack` | 專案打包（清除 skill 環境） | pack |

無參數時要求使用者指定子命令。

---

## A. `/skill new` — 建立新 Skill

互動式建立全新 Claude Code Skill，遵循既有結構規範並完成所有註冊。

### Step 1：收集 Skill 定義

透過 AskUserQuestion 或解析 `$ARGUMENTS` 取得：

| 欄位 | 必填 | 說明 |
|---|:---:|---|
| name | ✓ | kebab-case（如 `trace-flow`） |
| command | ✓ | 斜線指令（如 `/trace-flow`） |
| description | ✓ | 一行中文描述 |
| model | ✓ | `opus` / `sonnet` / `haiku` |
| effort | ✓ | `low` / `medium` / `high` |
| argument-hint | - | 自動完成提示 |
| trigger | ✓ | 手動 / 自動 / 條件觸發 |
| allowed_tools | ✓ | 工具清單 |
| steps | ✓ | 執行步驟 |
| scope | - | `通用` / `專案專屬` |

**Model 選擇指引**：
- `opus`：使用 Agent 工具、跨檔案分析、架構評估
- `sonnet`：多步驟工作流、檔案讀寫、標準開發任務
- `haiku`：結構化輸出、模板填充、狀態檢查
- 不確定 → 預設 `sonnet`

`$ARGUMENTS` 已含足夠資訊時直接解析；不足才追問。AskUserQuestion 第一個選項加 `(Recommended)`。

### Step 2：名稱衝突檢查

檢查 `.claude/skills/<name>/` 與 `.skill_personal/<name>/`：
- 已存在且有內容 → 警告，問「覆寫」或「更新」
- 已存在但空 → 視為新建
- 不存在 → 繼續

### Step 3：生成 SKILL.md

`.claude/skills/<name>/SKILL.md`：

```yaml
---
name: <name>
description: "<description>"
model: <model>
effort: <effort>
argument-hint: "<argument_hint>"
allowed-tools: <allowed_tools>
---
```

格式規範：
- frontmatter 順序：name → description → model → effort → argument-hint → allowed-tools
- 步驟用 `### Step N:`
- 每步以 `---` 分隔
- 末尾 `Arguments: $ARGUMENTS`
- 步驟說明中文，程式碼/指令英文
- 引用子目錄：`${CLAUDE_SKILL_DIR}/references/xxx.md`

### Step 3b：評估子目錄需求

| 子目錄 | 用途 | 觸發條件 |
|---|---|---|
| `references/` | 查找表、嚴重等級定義、決策樹 | 有可分離的參考資料 |
| `assets/` | 範本檔、設定範本、初始模板 | 有模板檔需要 |
| `scripts/` | 輔助腳本 | 有非協議邏輯的腳本 |

**SKILL.md > 150 行 → 必須拆分**。內容簡潔（< 150 行且無可分離內容）→ 跳過。

### Step 4：生成 README.md

含功能說明、使用方式、Model 資訊（model + effort + 理由）、觸發條件、執行流程、目錄結構、參數說明。

### Step 5：更新 `.claude/skills/README.md`

三個位置加入新 Skill：
1. **Skills Overview 表格**：按字母順序插入新行
2. **詳細說明區段**：按字母順序插入說明區塊
3. **Directory Structure 樹狀圖**：在 `skill_personal/` 結構中加入新資料夾

### Step 6：更新 CLAUDE.md

`## 可用 Skills` 區段按字母順序插入：
```
- `/command` — 描述
```

### Step 7：同步至 `.skill_personal/`（通用 Skill 才做）

通用 Skill：
1. 複製整個 skill 目錄至 `.skill_personal/<name>/`
2. 更新 `.skill_personal/manifest.json`（含 `model` 欄位、所有 files 路徑）
3. 更新 `.skill_personal/README.md`（表格 + 說明 + 樹狀圖）
4. commit + push：

```bash
cd .skill_personal
git add <name>/ manifest.json README.md
git commit -m "feat: 新增 <name> skill"
git push
```

專案專屬 Skill：僅在 `.claude/skills/`，不同步，告知使用者「不會隨 /skill pack 帶走」。

### Step 8：完整性驗證

| 檢查項 | ✓/✗ |
|---|:---:|
| `.claude/skills/<name>/SKILL.md` | |
| `.claude/skills/<name>/README.md` | |
| frontmatter 含 `model` + `effort` | |
| 子目錄檔案存在（若有規劃） | |
| `.claude/skills/README.md` 已更新 | |
| `CLAUDE.md` 已更新 | |
| `.skill_personal/<name>/` 已同步（若通用） | |
| `.skill_personal/manifest.json` 已更新（若通用） | |
| `.skill_personal/README.md` 已更新（若通用） | |

### Step 9：輸出摘要

```
✓ Skill 建立完成

名稱：<name>
指令：/<command>
Model：<model> (effort: <effort>)
類型：通用 / 專案專屬
位置：.claude/skills/<name>/
結構：SKILL.md + README.md [+ references/ + assets/ + scripts/]

已更新：
- .claude/skills/README.md
- CLAUDE.md
- .skill_personal/ (若通用)
```

---

## B. `/skill sync` — 遠端同步、規則評估

### 觸發時機

1. **新增規則至 CLAUDE.md 或 Memory 時**（自動）：評估是否應加入 Skill
2. **修改 `.skill_personal/` 時**（自動）：同步至遠端
3. **手動呼叫**：強制執行完整同步流程
4. **對話開始時**（可選）：檢查遠端差異

### 流程一：`.skill_personal/` 遠端同步

直接執行自動化腳本：

```bash
bash .skill_personal/setup/sp-sync.sh
```

腳本完成：
1. `git fetch origin` 取得遠端更新
2. 比較本地與遠端 commit
3. 若有更新 → `git pull --rebase origin main`
4. 逐一比對 `.skill_personal/` 與 `.claude/skills/` 各 skill 的 SKILL.md / README.md
5. 自動複製新增或差異 skill 到 `.claude/skills/`
6. 輸出 Added / Updated / No change 摘要

**腳本無法處理（需手動）**：
- Pull 衝突 → 中止，需手動 resolve 後重跑
- 新增 skill → 腳本只複製檔案，需手動更新 `CLAUDE.md` 可用 Skills
- Push 本地變更 → 腳本不自動 push，須 `cd .skill_personal && git push origin main`

### 流程二：規則評估與三向連動（強制）

> **寫入 Memory 時，必須在同一回覆中完成評估與執行。不可僅寫 Memory 就結束。**
>
> Memory 多為使用者習慣與行為偏好，具備跨專案通用性。僅存 Memory 的規則只對當前專案有效，無法隨 `.skill_personal` 帶到新專案。

**寫入 Memory 後立即判斷**：

1. **是否為可重複套用的行為約束或流程規則？** → 同步更新 `CLAUDE.md`
2. **是否具備跨專案通用性？** → 回流至 `.skill_personal/` 模板並推送遠端
3. **是否僅適用當前專案？** → 僅 Memory，不回流

完整決策樹與 5 項評估問題：

詳見 `${CLAUDE_SKILL_DIR}/references/evaluation-decision-tree.md`（若存在，否則內含於本檔）。

### 版控邊界（重要）

| 路徑 | 版控歸屬 |
|---|---|
| `CLAUDE.md` | 不入版控（本地） |
| `.claude/skills/` | 不入版控（本地） |
| `.skill_personal/` | `Skill-personal` 遠端倉庫 |
| `.local/` | 不入版控 |

**禁止 `git add -f`**：所有 `.gitignore` 中的檔案不得以任何方式加入專案版控。

---

## C. `/skill pack` — 專案打包

將專案中所有 AI 維護相關檔案打包到 `.local/ai-context/`，然後刪除 skill 環境，還原乾淨的專案目錄。

### 觸發

手動呼叫 `/skill pack`

### 執行

直接執行自動化腳本：

```bash
bash .skill_personal/setup/sp-pack.sh
```

### 腳本行為

1. **收集** — `CLAUDE.md`、`.local/` 工作紀錄、Memory、skills 快照
2. **偵測專案專屬 skill** — 比對 `.claude/skills/` vs `.skill_personal/`，差集即為專案專屬
3. **保存專案專屬 skill** → `.local/ai-context/project-skills/`
4. **收集通用指南** — 掃描 `.local/docs/`、`docs/`、根目錄，含 `guide` 或 `指南` 的文件至 `guides/`
5. **產生 manifest.txt** — 打包時間、檔案清單、還原指引
6. **清除** — 刪除 `.claude/skills/`、`.skill_personal/`、`CLAUDE.md`

### 腳本後 — AI 合併指南（必須執行）

腳本完成後，**必須** 對 `.local/ai-context/guides/` 進行智慧合併：

1. 讀取所有收集到的指南文件
2. 識別重複/重疊主題（例如多份 K8s 部署指南）
3. 合併同主題文件：
   - 盡力保留所有資訊，不丟棄任何實務細節
   - 主題命名（`guide-k8s-deployment.md`、`guide-cicd-pipeline.md`）
   - 在合併文件頂部註明原始路徑來源
   - 衝突資訊並列保留並標註差異
4. 刪除已合併的原始檔案
5. 無重疊的獨立指南 → 保持原樣，僅重新命名

### 注意

- 腳本會要求使用者確認（y/N）才執行刪除
- 結果在 `.local/ai-context/`（已 .gitignore，不入版控）
- 還原方式見 `manifest.txt`

### 還原流程

1. `.skill_personal/setup/sp-init.bat` — 重建環境
2. `bash .skill_personal/setup/sp-sync.sh` — 同步最新 skill
3. 將 `project-skills/` 複製回 `.claude/skills/`
4. 將 `CLAUDE.md` 複製回根目錄
5. 將 `memory/` 複製回 `~/.claude/projects/.../memory/`

---

Arguments: $ARGUMENTS （第一個 token 為子命令，其餘為該子命令參數）
