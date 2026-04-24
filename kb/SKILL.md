---
name: kb
description: "Manage sekai-workflow/knowledge_base/ — archive general technical notes (Docker, K8s, ETL, algorithms, backend patterns), auto-extract from decision/board closures, and retrieve relevant content when answering technical questions."
model: sonnet
effort: medium
argument-hint: "<add|search|extract> [topic|query|source-path]"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(git *), Bash(mkdir *), Bash(ls *), Bash(date *)
---

# /kb — Knowledge Base Manager

Maintains `sekai-workflow/knowledge_base/` as a cross-project reference library. Engineers and the model retrieve notes, templates, and best-practice examples without re-deriving them from scratch.

## Subcommand Routing

| Subcommand | Purpose |
|---|---|
| `/kb add <topic>` | Create or update a knowledge document |
| `/kb search <query>` | Search and return relevant sections inline |
| `/kb extract [source]` | Extract reusable content from a closed decision/board file |
| *(auto)* | On `/team` closure → check for extractable content; when answering technical questions → scan for relevant docs |

When no subcommand provided → treat as `/kb search <$ARGUMENTS>`.

---

## A. `/kb add` — Create or Update Knowledge Document

### Step 1: Determine Category

Map topic to a directory under `sekai-workflow/knowledge_base/`:

| Keyword signals | Directory |
|---|---|
| docker, container, compose, dockerfile | `docker/` |
| kubernetes, k8s, helm, pod, deployment | `kubernetes/` |
| etl, pipeline, airflow, spark, ingestion | `etl/` |
| algorithm, sort, search, dp, graph, complexity | `algorithms/` |
| backend, api, rest, grpc, auth, db, sql, orm | `backend/` |
| Unclear / cross-domain | `_general/` |

### Step 2: Check Existing Document

Glob `sekai-workflow/knowledge_base/<category>/<topic>.md`:
- Exists → update (append section or revise stale content)
- Not exists → create new

### Step 3: Write Document

Use the template at `D:/hanschen/personal_work/sekai-workflow-edit/.claude/skills/kb/assets/kb-doc-template.md`. Key structure: Overview → Quick Reference → Details → Examples → References.

Requirement: content must be **general and reusable** — no project-specific business logic, no hardcoded hostnames or credentials.

### Step 4: Update `_index.md`

Append or update the row in `sekai-workflow/knowledge_base/_index.md`:
```
| <topic> | <category> | <one-line description> | YYYY-MM-DD |
```

### Step 5: Commit

```bash
cd sekai-workflow
git add knowledge_base/
git commit -m "docs(kb): add/update <topic>"
git push
```

---

## B. `/kb search` — Search Knowledge Documents

### Step 1: Extract Keywords

Parse `$ARGUMENTS` for keywords; strip stop words.

### Step 2: Glob + Grep

```bash
grep -ri "<keyword>" sekai-workflow/knowledge_base/ --include="*.md" -l
```

Read top 3 most relevant files (score by: title match > heading match > body frequency).

### Step 3: Return Content Inline

Present relevant sections directly in the reply — do not make the user open the file. Note source path at the end for deep reading.

If 0 results → answer from model knowledge; if the answer is substantial, offer `/kb add` to archive it.

---

## C. `/kb extract` — Extract from Decision/Board Closure

Triggered automatically after `/team decide` or `/team board` closes, or manually with a file path.

### Step 1: Identify Source

- Manual: `$ARGUMENTS` is a file path → read that file
- Auto-trigger: read the `CLOSED_*` file just produced by `/team`

### Step 2: Scan for Reusable Patterns

Look for:
- Config snippets (Docker Compose, K8s manifests, SQL schemas, environment variable sets)
- Algorithm descriptions with complexity notes
- API design patterns, auth flows, error-handling conventions
- ETL schemas or transformation logic
- Architecture decisions with rationale that applies beyond this project

**Skip**: project-specific business logic, company-internal URLs, temporary workarounds, context-bound one-off decisions.

### Step 3: Propose Items

For each extractable item:
```
📚 Extractable: <topic>
   Category:  <directory>
   Reason:    <why it's generally reusable>
   Preview:   <first 4 lines of content>
```

Use AskUserQuestion (multi-select) — user picks which items to archive.
Auto-trigger mode: if 0 items found, skip silently.

### Step 4: Execute `/kb add` for Each Selected Item

Call the add flow inline for each approved item.

---

## D. Auto-Trigger: Question Enhancement

When answering a technical question (infrastructure, patterns, algorithms, backend):

1. Glob `sekai-workflow/knowledge_base/**/*.md` for topic-relevant files
2. If relevant doc found → read it, prefix the answer with retrieved content, note source path
3. If no doc found → answer from model knowledge; if answer is > 200 words, offer to add it to knowledge_base

---

Arguments: $ARGUMENTS (first token is subcommand; the rest are topic/query/path)
