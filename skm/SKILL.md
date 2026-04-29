---
name: skm
description: "Skill Management — one-stop entry for Skill environment management: create new Skill, remote sync, project packaging, user-confirmed skill improvements. Subcommand routing: new / sync / pack / update. Renamed from /skill on 2026-04-24 to avoid confusion with Claude Code's built-in /skills dialog."
model: sonnet
effort: medium
argument-hint: "<new|sync|pack|update|refactor> [args...]"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(git *), Bash(ls *), Bash(mkdir *), Bash(date *), Bash(cp *), Bash(bash *), Bash(cat *)
---

# /skm — Skill Management Merged Skill

> Renamed from `/skill` on 2026-04-24 to avoid confusion with Claude Code's built-in `/skills` (plural, skill-picker dialog). All subcommands and semantics unchanged — only the entry command name.

Integrates four responsibilities: create-skill, skill-sync, pack, and user-confirmed skill update. The first argument determines the subcommand.

## Subcommand Routing

| Subcommand | Purpose | Original Skill |
|---|---|---|
| `/skm new [name] [desc]` | Create new Skill | create-skill |
| `/skm sync` | Remote sync + rule evaluation | skill-sync |
| `/skm pack` | Project packaging (clean up skill environment) | pack |
| `/skm update [hint]` | User-confirmed skill improvement capture (replaces CLAUDE.md Rule 8 auto-inference for deliberate cases) | — (2026-04-17 added) |
| `/skm refactor [topic]` | Initiate cross-project structural refactor (path migration, skill rename, redirect) — writes `hanschen/.history/refactor.jsonl` for `/team sync` propagation | — (2026-04-29 added) |

When no argument is provided, ask the user to specify a subcommand.

---

## A. `/skm new` — Create New Skill

Interactively create a brand-new Claude Code Skill following existing structural conventions and completing all registrations.

### Step 1: Collect Skill Definition

Use AskUserQuestion or parse `$ARGUMENTS` to obtain:

| Field | Required | Description |
|---|:---:|---|
| name | ✓ | kebab-case (e.g. `trace-flow`) |
| command | ✓ | Slash command (e.g. `/trace-flow`) |
| description | ✓ | One-line description |
| model | ✓ | `opus` / `sonnet` / `haiku` |
| effort | ✓ | `low` / `medium` / `high` |
| argument-hint | - | Autocomplete hint |
| trigger | ✓ | Manual / automatic / conditional trigger |
| allowed_tools | ✓ | Tool list |
| steps | ✓ | Execution steps |
| scope | - | `general` / `project-specific` |

**Model Selection Guide**:
- `opus`: Uses Agent tool, cross-file analysis, architectural evaluation
- `sonnet`: Multi-step workflows, file read/write, standard development tasks
- `haiku`: Structured output, template filling, status checks
- Unsure → default to `sonnet`

If `$ARGUMENTS` contains enough information, parse directly; only ask follow-up questions when insufficient. Append `(Recommended)` to the first AskUserQuestion option.

### Step 2: Name Conflict Check

Check `.claude/skills/<name>/` and `Sekai_workflow/<name>/`:
- Exists with content → warn, ask whether to "overwrite" or "update"
- Exists but empty → treat as new
- Does not exist → proceed

### Step 3: Generate SKILL.md

`.claude/skills/<name>/SKILL.md`:

```yaml
---
name: <name>
description: "<description>"
model: <model>
effort: <effort>
argument-hint: "<argument_hint>"
allowed-tools: <allowed_tools>
---
```

Format rules:
- frontmatter order: name → description → model → effort → argument-hint → allowed-tools
- Steps use `### Step N:`
- Separate each step with `---`
- End with `Arguments: $ARGUMENTS`
- **Language rule (mandatory)**: SKILL.md is **all English** (step descriptions, tables, notes, frontmatter description all in English); exceptions: code, file paths, commands, identifier names (such as `/clean`, `YYMMDD_HHMM`) remain as-is
- Referencing subdirectories: `${CLAUDE_SKILL_DIR}/references/xxx.md`

### Step 3b: Evaluate Subdirectory Needs

