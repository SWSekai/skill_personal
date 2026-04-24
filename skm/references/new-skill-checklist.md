# New Skill Integrity Checklist

Run this checklist after creating a new skill via `/skm new` or manually. Migrated from CLAUDE.md Rule 10 (2026-04-24) per CLOSED_260424_claudemd_slim decision §3.6.

## Mandatory items

- [ ] Skill folder contains both `SKILL.md` and `README.md`
- [ ] `.claude/skills/README.md` updated with new skill entry
- [ ] `Sekai_workflow/` mirror folder synced (cross-project portability per Rule 4)
- [ ] `CLAUDE.md` 可用 Skills list updated
- [ ] **Subdirectory structure per Rule 19**: at minimum includes `references/`; `assets/` holds only templates and sample data (no executables); `agents/` and `scripts/` are optional (see Rule 19 trade-offs)
- [ ] **SKILL.md holds only external contract**: subcommand routing, usage, step outline. Detail rules, parser logic, data structures all live in `references/`

## Language split

- `SKILL.md` — English (Claude-execution contract)
- `README.md` — Traditional Chinese (human-reading)
- `references/*.md` — same language as SKILL.md (English)
- `assets/*.md` templates — can retain Chinese for user-facing text

## Verification

After the checklist, verify via:
```bash
ls .claude/skills/<new>/       # SKILL.md + README.md present
ls .claude/skills/<new>/references/   # at least one .md
grep "<new>" .claude/skills/README.md
grep "<new>" CLAUDE.md         # Available Skills list
ls Sekai_workflow/<new>/        # mirror exists
```

Any missing item is a Rule 10 violation — must be completed before closing the `/skm new` flow.
