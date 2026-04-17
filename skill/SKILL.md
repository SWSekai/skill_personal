---
name: skill
description: "One-stop entry for Skill environment management: create new Skill, remote sync, project packaging. Subcommand routing: new / sync / pack."
model: sonnet
effort: medium
argument-hint: "<new|sync|pack> [args...]"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(git *), Bash(ls *), Bash(mkdir *), Bash(date *), Bash(cp *), Bash(bash *), Bash(cat *)
---

# /skill — Skill Environment Management Merged Skill

Integrates three responsibilities: create-skill, skill-sync, and pack. The first argument determines the subcommand.

## Subcommand Routing

| Subcommand | Purpose | Original Skill |
|---|---|---|
| `/skill new [name] [desc]` | Create new Skill | create-skill |
| `/skill sync` | Remote sync + rule evaluation | skill-sync |
| `/skill pack` | Project packaging (clean up skill environment) | pack |

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
4. Compare each skill's SKILL.md / README.md between `Sekai_workflow/` and `.claude/skills/` one by one
5. Automatically copy new or differing skills to `.claude/skills/`
6. Output an Added / Updated / No change summary

**Cannot be handled by script (manual required)**:
- Pull conflict → abort; resolve manually then rerun
- New skill → the script only copies files; you must manually update available Skills in `CLAUDE.md`
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

Arguments: $ARGUMENTS (the first token is the subcommand; the rest are arguments for that subcommand)