| Subdirectory | Purpose | Trigger Condition |
|---|---|---|
| `references/` | Lookup tables, severity definitions, decision trees | Has separable reference material |
| `assets/` | Template files, configuration templates, initial templates | Has template files needed |
| `scripts/` | Helper scripts | Has non-protocol logic scripts |

**SKILL.md > 150 lines → must split**. Concise content (< 150 lines with no separable material) → skip.

### Step 4: Generate README.md

Includes feature description, usage, Model info (model + effort + rationale), trigger conditions, execution flow, directory structure, and parameter explanations.

**Language rule (mandatory)**: README.md is **all Traditional Chinese (Taiwan usage)**; exceptions: code, file paths, commands, identifier names, API names remain as-is. Violations of the CLAUDE.md language-division rule must be corrected.

### Step 5: Update `.claude/skills/README.md`

Add the new Skill in three locations:
1. **Skills Overview table**: insert a new row in alphabetical order
2. **Detailed description section**: insert description block in alphabetical order
3. **Directory Structure tree**: add the new folder under the `Sekai_workflow/` structure

### Step 6: Update CLAUDE.md

Insert into the `## 可用 Skills` section in alphabetical order:
```
- `/command` — description
```

### Step 7: Sync to `Sekai_workflow/` (general Skills only)

General Skill:
1. Copy the entire skill directory to `Sekai_workflow/<name>/`
2. Update `Sekai_workflow/manifest.json` (including `model` field and all file paths)
3. Update `Sekai_workflow/README.md` (table + description + tree)
4. commit + push:

```bash
cd Sekai_workflow
git add <name>/ manifest.json README.md
git commit -m "feat: add <name> skill"
git push
```

Project-specific Skill: lives only in `.claude/skills/`, not synced; inform the user it "will not be carried away by /skm pack".

### Step 8: Integrity Verification

| Check Item | ✓/✗ |
|---|:---:|
| `.claude/skills/<name>/SKILL.md` | |
| `.claude/skills/<name>/README.md` | |
| frontmatter contains `model` + `effort` | |
| Subdirectory files exist (if planned) | |
| `.claude/skills/README.md` updated | |
| `CLAUDE.md` updated | |
| `Sekai_workflow/<name>/` synced (if general) | |
| `Sekai_workflow/manifest.json` updated (if general) | |
| `Sekai_workflow/README.md` updated (if general) | |
| Step 10 commit prompt executed (AskUserQuestion or direct `/commit-push --meta`) | |

### Step 9: Output Summary

```
✓ Skill created

Name: <name>
Command: /<command>
Model: <model> (effort: <effort>)
Type: general / project-specific
Location: .claude/skills/<name>/
Structure: SKILL.md + README.md [+ references/ + assets/ + scripts/]

Updated:
- .claude/skills/README.md
- CLAUDE.md
- Sekai_workflow/ (if general)
```

### Step 10: Commit Prompt (Mandatory, per CLAUDE.md Rule 20)

Skill creation is a **meta-level maintenance** activity; its commit must not pollute the project's modify_log or daily brief. The final step asks the user whether to commit now:

1. Use AskUserQuestion (single-select) to confirm:

   | Question | Options |
   |---|---|
   | Skill 已建立完成。要立即 commit 嗎？ | ① 立即 commit & push（`/commit-push --meta`）／② 先不 commit，稍後自行處理 |

2. If user chose ① → execute `/commit-push --meta` inline. The `--meta` flag:
   - Skips Step 5 Modify Log
   - Skips Step 11 Daily Report Append
   - Keeps Step 1 Quality Check, Step 2 README Sync, Step 4 Commit, Step 6 Push, Step 7 sekai-workflow flowback, Step 8 Restart Eval, Step 9 Context Cleanup, Step 10 Guide
   - Commit message prefix recommendation: `chore(skill):` or `docs(skill):` — per `commit-push/references/commit-conventions.md`

3. If user chose ② → print:
   ```
   已跳過 commit。新 skill 檔案已就位；自行 commit 時請加 --meta flag：
     /commit-push --meta "<訊息>"
   以確保不誤寫 modify_log / daily report。
   ```

4. Direct-call alternative: instead of AskUserQuestion, users may also configure their workflow to always auto-commit by directly invoking `/commit-push --meta` at Step 10 tail. Both paths are permitted per Rule 20 — AskUserQuestion is preferred default for safety, direct-call is opt-in.

