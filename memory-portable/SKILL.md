---
name: memory-portable
description: "Memory 跨專案攜帶：feedback/user type 的 memory 隨 Sekai_workflow git 攜帶，新專案初始化時自動還原。"
model: sonnet
effort: low
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(ls *), Bash(cp *), Bash(git *)
---

## Memory 跨專案攜帶

管理 `feedback` 和 `user` type 的 memory 檔案，使其可隨 Sekai_workflow 攜帶至新專案。

---

### Step 1: 識別可攜帶的 Memory

掃描當前專案的 Memory 目錄（`~/.claude/projects/{project}/memory/`），篩選：

- **攜帶**：`feedback` 和 `user` type（跨專案通用的偏好與習慣）
- **不攜帶**：`project` 和 `reference` type（與專案綁定）

判斷依據：讀取每個 `.md` 的 frontmatter `type` 欄位。

---

### Step 2: 同步至 Sekai_workflow

將篩選出的 memory 檔案複製至 `Sekai_workflow/memory-portable/`：

```bash
cp ~/.claude/projects/{project}/memory/feedback_*.md Sekai_workflow/memory-portable/
cp ~/.claude/projects/{project}/memory/user_*.md Sekai_workflow/memory-portable/
```

- **不覆蓋已存在的同名檔案**（保留既有版本）
- 更新 `Sekai_workflow/memory-portable/README.md` 的檔案清單

---

### Step 3: 還原（由 sp-init.bat 觸發）

新專案初始化時自動執行：

1. 將 `Sekai_workflow/memory-portable/*.md` 複製至當前帳號的 `~/.claude/projects/{project}/memory/`
2. 不覆蓋已存在的同名檔案
3. 自動生成或合併 `MEMORY.md` 索引

---

### Step 4: 回寫（由 sp-pack.sh 觸發）

專案打包時：

1. 掃描 memory 目錄找出新增的 feedback/user memory
2. 複製至 `Sekai_workflow/memory-portable/`
3. commit + push Sekai_workflow

---

Arguments: $ARGUMENTS (optional)
