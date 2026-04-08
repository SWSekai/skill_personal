---
name: create-skill
description: "建立新 Skill：互動式定義 → 生成 SKILL.md + README.md → 註冊索引 → 同步 skill_personal"
model: sonnet
effort: medium
argument-hint: "[skill-name] [description]"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(ls *), Bash(mkdir *), Bash(date *), Bash(git *), Bash(cp *)
---

## Create Skill Protocol

建立一個全新的 Claude Code Skill，遵循既有結構規範並自動完成所有註冊步驟。

---

### Step 1: 收集 Skill 定義資訊

透過 AskUserQuestion 或解析 `$ARGUMENTS` 取得以下資訊：

| 欄位 | 必填 | 說明 |
|------|:----:|------|
| name | ✓ | Skill 名稱（英文 kebab-case，如 `trace-flow`） |
| command | ✓ | 斜線指令名（如 `/trace-flow`） |
| description | ✓ | 一行描述（中文），說明用途 |
| model | ✓ | 建議 model：`opus` / `sonnet` / `haiku` |
| effort | ✓ | 推理深度：`low` / `medium` / `high` |
| argument-hint | - | 自動完成提示（如 `[service...]`、`[topic]`） |
| trigger | ✓ | 觸發方式：`手動呼叫` / `自動觸發` / `條件觸發`（附條件說明） |
| allowed_tools | ✓ | 該 Skill 可使用的工具清單 |
| steps | ✓ | 執行步驟（至少一步） |
| scope | - | `通用`（適用所有專案）或 `專案專屬`（僅當前專案） |

**Model 選擇指引**（詳見 `${CLAUDE_SKILL_DIR}/references/model-selection-guide.md`）：
- `opus`：使用 Agent 工具、跨檔案分析、架構評估
- `sonnet`：多步驟工作流、檔案讀寫、標準開發任務
- `haiku`：結構化輸出、模板填充、狀態檢查
- 若不確定，預設使用 `sonnet`

若 `$ARGUMENTS` 中已有足夠資訊，直接解析使用；不足的欄位再逐一詢問。

**使用 AskUserQuestion 時，第一個選項為推薦選項，讓使用者可直接按 Enter 確認。**

---

### Step 2: 檢查名稱衝突

```
檢查以下路徑是否已存在同名 Skill：
1. .claude/skills/<name>/
2. skill_personal/<name>/
```

- 若已存在且有內容 → 警告使用者，詢問要「覆寫」還是「更新」
- 若已存在但是空的 → 視為全新建立，繼續
- 若不存在 ��� 繼續

---

### Step 3: 生成 SKILL.md

使用 `${CLAUDE_SKILL_DIR}/assets/SKILL.md.template` 為基礎，在 `.claude/skills/<name>/SKILL.md` 建立 Skill 定義檔。

**Frontmatter 必須包含所有欄位：**

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

**格式規範：**
- frontmatter 欄位順序：name → description → model → effort → argument-hint → allowed-tools
- 步驟以 `### Step N:` 格式編號
- 每步之間用 `---` 分隔
- 最後加 `Arguments: $ARGUMENTS` 行
- 語言：步驟說明用中文，程式碼/指令用英文
- 引用子目錄檔案使用 `${CLAUDE_SKILL_DIR}/references/xxx.md` 或 `${CLAUDE_SKILL_DIR}/assets/xxx`

---

### Step 3b: 評估子目錄需求

根據 Skill 內容複雜度，決定是否建立子目錄：

**評估標準：**
- SKILL.md 預估超過 150 行 → **必須**拆分
- 包含可分離的參考表格、查找表 → 抽到 `references/`
- 包含模板檔案、設定範本 → 抽到 `assets/`
- 包含輔助腳本 → 抽到 `scripts/`

**可用子目錄（僅在需要時建立）：**