---

## B. `/skm sync` — Rule Evaluation and Three-Way Linkage

> **Remote sync (Flow 1) is now unified under `/hello` Step 2.** At the start of a conversation, use `/hello`.
> This subcommand retains the "rule evaluation and three-way linkage" responsibility, automatically triggered when Memory is written.

### Trigger Timing

1. **When new rules are added to CLAUDE.md or Memory** (automatic): evaluate whether they should be added to a Skill
2. **When `Sekai_workflow/` is modified** (automatic): sync to remote
3. **Manual invocation**: force the full sync flow (including remote sync + rule evaluation)

### Flow 1: `Sekai_workflow/` Remote Sync

Directly run the automation script:

```bash
bash Sekai_workflow/_bootstrap/sp-sync.sh
```

The script performs:
1. **Step 0 Pre-fetch compat check** — Read local `file_manifest.json`; if `manifest.schema_version > SCRIPT_SCHEMA_COMPAT`, abort (exit 2) with "update sp-sync.sh and rerun". Skip if no manifest yet or node unavailable.
2. `git fetch origin` to retrieve remote updates
3. Compare local and remote commits
4. If updated → `git pull --rebase origin main`
5. **Step 1c Post-pull drift check** — Re-read pulled manifest; same schema gate. Also compare on-disk `sp-sync.sh` `SCRIPT_VERSION` against the currently running value — if different, warn and abort (exit 3) so the user reruns with the newer script.
6. **Skills sync** — Compare each skill's SKILL.md / README.md between `Sekai_workflow/` and `.claude/skills/`; copy new or differing skills
7. **Manifest reconciliation** — Read `Sekai_workflow/file_manifest.json`; for every entry in `skill_aliases` (old→new rename map), detect stale folders at `.claude/skills/<old>/` and `Sekai_workflow/<old>/`, then interactively prompt the user to remove them. Non-interactive runs skip removal.
8. **Hooks sync** — Compare each `*.cjs` / `*.sh` between `Sekai_workflow/hooks/` and `.claude/hooks/`; copy new or differing hook scripts
9. **Statusline sync** — Sync `statusline.cjs` + patch `~/.claude/settings.json` `statusLine.command`
10. Output `Version — Script / Schema` plus Added / Updated / No change summaries for skills, manifest-stale, hooks, and statusline

**Cannot be handled by script (manual required)**:
- Pull conflict → abort; resolve manually then rerun
- New skill → the script only copies files; you must manually update available Skills in `CLAUDE.md`
- **New hook → the script copies the file but `.claude/settings.local.json` binding is not auto-modified** (per-project risk). Reference `_bootstrap/templates/hooks.json` for the expected matcher/command shape; manually add the `PreToolUse` / `PostToolUse` / `Stop` entry.
- Push local changes → the script does not auto-push; you must `cd Sekai_workflow && git push origin main`

### Flow 1b: `.local/` Structure Drift Scan (Mandatory Post-Sync)

After Flow 1 completes, **scan `.local/` for drift against the newly-synced Skill expectations**. Skill renames, path conventions changes, or deprecated directories often leave stale files in `.local/` that Skills no longer reference — silently accumulating dead state.

**Scan items** (report, do not auto-delete):

1. **Legacy singular/plural directories** — e.g. `modify_logs/` when skills use `modify_log/`, `whiteboards/` vs `whiteboard/`. List any `.local/<dir>` or `.local/docs/<dir>` not referenced by any synced SKILL.md.
2. **Renamed subcommand artifacts** — e.g. if `/team living` renamed to `/team journal`, check whether `hanschen/docs/living/` needs redirect / alias.
3. **Orphan directories** — directories under `.local/` with no SKILL.md reference (grep `.local/<name>` across all `.claude/skills/**/*.md`). Classify as: likely-obsolete / project-specific / needs-user-judgment.
4. **Filename convention drift** — files in `decisions/` without `_decision.md` suffix, in `whiteboards/` without `_board.md` suffix, etc. Report count, do not rename (existing files per `team/references/naming.md` remain valid).
5. **Path-expectation mismatches** — e.g. Skill expects `.local/collab/TODO.md` but project keeps `./TODO.md`. Check config-flexible paths (see `team/SKILL.md` §A location resolution).

