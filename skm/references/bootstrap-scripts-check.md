# Bootstrap Scripts Check for Non-Skill Top-Level Directory Changes

Migrated from CLAUDE.md Rule 23 (2026-04-24) per CLOSED_260424_claudemd_slim §3.5.e. CLAUDE.md retains a one-line trigger pointer; this file holds the enforcement detail.

## 1. When to Apply

Applies when adding, renaming, or deleting **non-skill top-level directories** in `sekai-workflow/` — e.g. `handbook/`, `docs/`, `hooks/`, `references/`, `_bootstrap/`. Missing this check causes silent failures during initialization, sync, and packaging (wrong-place copy, data loss, stale references).

## 2. Mandatory Script Audit

For every non-skill top-level directory change, audit these four scripts + `manifest.json`:

| Script | Check Point | Impact If Missed |
|---|---|---|
| `_bootstrap/sp-init.bat` | `:CopySkill` skip list | New directory mis-copied to `.claude/skills/` |
| `_bootstrap/sp-sync.sh` | `SKIP_DIRS` variable | Sync log shows anomaly (though line 79 `SKILL.md` check offers partial protection) |
| `_bootstrap/sp-pack.sh` | preserve-before-delete logic | New data directory lost during `rm -rf "$SP_DIR"` stage |
| `_bootstrap/sp-verify.bat` | verification list | Critical infrastructure directories need acceptance checks |
| `manifest.json` | `skills` and (if present) `data_directories` sections | New directory needs classification: skill / resource / data |

## 3. How to Identify "Non-Skill Directory"

- **Skill directory**: contains `SKILL.md` → handled by existing skill flow (sp-sync auto-detects)
- **Non-skill directory**: no `SKILL.md` → falls under this rule; must be manually added to skip/preserve lists

## 4. Procedure

When adding/renaming a non-skill top-level directory:

1. Read the four scripts + `manifest.json`
2. Based on directory nature (data / infrastructure / documentation), decide which skip/preserve lists to add to
3. Modify scripts + `manifest.json`
4. Smoke test (if possible): simulate sync / pack flow to confirm no mis-copy, no data-loss warnings
5. Commit message explicitly lists "已更新腳本 X/Y/Z"

## 5. Historical Lesson

On 2026-04-24, `handbook/` was added without auditing scripts. If scripts had not been caught:
- `sp-init.bat` would mis-copy `handbook/` to `.claude/skills/handbook/` (wrong location)
- `sp-pack.sh` `rm -rf "$SP_DIR"` stage would indiscriminately delete local un-pushed handbook content

This incident prompted the rule. All similar changes must follow this checklist.

## 6. Automation (Optional)

An optional pre-tool-use hook (`.claude/hooks/bootstrap_scripts_check.cjs`, not currently enabled) can detect Write/Edit operations on paths matching `sekai-workflow/<non-skill>/` and inject a reminder to consult this reference. Hook is per §3.5.e of CLOSED_260424_claudemd_slim decision; enabling is at user discretion.
