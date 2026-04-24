# `/commit-push --meta` Flag — Skill Maintenance Commit Mode

Migrated from CLAUDE.md Rule 20.1-20.4 (2026-04-24) per CLOSED_260424_claudemd_slim §3.3. Skill-maintenance commits are meta-layer work (not project feature development) and must be isolated from `modify_log` and daily reports.

## 1. `/skm new` Final Step Integration

`/skm new` Step 10 (final step) mandates one of two closures:

**Option A (default recommended)**: call `AskUserQuestion` — "是否立即 commit?"
- Select "立即 commit" → inline execute `/commit-push --meta`
- Select "稍後處理" → print reminder: "自行 commit 時請加 `--meta` flag"

**Option B (advanced)**: directly call `/commit-push --meta` (no interaction; user self-configures preference)

Skipping this step or using plaintext "要 commit 嗎？" violates Rule 15 (Y/N → Tool UI).

## 2. `--meta` Flag Behavior

When `$ARGUMENTS` contains `--meta`:
- **Skip Step 5** (`modify_log` creation) — prevents meta-layer work from being recorded as project progress
- **Skip Step 11** (daily report append) — prevents Teams report pollution
- **Keep all other steps**: quality check, README sync, staging, commit, push, sekai-workflow flowback, restart evaluation, context cleanup, guide backflow
- Suggested commit message prefix: `chore(skill):` or `docs(skill):`

## 3. When to Use `--meta`

**Applicable**:
- `/skm new` commits for new skill creation
- `/skm update` / `/skm sync` related SKILL.md / reference modifications
- CLAUDE.md / manifest.json rule-level modifications (pure meta-layer)
- `.claude/hooks/` adjustments
- `Sekai_workflow/` structural modifications (changes to this repo itself)

**NOT applicable** (use normal `/commit-push`):
- Project feature development
- Bug fixes
- Writing tests
- Any change that affects user-visible behavior in the project layer

## 4. Gray-Area Judgement

If a single commit contains BOTH project feature + skill maintenance changes:
- **Preferred**: split into two commits (feature via normal flow; skill via `--meta`)
- When inseparable: use normal `/commit-push` (feature takes priority; skill is incidental; `modify_log` topic centered on feature)

## 5. Verification

After commit with `--meta`, verify:
```bash
ls modify_log/YYMMDD_*.md  # should NOT contain an entry for this commit
grep "this commit hash" .local/report/YYMMDD_daily_report.md  # should be absent
git log -1 --format=%s  # should start with chore(skill): or docs(skill):
```

If `modify_log` entry or daily report mention is present, the flag was not honored — investigate `/commit-push` step gating logic.