**Output format** (present to user, require confirmation for destructive ops):

```
.local/ Drift Report (Skill sync revealed):
  A. Safe auto-merge (executed):
     - modify_logs/ → modify_log/ (2 files merged)
  B. Needs decision:
     - docs/decisions/ vs Skill singular spec (4 files)
  C. Orphan dirs (no Skill reference):
     - docs/pending/ (1 file) — suggest archive to PROJECT_JOURNAL.md
     - docs/changelog/ (experiment data, likely retain)
  D. Path mismatches:
     - ./TODO.md at root (Skill now accepts both root + .local/collab/)
```

Safe merges (pure rename of legacy-plural → active-singular with no semantic conflict) may be auto-executed. All other categories require user confirmation before action.

### Flow 2: Rule Evaluation and Three-Way Linkage (Mandatory)

> **When writing to Memory, evaluation and execution must be completed in the same reply. Do not end the reply after just writing Memory.**
>
> Memory mostly represents user habits and behavior preferences, which are cross-project general. Rules stored only in Memory take effect only in the current project and cannot be carried to new projects with `Sekai_workflow`.

**After writing Memory, immediately decide**:

1. **Is it a reusable behavioral constraint or process rule?** → sync-update `CLAUDE.md`
2. **Is it cross-project general?** → reflow back to `Sekai_workflow/` template and push to remote
3. **Does it only apply to the current project?** → Memory only, no reflow

Full decision tree and 5 evaluation questions:

See `${CLAUDE_SKILL_DIR}/references/evaluation-decision-tree.md` (if it exists; otherwise included in this file).

### Flow 3: `file_manifest.json` Maintenance (Mandatory for Renames/Retirements)

`Sekai_workflow/file_manifest.json` is the single source of truth for **which folders should exist where** and **which old folders must be cleaned up** after a rename/retirement. `sp-sync.sh` Step 2b reads this file to detect stale folders and interactively remove them.

#### Structure

```json
{
  "schema_version": 1,
  "version": 1,
  "updated": "<YYYY-MM-DD>",
  "skill_aliases": { "<old-name>": "<new-name>" },
  "skills":        { "<name>": { "required_files": [...] } },
  "hooks":         { "<name>": { "file": "...cjs", "binding": "..." } },
  "system":        {
    "statusline":     { "template": "...", "canonical": "..." },
    "sp_sync_script": { "canonical": "...", "version": "1.1", "purpose": "..." }
  },
  "data_folders":  { "<name>": { "location": "...", "description": "..." } }
}
```

#### When to Update the Manifest

| Scenario | Required Update |
|---|---|
| Rename a skill (e.g. `skill` → `skm`) | Add `skill_aliases["skill"] = "skm"`; rename the `skills` entry; bump `updated` |
| Retire a skill | Add it to `skill_aliases` with the new owner or `null`; remove from `skills` |
| Add a new skill | Add a `skills` entry with `required_files` |
| Add a new hook | Add a `hooks` entry with `file` + `binding` |
| Move a system-level file | Update the corresponding `system` entry |
| Add a new cross-project data folder (like `knowledge_base/`) | Add a `data_folders` entry |

#### Enforcement Points

- **`/skm new` Step 3b** — when creating a skill, write an entry to `skills` in the manifest
- **`/skm update` Step 3** — when the change is a rename/move, update `skill_aliases` in the same diff
- **`/skm sync` Flow 1** — `sp-sync.sh` Step 2b reads manifest and reconciles stale folders (interactive)
- **Manual manifest edit → commit + push `.sekai-workflow/`** so other machines pick it up on next sync

#### Stale Detection Logic (Step 2b)

For each `(oldName, newName)` in `skill_aliases`:
- If `.claude/skills/<oldName>/` exists → flag as STALE (local)
- If `.sekai-workflow/<oldName>/` exists → flag as STALE (sekai)
- List all flagged paths → ask user `y/N` → `rm -rf` on `y`
- Non-interactive run (no tty) → skip removal, keep for manual cleanup

#### Safety Principles

