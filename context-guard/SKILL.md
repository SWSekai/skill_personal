---
name: context-guard
description: "Monitor context window usage. Triggered by: (1) system compression notification, (2) manual /context-guard call, (3) conversation start to recover pending summaries. Summarize work to context_summary/ and prompt /clear."
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(ls *), Bash(wc *), Bash(git status*), Bash(git log*), Bash(date *)
---

## Context Window 管理守衛

### 能力邊界（重要）

| 功能 | 可行性 | 說明 |
|------|:------:|------|
| 手動 `/context-guard` | ✓ | 隨時可用 |
| 系統壓縮通知後觸發 | ✓ | 唯一可靠的自動信號 |
| 對話開始讀取舊摘要 | ✓ | 由 skill-sync 串聯 |
| 量測 context 使用百分比 | ✗ | 無 API，不可實現 |
| 自動計數對話輪數 | ✗ | 無內建計數器 |
| 自動偵測任務切換 | △ | 依賴狀態檔比對，半自動 |

---

### Step 1: 觸發條件判定

此 Skill 在以下情況觸發：

1. **系統壓縮通知**（自動）：收到 `context compressed` 或類似系統訊息時，立即進入 Step 2
2. **手動呼叫** `/context-guard`：使用者主動觸發
3. **對話開始時**（由 skill-sync 串聯）：檢查是否有待恢復的摘要 → 直接跳至 Step 5

不再依賴以下不可量測條件：
- ~~對話輪數超過 20 輪~~（無計數器）
- ~~context 使用量超過 40%~~（無 API 量測）

---

### Step 2: 記錄當前工作狀態

在 `.local/summary/` 建立摘要（由 `setup.bat` 自動建立）：

**檔名格式**：`YYMMDD_HHMM_TopicDescription.md`

```markdown
# Context Summary — [Topic Description]

## Date/Time
YYYY-MM-DD HH:MM

## Current Work in Progress
- [Task description and current progress]

## Completed Work
- [Completed items]

## Uncommitted Changes
[Run git status to list]

## Pending Items
- [Tasks not yet started or needing follow-up]

## Key Decisions & Context
- [Design decisions, user preferences, information to carry forward]

## Service Restart Requirements
[If any, list containers and commands; otherwise "None"]
```

---

### Step 3: Update Topic State File

Write or update `.local/summary/current_topic.md`:

```markdown
# Current Work Topic

- **Topic**: [one-line description]
- **Updated**: YYYY-MM-DD HH:MM
- **Related Summary**: [summary filename]
```

This file is used for task switch detection (Step 4).

---

### Step 4: Task Switch Detection (semi-automatic)

**Trigger**: Claude reads `current_topic.md` before processing a new user request and compares:

- If the new request clearly belongs to a **different functional area** (e.g., from "frontend UI changes" to "training service refactor"):
  1. Alert: "Detected task switch ([old topic] → [new topic]), recommend cleaning context."
  2. Confirm whether to commit current changes
  3. Generate summary → suggest `/clear`
  4. Update `current_topic.md` to new topic

- If the new request is an **extension of the same workflow** (e.g., commit followed by container restart question):
  - Do not trigger, only update `current_topic.md`

**Judgment basis**: Based on code impact scope, not surface keywords. Operations within the same service or module are considered the same topic.

**Limitation**: This detection depends on Claude proactively reading the state file — it is not truly automatic. If Claude doesn't read it, detection won't trigger.

---

### Step 5: Summary Recovery & Lifecycle

**At conversation start** (chained by skill-sync):
1. Check `.local/summary/` for `.md` summary files (excluding `current_topic.md`)
2. Found → read latest summary, present to user and ask whether to continue
3. Not found → start normally

**Stale cleanup**:
- All work in summary is completed (committed + pushed) → delete summary
- `current_topic.md` not updated for 24+ hours → treat as stale, clean up

---

### Step 6: Confirm with User

1. **Confirm commit**: "There are uncommitted changes — commit first?"
   - Yes → run `/commit-push`
   - No → continue
2. **Confirm /clear**: "Summary saved to `[path]`, recommend running /clear."

Arguments: $ARGUMENTS (optional: "check" check only without generating summary, "clean" clean stale summaries)
