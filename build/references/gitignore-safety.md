# .gitignore Safety Rules

## Before Staging

Read `.gitignore` to verify:

- **All files matching `.gitignore` patterns must NOT be staged — no exceptions**
- This includes: `.env`, `*.log`, `__pycache__/`, secrets, binaries, `CLAUDE.md`, `.claude/skills/`, `.local/`, `Sekai_workflow/`, or any project-specific ignored paths
- **Never use `git add -f`** — files in `.gitignore` are excluded from project version control by design
- If a file about to be staged matches `.gitignore`, **warn the user and skip it**

## Staging Commands

- Use `git add <file>` for specific files only
- **Never** use `git add -f` (no force-adding of any file)
- **Never** use `git add -A` or `git add .` (risk of including secrets or binaries)

## Pre-commit Hook (Last Line of Defense)

> A pre-commit hook (installed by `sp-init.bat`) provides a hard block as the last line of defense.
> Even if `git add -f` is used, the commit will be rejected if `.claude/`, `Sekai_workflow/`, or `CLAUDE.md` are staged.
> Run `Sekai_workflow/_bootstrap/sp-verify.bat` to confirm the hook is active.