1. **Remove only what is in `skill_aliases`** — orphan detection (folders in .claude/skills but nowhere in manifest) is a **future enhancement**; do not delete anything outside the alias map
2. **Always interactive** — the script asks before deleting; never silent `rm -rf`
3. **Manifest is the contract** — do not hand-delete renamed folders; update the manifest and let `sp-sync.sh` do it so every cloned project converges

#### Schema Version & Script Compat (2026-04-24 added)

`sp-sync.sh` is the **receiving end** that consumes this manifest; they are versioned together to prevent old scripts from silently misinterpreting newer-structure manifests.

| Field | Location | Meaning |
|---|---|---|
| `schema_version` | `file_manifest.json` (top-level) | Integer describing the manifest's field set and semantics. Bump when adding new tracked field types or changing how existing fields are interpreted. |
| `SCRIPT_VERSION` | `sp-sync.sh` (top of file) | Semver-ish string identifying this script's logic. Bump when Step flow or behavior changes. |
| `SCRIPT_SCHEMA_COMPAT` | `sp-sync.sh` (top of file) | Integer — the highest `schema_version` this script can correctly parse. Bump only when the script gains support for newer manifest schemas. |
| `system.sp_sync_script.version` | `file_manifest.json` | Declared current script version — documentation for humans; the authoritative check compares the running-process `SCRIPT_VERSION` against the `SCRIPT_VERSION=` line in the on-disk script after pull. |

**Check points** (implemented in sp-sync.sh):

1. **Step 0 Pre-fetch** — read local manifest; abort with exit 2 if `schema_version > SCRIPT_SCHEMA_COMPAT`. Guards against running with an old local script after a prior machine pushed a schema bump.
2. **Step 1c Post-pull** — re-read manifest after pull + grep on-disk script's `SCRIPT_VERSION=`; abort with exit 3 if either drifted. The receiver must rerun with the freshly pulled sp-sync.sh so the new logic is actually in effect.

**Bump rules**:

| Change kind | schema_version | SCRIPT_VERSION | SCRIPT_SCHEMA_COMPAT |
|---|---|---|---|
| Cosmetic script fix (logs, formatting) | — | +0.1 | — |
| New Step or non-schema logic change | — | +0.1 | — |
| New manifest field consumed by script | +1 (manifest) | +0.1 (script) | raise to new schema_version |
| Breaking rename of manifest field | +1 (manifest) | new major (script) | raise to new schema_version |

**Hard rule**: A manifest commit that bumps `schema_version` **must in the same commit** bump `SCRIPT_SCHEMA_COMPAT` in sp-sync.sh — otherwise the pushing machine itself will fail Step 0 on the next sync.

---

### Version Control Boundaries (Important)

| Path | Version Control Ownership |
|---|---|
| `CLAUDE.md` | Not under version control (local) |
| `.claude/skills/` | Not under version control (local) |
| `Sekai_workflow/` | `sekai-workflow` remote repository |
| `.local/` | Not under version control |

**Do not use `git add -f`**: files in `.gitignore` must never be added to project version control by any means.

### Non-Skill Directory Changes (CLAUDE.md Rule 23)

When adding, renaming, or deleting **non-skill top-level directories** under `sekai-workflow/` (those without a `SKILL.md`, e.g. `handbook/`, `docs/`, `hooks/`, `references/`), you **must** also verify and update the bootstrap scripts:

| Script | Checkpoint | Failure mode if missed |
|---|---|---|
| `_bootstrap/sp-init.bat` | `:CopySkill` skip list | Directory mis-copied into `.claude/skills/` as a fake skill |
| `_bootstrap/sp-sync.sh` | `SKIP_DIRS` variable | Noisy sync log (silent pass due to `SKILL.md` guard, but should be explicit) |
| `_bootstrap/sp-pack.sh` | preserve-before-delete logic | `rm -rf $SP_DIR` deletes unpushed local content |
| `_bootstrap/sp-verify.bat` | verification checklist | Missing infra validation |
| `manifest.json` | `skills` / data-dir classification | Directory mis-classified |

**Criterion**: does the directory contain `SKILL.md`? No → non-skill → this rule applies.
**Origin**: 2026-04-24 `handbook/` rename incident where `sp-init.bat` and `sp-pack.sh` would have silently broken; rule codified into CLAUDE.md Rule 23.

---

