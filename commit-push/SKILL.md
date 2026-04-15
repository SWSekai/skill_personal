---
name: commit-push
description: Commit and push changes — auto-generate local modify logs, update READMEs, evaluate service restarts, and run quality checks. No .gitignore files are ever force-added.
model: sonnet
effort: medium
argument-hint: "[commit message]"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(git *), Bash(ls *), Bash(date *), Bash(docker *)
---

## Commit & Push Protocol

Execute the following steps **in order**. Do not skip any step.

---

### Step 1: Pre-commit quality checks

Before staging anything, perform:

1. **Code quality scan**: Review all changed files for:
   - Dead code or unused imports
   - Redundant logic or duplicated blocks
   - Hardcoded values that should be configurable
   - Missing error handling at system boundaries

2. **Impact assessment**: For each changed file, evaluate:
   - Does this change affect other modules? Trace dependencies.
   - Could this break existing functionality? Check callers/consumers.
   - Are there race conditions or edge cases?
   - Report any **potential risks** to the user before proceeding.

3. **Skill relevance check**: If changes introduce new patterns or conventions:
   - Ask the user: "Should I update the Skill definitions to reflect this new pattern?"
   - Wait for confirmation before updating `.claude/skills/`.

---

### Step 2: Auto-update README.md files

Check if any changed files belong to directories that have `README.md`. If the changes affect the directory's structure or functionality, update the README accordingly.

If a key functional directory lacks a README, create one with:
- Purpose of the directory
- File/directory structure
- Key functionality overview

---

### Step 3: Status overview & staging

**3a. Show full pending status** (give user a clear picture before commit)

```bash
git status
git diff --stat
git log --oneline origin/$(git rev-parse --abbrev-ref HEAD)..HEAD   # committed but not pushed
```

Present to the user:
- **Unstaged modified files**: list each file with a one-line change summary
- **Staged but uncommitted files**: same
- **Committed but unpushed**: list commit hash + message
- If nothing pending, inform the user and stop

**3b. Read `.gitignore` for safe staging**

Read `.gitignore` before staging. Never force-add ignored files. See full rules:
→ `${CLAUDE_SKILL_DIR}/references/gitignore-safety.md`

**3c. Stage files**

- Use `git add <file>` for specific files only
- Include any updated READMEs
- See `${CLAUDE_SKILL_DIR}/references/gitignore-safety.md` for prohibited commands

**3d. Proceed directly to staging + commit (no extra confirmation message)**

After listing the file summary, proceed directly to `git add` + `git commit`. The user can approve or deny via the tool permission confirmation UI — do not send a separate text message asking "should I continue?".

---

### Step 4: Commit

- Follow Conventional Commits format with HEREDOC template
- See full conventions and template:
  → `${CLAUDE_SKILL_DIR}/references/commit-conventions.md`

---

### Step 5: Auto-create Modify Log (local only, not committed)

After commit, create the modification log:

1. Get the commit hash:
   ```bash
   git log --oneline -1
   ```
2. Invoke the `modify-log` skill with the commit hash
3. Path: `.local/modify_logs/YYMMDD_TopicDescription.md`
4. **The log is stored locally only — it is NOT added to git version control**

---

### Step 6: Push

```bash
git push
```

If push fails (auth, hook, or remote error), inform the user with the error and suggest next steps.

---

### Step 7: Sync skill_personal to remote repository

If any files under `skill_personal/` (or its equivalent general skill folder) were changed in this session:

1. Enter the `skill_personal/` directory (it is itself a git repo with remote `https://github.com/SWSekai/skill_personal.git`)
2. Stage all updated files, commit (mirror the current commit message), and push:

```bash
cd skill_personal
git add -A
git commit -m "<mirrored commit message>"
git push
```

3. If push fails, inform the user and continue — do not block the main workflow.

4. **If any SKILL.md or README.md was added/modified**, auto-update `manifest.json` and `QUICKSTART.md`:
   - Read `manifest.json`, update the changed skill's entry (or add new entry)
   - Update the skill count comment and date in `QUICKSTART.md`
   - If a new skill was added, add its row to the command table in `QUICKSTART.md`
   - Include these updates in the same commit

If no `skill_personal/` files were changed, skip this step.

---

### Step 8: Service restart evaluation

If the project uses Docker / containers / services, determine which need restarting:

1. Read `docker-compose.yml` (or equivalent) to understand volume mounts vs baked-in code
2. Classify each changed file:
   - **Volume-mounted code (no auto-reload)** → needs `docker compose restart <service>`
   - **Volume-mounted code (with auto-reload/HMR)** → no restart needed
   - **Baked into image** → needs `docker compose build <service> && docker compose up -d <service>`
   - **Static files served by web server** → browser refresh only
   - **DB init scripts** → only affect first init; existing DB needs manual migration
   - **Dockerfile / compose changes** → rebuild required
3. Output the exact commands needed

If the project has no containerization, skip this step.

---

### Step 9: Context cleanup & summary (auto-execute)

After the commit-push workflow completes (including modify log creation), proactively manage context:

**9a. Execute context-guard summary**

Follow context-guard Skill Step 2~3 logic to create or merge a summary:

1. Check if `.local/context_summary/` (or equivalent) already has a **same-day same-topic** summary:
   - Yes → merge (append new commit info to existing summary)
   - No → create new summary `YYMMDD_HHMM_TopicDescription.md`
2. Update `current_topic.md` with the current work topic
3. Summary content follows context-guard format: in-progress work, completed work, uncommitted changes, pending items, key decisions, container restart needs

**9b. Create README.md (for user reference)**

Create or **overwrite** a README.md in the context summary directory, containing:
- Purpose of the directory
- List of existing summary files (scan the directory)
- Topic and date for each summary
- Usage instructions (how to recover context, how to clean stale summaries)

**9c. Prompt user to execute /clear** ✗ Cannot be automated

`/clear` is a built-in CLI command that cannot be triggered programmatically by Claude.
After summary is saved, prompt the user: "Summary saved. Recommend running `/clear` to free the context window."

---

### Step 10: Lessons learned — document to guides

After completing the commit, evaluate whether this change contains **troubleshooting experience, gotchas, or non-obvious fixes** worth documenting:

1. **Criteria for documenting**: Does this fix or change involve:
   - A problem that took significant time to diagnose?
   - A non-obvious root cause (e.g., auth hanging, environment differences)?
   - Configuration that differs from documentation or defaults?
   - Workarounds for tool/platform limitations?

2. **If yes**, update the relevant guide in `.local/docs/`:
   - Add to the appropriate troubleshooting/FAQ section
   - Format: **症狀** → **原因** → **解決方式** → **注意事項**
   - If no relevant guide exists, create one

3. **Inform the user**: "已將此經驗寫入 `.local/docs/<guide>.md`，/pack 時會一併帶走。"

This ensures operational knowledge is captured in portable documentation, not lost in conversation history.

Arguments: $ARGUMENTS (optional commit message override)
