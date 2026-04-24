---
name: skill
description: "One-stop entry for Skill environment management: create new Skill, remote sync, project packaging, user-confirmed skill improvements. Subcommand routing: new / sync / pack / update."
model: sonnet
effort: medium
argument-hint: "<new|sync|pack|update> [args...]"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(git *), Bash(ls *), Bash(mkdir *), Bash(date *), Bash(cp *), Bash(bash *), Bash(cat *)
---

# /skill — Skill Environment Management Merged Skill

Integrates four responsibilities: create-skill, skill-sync, pack, and user-confirmed skill update. The first argument determines the subcommand.

## Subcommand Routing

| Subcommand | Purpose | Original Skill |
|---|---|---|
| `/skill new [name] [desc]` | Create new Skill | create-skill |
| `/skill sync` | Remote sync + rule evaluation | skill-sync |
| `/skill pack` | Project packaging (clean up skill environment) | pack |
| `/skill update [hint]` | User-confirmed skill improvement capture (replaces CLAUDE.md Rule 8 auto-inference for deliberate cases) | — (2026-04-17 added) |

When no argument is provided, ask the user to specify a subcommand.

---

## A. `/skill new` — Create New Skill

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

Project-specific Skill: lives only in `.claude/skills/`, not synced; inform the user it "will not be carried away by /skill pack".

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
   - Skips Step 11 Daily Brief Append
   - Keeps Step 1 Quality Check, Step 2 README Sync, Step 4 Commit, Step 6 Push, Step 7 sekai-workflow flowback, Step 8 Restart Eval, Step 9 Context Cleanup, Step 10 Guide
   - Commit message prefix recommendation: `chore(skill):` or `docs(skill):` — per `commit-push/references/commit-conventions.md`

3. If user chose ② → print:
   ```
   已跳過 commit。新 skill 檔案已就位；自行 commit 時請加 --meta flag：
     /commit-push --meta "<訊息>"
   以確保不誤寫 modify_log / brief。
   ```

4. Direct-call alternative: instead of AskUserQuestion, users may also configure their workflow to always auto-commit by directly invoking `/commit-push --meta` at Step 10 tail. Both paths are permitted per Rule 20 — AskUserQuestion is preferred default for safety, direct-call is opt-in.

---

## B. `/skill sync` — Rule Evaluation and Three-Way Linkage

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
1. `git fetch origin` to retrieve remote updates
2. Compare local and remote commits
3. If updated → `git pull --rebase origin main`
4. **Skills sync** — Compare each skill's SKILL.md / README.md between `Sekai_workflow/` and `.claude/skills/`; copy new or differing skills
5. **Hooks sync** — Compare each `*.cjs` / `*.sh` between `Sekai_workflow/hooks/` and `.claude/hooks/`; copy new or differing hook scripts
6. Output Added / Updated / No change summary for both skills and hooks

**Cannot be handled by script (manual required)**:
- Pull conflict → abort; resolve manually then rerun
- New skill → the script only copies files; you must manually update available Skills in `CLAUDE.md`
- **New hook → the script copies the file but `.claude/settings.local.json` binding is not auto-modified** (per-project risk). Reference `_bootstrap/templates/hooks.json` for the expected matcher/command shape; manually add the `PreToolUse` / `PostToolUse` / `Stop` entry.
- Push local changes → the script does not auto-push; you must `cd Sekai_workflow && git push origin main`

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

### Version Control Boundaries (Important)

| Path | Version Control Ownership |
|---|---|
| `CLAUDE.md` | Not under version control (local) |
| `.claude/skills/` | Not under version control (local) |
| `Sekai_workflow/` | `sekai-workflow` remote repository |
| `.local/` | Not under version control |

**Do not use `git add -f`**: files in `.gitignore` must never be added to project version control by any means.

---

## C. `/skill pack` — Project Packaging

Pack all AI-maintenance-related files in the project into `.local/ai-context/`, then delete the skill environment, restoring a clean project directory.

### Trigger

Manual invocation: `/skill pack`

### Execution

Directly run the automation script:

```bash
bash Sekai_workflow/_bootstrap/sp-pack.sh
```

### Script Behavior

1. **Collect** — `CLAUDE.md`, `.local/` work records, Memory, skills snapshot
2. **Detect project-specific skills** — compare `.claude/skills/` vs `Sekai_workflow/`; the difference is project-specific
3. **Preserve project-specific skills** → `.local/ai-context/project-skills/`
4. **Collect general guides** — scan `.local/docs/`, `docs/`, and the project root for documents containing `guide` or `指南`, copied to `guides/`
5. **Generate manifest.txt** — packaging time, file list, restore instructions
6. **Clean up** — delete `.claude/skills/`, `Sekai_workflow/`, `CLAUDE.md`

### Post-Script — AI Merge Guide (Mandatory)

After the script completes, you **must** perform an intelligent merge on `.local/ai-context/guides/`:

1. Read all collected guide documents
2. Identify duplicate/overlapping topics (e.g. multiple K8s deployment guides)
3. Merge documents on the same topic:
   - Preserve all information as much as possible; do not discard any practical details
   - Topic naming (`guide-k8s-deployment.md`, `guide-cicd-pipeline.md`)
   - Note original source paths at the top of the merged document
   - Conflicting information is kept side-by-side with differences annotated
4. Delete the original files that have been merged
5. Independent guides with no overlap → keep as-is, only rename

### Notes

- The script will ask the user to confirm (y/N) before executing deletion
- Results are in `.local/ai-context/` (already .gitignored, not under version control)
- See `manifest.txt` for the restore procedure
- **Environment info and progress notes are produced by `/team handoff`** (handoff scenarios); pack only handles Skill exit archival

### Restore Flow

1. `Sekai_workflow/_bootstrap/sp-init.bat` — rebuild environment
2. `bash Sekai_workflow/_bootstrap/sp-sync.sh` — sync latest skills
3. Copy `project-skills/` back to `.claude/skills/`
4. Copy `CLAUDE.md` back to the project root
5. Copy `memory/` back to `~/.claude/projects/.../memory/`

---

## D. `/skill update` — User-Confirmed Skill Improvement

Explicit **user-invoked** entry to codify a skill improvement that emerged from the current conversation.

**Relation to CLAUDE.md Rule 8**: Rule 8 allows Claude to proactively ask when a new rule seems to emerge. `/skill update` is the opposite direction — the user initiates, so the signal is unambiguous and Claude must not guess whether to codify. Use `/skill update` whenever you want the improvement **locked in deterministically**, bypassing AI auto-inference.

### Trigger

Manual invocation only:

| Usage | Behavior |
|---|---|
| `/skill update` | Claude asks what to capture (free-form or recent-candidate list) |
| `/skill update <one-line hint>` | Use the hint directly as the improvement description |

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

Arguments: $ARGUMENTS (the first token is the subcommand; the rest are arguments for that subcommand)