## C. `/skm pack` — Project Packaging (Closure Flow)

Pack all AI-maintenance-related files, archive cross-project knowledge assets, and restore a clean project directory. Serves as the **project closure flow**.

The pack flow runs **all phases in one invocation**: audit → collect → changeset review → execute. **No writes occur before the user confirms the changeset in Phase 3.**

### Trigger

Manual invocation: `/skm pack`

---

### Phase 1: Pre-Pack Audit

#### Step 1: Memory Audit

Scan all memory files in `~/.claude/projects/<path>/memory/`:
- Assess each entry: **Keep** (cross-session, non-duplicate) / **Merge** (same rule in two entries) / **Remove** (stale, duplicate, ephemeral)
- Do **not** modify yet — queue for Phase 3 confirmation

#### Step 2: Skill Sync Verification

For each skill in `.claude/skills/`: diff against `sekai-workflow/<skill>/`:
- **Synced** / **Diverged** (needs push) / **Local-only** (project-specific)
- If any general skill is diverged → invoke `/skm sync` before proceeding
- Confirm remote is current: `cd sekai-workflow && git fetch origin && git status`

#### Step 3: CLAUDE.md Comparison

Compare local `CLAUDE.md` against `sekai-workflow/_bootstrap/CLAUDE.md.template`:
- Identify local additions → propose reflow if cross-project general
- Queue approved changes for Phase 3 confirmation

---

### Phase 2: Collect & Package

#### Step 4: Export Session Commands
- Diff `.claude/skills/` vs `sekai-workflow/` → project-specific entries
- List `CLAUDE.md` entries not in `sekai-workflow/manifest.json`
- Output: `.local/bag/session-commands.md`

#### Step 5: Archive Knowledge Documents
- Scan `.local/docs/`, `docs/`, project root for guides / ADRs
- Output: `.local/bag/docs/`

#### Step 6: Auto-Generate `.skill` Files
- For each project-specific skill: generate `.local/bag/project-skills/<name>.skill` from frontmatter

#### Step 7: Document Consolidation into `bag/`
- Merge same-topic docs into single files; annotate conflicts; delete originals
- Also snapshot: `.local/bag/memory/`, `.local/bag/CLAUDE.md`, `.local/bag/skills/`

---

### Phase 3: Changeset Review

#### Step 8: Changeset Preview & User Confirmation

Present full planned changeset before any writes:
```
📦 Pack Changeset Review
[Memory]      Keep / Merge / Remove counts
[Skill Sync]  Synced / Diverged / Local-only
[CLAUDE.md]   Template additions / local-only rules
[bag/ tree]   Full file list
[Cleanup]     Files to delete after confirmation
⚠️  Sensitive files: <list or "none">
```
Use AskUserQuestion — Phase 4 executes only after approval.

---

### Phase 4: Execute

#### Step 9: Clean Up
After user approval:
1. Apply memory changes (Step 1 plan)
2. Update `sekai-workflow/_bootstrap/CLAUDE.md.template` if approved (Step 3)
3. Run `bash sekai-workflow/_bootstrap/sp-pack.sh` — collects, generates manifest.txt, deletes `.claude/skills/`, `sekai-workflow/`, `CLAUDE.md`, temp files
4. `bag/` is **not deleted** — remains for user review and transfer

#### Step 10: Output Closure Report
Generate `.local/bag/closure-report.md` covering all phases.

---

### Notes

- All output is under `.local/bag/` (gitignored)
- `bag/` is the primary transfer artifact for new projects
- **Environment info / progress notes → `/team handoff`**; pack handles Skill exit archival only

### Restore Flow

1. `sekai-workflow/_bootstrap/sp-init.bat` — rebuild environment
2. `bash sekai-workflow/_bootstrap/sp-sync.sh` — sync latest skills
3. Copy `.local/bag/project-skills/` back to `.claude/skills/`
4. Copy `.local/bag/CLAUDE.md` back to the project root
5. Copy `.local/bag/memory/` back to `~/.claude/projects/.../memory/`

---

## D. `/skm update` — User-Confirmed Skill Improvement

Explicit **user-invoked** entry to codify a skill improvement that emerged from the current conversation.

