---
name: commit-push
description: Commit and push changes — auto-generate modify logs, update READMEs, evaluate service restarts, and run quality checks before committing
disable-model-invocation: true
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

### Step 2: Auto-update Modify Log

**Before committing**, create or update the modify log.

- Path: `[PROJECT_LOG_DIR]/YYYYMMDD_v[VERSION].md`
  - Adapt to the project's log directory convention. Common locations: `docs/changelog/`, `logs/`, or project-specific paths.
- Use today's date. Check existing files for the latest version number of today.
- If today already has `v1`, use `v2`, etc.

**Required fields:**

```markdown
# [Title]

## Change Info
- **Date/Time**: YYYY-MM-DD HH:MM
- **Version**: vX
- **Reason**: [Motivation or problem description]

## Change Details

| File | Lines affected | Summary |
|------|---------------|---------|
| `path/to/file` | +XX / -YY | Description |

## Impact Scope
- [List affected modules or features]

## Service Restart Requirements
- [List services that need restart, if applicable]
```

---

### Step 3: Auto-update README.md files

Check if any changed files belong to directories that have `README.md`. If the changes affect the directory's structure or functionality, update the README accordingly.

If a key functional directory lacks a README, create one with:
- Purpose of the directory
- File/directory structure
- Key functionality overview

---

### Step 4: Stage files

```bash
git status
git diff --stat
git log --oneline -3
```

- Use `git add <file>` for specific files
- Handle `.gitignore` exceptions with `git add -f <file>` when needed
- **Never** use `git add -A` or `git add .` (risk of including secrets or binaries)
- Include the updated modify log and any updated READMEs

---

### Step 5: Commit

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

### Step 6: Push

```bash
git push
```

If push fails (auth, hook, or remote error), inform the user with the error and suggest next steps.

---

### Step 7: Sync skill_general to remote repository

If any files under `skill_general/` (or its equivalent general skill folder) were changed in this commit:

1. Locate the `Skill-personal` local repo (typically `../Skill-personal/` relative to the project root)
   - If not found, clone from: `https://github.com/SWSekai/Skill-personal.git`
2. Copy all updated `skill_general/` files into the `Skill-personal` repo (overwrite)
3. Stage, commit (mirror the current commit message), and push:

```bash
cd ../Skill-personal
git add -A
git commit -m "<mirrored commit message>"
git push
```

4. If push fails, inform the user and continue — do not block the main workflow.

If no `skill_general/` files were changed, skip this step.

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

Arguments: $ARGUMENTS (optional commit message override)
