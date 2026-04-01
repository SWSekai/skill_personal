---
name: todo
description: "Read and process AI TODO list from the collaboration directory. Picks items by priority, asks follow-up questions, executes tasks, and updates the TODO file with results."
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(git *), Bash(ls *), Bash(date *), Bash(docker *), Bash(mkdir *)
---

## AI TODO Processing

### Usage

```
/todo              — Process pending items (highest priority first)
/todo add <desc>   — Quick-add a new item (supports @high / @low tags)
/todo list         — List all pending items
```

---

### Step 1: Read & Parse TODO

1. Read the TODO file (default: `.local/collab/TODO.md` or project-specific path)
2. Parse all items in the "Pending" section:
   - Extract description and priority tags (`@high` / `@low` / unmarked)
   - Read indented notes below each item as supplementary context
3. If no pending items → inform the user and exit

**If argument is `add <description>`**:
- Add item to the top of the "Pending" section
- Inform the user and exit (do not enter processing flow)

**If argument is `list`**:
- Display all pending items as a table (number, description, priority)
- Exit (do not enter processing flow)

---

### Step 2: Sort & Select

1. Sort by priority: `@high` → unmarked → `@low`
2. Same priority: first-in-first-processed
3. Present sorted list to user, ask which to process:
   - Default: start from #1
   - User can pick specific numbers
   - User can reply "all" to process everything

---

### Step 3: Detail Confirmation (Follow-up Questions)

Before executing a selected item, **evaluate if the description is specific enough**:

**Ask follow-up when**:
- Description is vague (e.g., "optimize performance" → which service? which endpoint?)
- Multiple implementation approaches exist
- Scope is unclear
- Acceptance criteria missing

**Skip follow-up when**:
- Description includes specific files, functions, or concrete behavior
- Bug fix with error message or reproduction steps
- Notes already provide sufficient detail

Ask all questions at once in a concise list. If user replies "you decide" → make a judgment call based on existing code architecture, briefly state the decision before proceeding.

---

### Step 4: Execute Task

1. Move item from "Pending" to "In Progress", update TODO file:
   ```markdown
   ## In Progress
   - [~] description — processing (YYYY-MM-DD HH:MM)
   ```

2. **Perform the actual work**: read code, make changes, follow project conventions

3. During execution:
   - **Derived tasks**: auto-add to "Pending" with `(derived from: original description)`
   - **Blockers**: pause, explain to user, move item back to "Pending" with blocker note

---

### Step 5: Completion

After task completion:

1. Move item from "In Progress" to "Completed":
   ```markdown
   ## Completed
   - [x] description — done YYYY-MM-DD HH:MM
     - commit: `hash` message
     - affected: file1, file2
   ```

2. If derived tasks exist, inform user
3. Check for remaining items:
   - User chose "all" → continue to next (back to Step 3)
   - Otherwise → ask if they want to continue

---

### Step 6: Wrap-up

After all selected items are processed:

1. Present processing summary (completed, deferred, derived)
2. Ask if user wants to commit-push (if there are uncommitted changes)

Arguments: $ARGUMENTS (optional: "add <description>", "list", or item number)