**Relation to CLAUDE.md Rule 8**: Rule 8 allows Claude to proactively ask when a new rule seems to emerge. `/skm update` is the opposite direction — the user initiates, so the signal is unambiguous and Claude must not guess whether to codify. Use `/skm update` whenever you want the improvement **locked in deterministically**, bypassing AI auto-inference.

### Trigger

Manual invocation only:

| Usage | Behavior |
|---|---|
| `/skm update` | Claude asks what to capture (free-form or recent-candidate list) |
| `/skm update <one-line hint>` | Use the hint directly as the improvement description |

### Step 1: Clarify the Improvement

If `$ARGUMENTS` contains a hint → use it as the starting description.
Otherwise, use AskUserQuestion with a free-form option and (if detectable from recent turns) 1–3 candidate improvements extracted from the conversation.

Confirm one-sentence summary of the improvement before proceeding. If ambiguous, ask follow-up.

### Step 2: Identify Target Skill

Match the improvement to the most-relevant skill folder under `.claude/skills/`:

- Behavior about decision tables, whiteboards, TODOs → `team`
- Commit / log / push / deploy rules → `commit-push` or `build`
- Skill-creation conventions → `skill` (this skill itself)
- Context cleanup / summary → `clean`
- System info or trace rules → `ask`
- Conversation start / environment pull → `hello`

Ambiguous → AskUserQuestion listing 2–3 candidate skills, first option marked `(Recommended)`.

### Step 3: Draft the Change

1. Read `.claude/skills/<skill>/SKILL.md` (+ README.md if structural change)
2. Propose: insertion location (file + section) + **exact diff** (old_string / new_string preview)
3. Evaluate side-effects:
   - frontmatter `description` / `argument-hint` update needed?
   - Subcommand Routing table change needed?
   - New section numbering collision?
4. Present the full diff to the user

AskUserQuestion:
- `接受並套用 (Recommended)`
- `我要調整措辭` → user provides edits → redraft
- `取消`

### Step 4: Apply to `.claude/skills/<skill>/`

Edit SKILL.md + README.md as drafted. Do **not** also update `.sekai-workflow/` yet — reserve that for Step 5 so the diff is reviewable isolated.

### Step 5: Mirror to `.sekai-workflow/<skill>/` (general skills only)

1. Apply the same diff to `.sekai-workflow/<skill>/SKILL.md` (+ README.md)
2. `diff -q .claude/skills/<skill>/SKILL.md .sekai-workflow/<skill>/SKILL.md` → expect no output
3. Project-specific skill (only in `.claude/skills/`, not in `.sekai-workflow/`) → skip, note it in summary

### Step 6: Evaluate CLAUDE.md Impact

Update root `CLAUDE.md` **only if** the change:
- Adds a new subcommand to an existing skill → update the `## 可用 Skills` line for that skill
- Adds a new top-level command line option or flag
- Introduces a cross-project rule that belongs in the numbered core-rules list

Otherwise leave CLAUDE.md unchanged and state "CLAUDE.md: no change needed" in the summary.

### Step 7: Commit and Push `.sekai-workflow/`

```bash
cd .sekai-workflow
git add <skill>/
# README.md / manifest.json if touched
git commit -m "feat(skill): <skill> — <one-line improvement summary>"
git push
```

If push fails (conflict) → pull --rebase, resolve, retry. Do **not** force-push.

### Step 8: Output Summary

```
✓ Skill updated

Skill: <skill>
Change: <one-line summary>
Files modified:
  - .claude/skills/<skill>/SKILL.md (+ README.md if applicable)
  - .sekai-workflow/<skill>/SKILL.md (+ README.md if applicable)
CLAUDE.md: updated / no change
.sekai-workflow commit: <hash>
```

### Design Principles

- **User-initiated, never AI-inferred**: running only on explicit invocation eliminates the risk of Claude silently codifying misunderstandings.
- **Explicit diff preview before writing**: Step 3 always surfaces the exact change for approval.
- **Three-way sync automatic**: Rule 9 (`.claude/skills/` ↔ `.sekai-workflow/` ↔ CLAUDE.md) enforced without extra prompting.
- **Single improvement per invocation**: keeps the commit focused and reviewable; for batched updates, invoke repeatedly.

---

## E. `/skm refactor` — Cross-Project Structural Refactor Initiation