| 子目錄 | 用途 | 範例 |
|--------|------|------|
| `references/` | 查找表、嚴重等級定義、慣例文件、決策樹 | `severity-guide.md`, `error-recovery.md` |
| `scripts/` | 輔助腳本（非 SKILL.md 協議步驟本身的邏輯） | `validate.sh`, `helper.py` |
| `assets/` | 範本檔案、設定範本、初始結構模板 | `template.md`, `schema.json` |

**SKILL.md 中的引用方式：**
```
詳見 `${CLAUDE_SKILL_DIR}/references/xxx.md`
使用 `${CLAUDE_SKILL_DIR}/assets/xxx` 作為模板
```

若 Skill 內容簡潔（<150 行且無可分離內容），跳過此步驟。

---

### Step 4: 生成 README.md

使用 `${CLAUDE_SKILL_DIR}/assets/README.md.template` 為基礎，在 `.claude/skills/<name>/README.md` 建立說明文件。

README 必須包含：
- 功能說明、使用方式
- **Model 資訊**（建議 model、effort、理由）
- 觸發條件、執行流程
- 目錄結構（含子目錄，若有）
- 參數說明

---

### Step 5: 更新 `.claude/skills/README.md`

在三個位置加入新 Skill：

1. **Skills Overview 表格**：在 `| Skill | Command | Model | Description |` 表格中，按字母順序插入新行
2. **詳細說明區段**：在 `## 詳細說明` 區段，按字母順序插入新 Skill 的說明區塊
3. **Directory Structure 樹狀圖**：在 `skill_personal/` 的樹狀結構中加入新資料夾（含子目錄）

---

### Step 6: 更新 CLAUDE.md

在 CLAUDE.md 的 `## Available Skills` 區段加入新 Skill：

```
- `/command` --- 描述
```

按字母順序插入。

---

### Step 7: 同步至 skill_personal（如果是通用 Skill）

判斷此 Skill 的 scope：

**通用 Skill（適用所有專案）：**
1. 複製整個 skill 目錄（含子目錄）至 `skill_personal/<name>/`
2. 更新 `skill_personal/manifest.json`：
   - 在 `skills` 陣列中加入新條目（含 `model` 欄位）
   - `files` 陣列包含所有檔案（SKILL.md、README.md、references/*、assets/*、scripts/*）
3. 更新 `skill_personal/README.md`：表格 + 說明 + 樹狀圖
4. 在 `skill_personal/` 中 commit + push：
   ```bash
   cd skill_personal
   git add <name>/ manifest.json README.md
   git commit -m "feat: 新增 <name> skill"
   git push
   ```

**專案專屬 Skill：**
- 僅建立在 `.claude/skills/<name>/`，不同步至 `skill_personal/`
- 告知使用者此 Skill 不會隨 `/pack` 帶走

---

### Step 8: 完整性驗證

執行 CLAUDE.md Rule 10 的完整性檢查：

| 檢查項目 | 狀態 |
|----------|:----:|
| `.claude/skills/<name>/SKILL.md` 存在 | ✓/✗ |
| `.claude/skills/<name>/README.md` 存在 | ✓/✗ |
| SKILL.md frontmatter 包含 `model` + `effort` | ✓/✗ |
| 子目錄檔案存在（若有規劃） | ✓/✗ |
| `.claude/skills/README.md` 已更新（表格 + 說明 + 樹狀圖） | ✓/✗ |
| `CLAUDE.md` Available Skills 已更新 | ✓/✗ |
| `skill_personal/<name>/` 已同步（若通用） | ✓/✗ |
| `skill_personal/manifest.json` 已更新（含 `model`）（若通用） | ✓/✗ |
| `skill_personal/README.md` 已更新（若通用） | ✓/✗ |

所有項目 ✓ 後，輸出確認訊息。

---

### Step 9: 輸出摘要

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
- skill_personal/ (若通用)
```

Arguments: $ARGUMENTS (可直接傳入 Skill 名稱或完整定義，如 `/create-skill my-skill 描述...`)
