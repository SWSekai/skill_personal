---
name: commit-push
description: Commit and push changes — auto-generate local modify logs, update READMEs, evaluate service restarts, and run quality checks. No .gitignore files are ever force-added.
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

Before staging, read `.gitignore` to verify:
- **All files matching `.gitignore` patterns must NOT be staged — no exceptions**
- This includes: `.env`, `*.log`, `__pycache__/`, secrets, binaries, `CLAUDE.md`, `.claude/skills/`, `.local/`, `.skill_personal/`, or any project-specific ignored paths
- **Never use `git add -f`** — files in `.gitignore` are excluded from project version control by design
- If a file about to be staged matches `.gitignore`, **warn the user and skip it**

> **Note**: A pre-commit hook (installed by `setup.bat`) provides a hard block as the last line of defense.
> Even if `git add -f` is used, the commit will be rejected if `.claude/`, `skill_personal/`, or `CLAUDE.md` are staged.
> Run `skill_personal/verify.bat` to confirm the hook is active.

**3c. Stage files**

- Use `git add <file>` for specific files only
- **Never** use `git add -f`（no force-adding of any file）
- **Never** use `git add -A` or `git add .` (risk of including secrets or binaries)
- Include any updated READMEs

**3d. Confirm with user before committing**

List all files about to be committed, then ask the user for confirmation before proceeding.

---

### Step 4: Commit

- Follow the project's commit message conventions (detect from `git log`)
- If no convention is established, use Conventional Commits:
  - `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`
- First line: short summary (under 72 chars)
- Body: bullet points of key changes
- End with: `Co-Authored-By: Claude <noreply@anthropic.com>`
- Use HEREDOC format for multi-line messages:

```bash
git commit -m "$(cat <<'EOF'
type: short summary

- change 1
- change 2

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

---

### Step 5: Auto-create Modify Log (local only, not committed)

After commit, create the modification log:

1. Get the commit hash:
   ```bash
   git log --oneline -1
   ```
2. Invoke the `modify-log` skill with the commit hash
3. Path: `.local/logs/YYMMDD_TopicDescription.md`
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

**9c. Execute /clear**

After summary is saved, execute `/clear` to free the context window.
- No user confirmation needed (this is an automatic cleanup step of the commit-push workflow)

Arguments: $ARGUMENTS (optional commit message override)