Initiate a structural refactor (path migration, skill rename, workflow redirect) and record it in `hanschen/.history/refactor.jsonl` so other machines / projects can pick it up via `/team sync` Step 0.

### Why This Subcommand Exists

Per CLOSED_260429_hanschen_dir_governance_decision.md §03.A (strict separation of `hanschen/` vs `.local/`), the codebase does not use runtime fallback. Cross-machine consistency relies on:

- **`/skm refactor`** — initiator: writes refactor intent to `hanschen/.history/refactor.jsonl`
- **`/team sync` Step 0** — receiver: reads history, prompts to apply pending migrations on each machine

This subcommand is the entry for the "initiator" half.

### Triggers

| Usage | Behavior |
|---|---|
| `/skm refactor` | Interactive: ask refactor type + parameters |
| `/skm refactor migrate <from> <to>` | Path migration: scan `<from>`, propose move to `<to>` |
| `/skm refactor rename-skill <old> <new>` | Skill rename: update `skill_aliases` in manifest, scan stale folders |
| `/skm refactor redirect <skill> <from> <to>` | Workflow redirect: e.g., `/team note` writes go to `/kb add` instead |

### Step 1: Refactor Type Selection

If no args → AskUserQuestion: which refactor type? (path_migration / skill_rename / skill_redirect / other)
If args provided → parse directly.

### Step 2: Impact Analysis (Mandatory before write)

For the chosen refactor type:

1. **Scan affected files** — list all paths matching the `from` pattern across this project
2. **Scan skill references** — grep `.claude/skills/**/*.md` for the old path / command
3. **Scan sekai-workflow mirror** — grep `.sekai-workflow/**/*.md` for the same
4. **Estimate fan-out** — how many files / commands will need updating
5. Present summary; require AskUserQuestion confirm before proceeding

### Step 3: Write Refactor Record

Append to `hanschen/.history/refactor.jsonl`:

```json
{"date":"YYYY-MM-DD","type":"path_migration","from":"<old>","to":"<new>","scope":"all|<skill>","decision":"CLOSED_*.md (if linked)","ttl_days":90,"note":"<optional>"}
```

If `hanschen/.history/` does not exist → create it. If `refactor.jsonl` does not exist → create with this entry.

### Step 4: Apply Locally

Execute the refactor on the current project:

- **path_migration** — `mv` files from `<from>` to `<to>`; update `.gitignore` if needed
- **skill_rename** — Edit affected SKILL.md files; update `manifest.json` `skill_aliases`
- **skill_redirect** — Edit affected SKILL.md files; insert redirect note + legacy section

### Step 5: Update Skill Files

If the refactor changes paths or commands referenced in skills:

1. Batch-update all `.claude/skills/**/*.md` files
2. Mirror to `.sekai-workflow/**/*.md`
3. Update `CLAUDE.md` if cross-project rule

### Step 6: Commit (with `--meta` flag)

Skill / workflow refactors are meta-level. Default to `/commit-push --meta`:
- Skips modify_log generation (refactor record is the log)
- Skips daily report append

### Step 7: Cross-Machine Propagation

Print:
```
✓ Refactor recorded: hanschen/.history/refactor.jsonl
  Other machines / projects will detect this on next /team sync.
  Auto-apply available: /team sync --auto-migrate
```

### Step 8: Self-Check

- [ ] `hanschen/.history/refactor.jsonl` contains new entry
- [ ] Affected `.claude/skills/` files updated
- [ ] `.sekai-workflow/` mirror updated (if general refactor)
- [ ] `CLAUDE.md` updated (if cross-project rule)
- [ ] Commit made with `--meta` (or queued for user)

### Design Principles

- **Append-only history** — never delete entries; expired entries (>90d) marked but kept for audit
- **Two-phase migration** — initiator (this subcommand) records intent; receivers (`/team sync`) apply per-project
- **Decision-traceable** — each refactor record links to a CLOSED_*.md decision when available
- **No runtime fallback** — `hanschen/` and `.local/` are strictly separated (per §03.A); migration consistency is enforced through this history mechanism, not skill-layer if/else

---

Arguments: $ARGUMENTS (the first token is the subcommand; the rest are arguments for that subcommand)
