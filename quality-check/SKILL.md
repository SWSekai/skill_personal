---
name: quality-check
description: "Pre-commit code quality audit — redundancy, impact analysis, architecture conformance, and risk assessment. IMPORTANT: After quality check passes, ensure modify-log skill is invoked after commit to create the local modification log."
allowed-tools: Read, Grep, Glob, Agent
---

## Quality & Impact Check

Perform a comprehensive quality audit on changed files. This skill is automatically invoked as part of the `/commit-push` flow, but can also be called standalone.

### 1. Code Quality Scan

For each changed file, check:

- **Dead code**: Unused imports, unreachable branches, commented-out code blocks
- **Redundancy**: Duplicated logic across files, copy-paste patterns that should be abstracted
- **Hardcoded values**: Magic numbers or strings that should be in config/constants
- **Error handling**: Missing try/catch at system boundaries (API endpoints, external calls, file I/O)
- **Type consistency**: Mismatches between layers (e.g., frontend sends string, backend expects int)
- **Serialization risks**: Values that could be lost during JSON/protobuf/form serialization
- **Security**: SQL injection, XSS, command injection, exposed secrets, OWASP Top 10

### 2. Architecture Conformance

Verify changes follow the project's existing patterns:

- Read 3-5 existing files in the same directory to understand conventions
- Check: naming patterns, error handling style, logging patterns, response format
- Flag deviations with specific examples of the existing pattern

### 3. Impact Assessment

For each change, evaluate:

- **Upstream**: Who calls this function/endpoint? Will callers break?
- **Downstream**: What does this function call? Are contracts still valid?
- **State**: Does this change DB schema, cache keys, file paths, or environment variables?
- **Concurrency**: Could this cause race conditions in multi-user/multi-worker scenarios?
- **Backward compatibility**: Will existing data (DB records, saved configs, cached values) still work?
- **API contracts**: If an endpoint's request/response shape changed, are all clients updated?

### 4. Risk Report

Output a structured report:

| Risk | Severity | File | Description | Mitigation |
|------|----------|------|-------------|------------|
| ... | High/Med/Low | ... | ... | ... |

Severity guide:
- **High**: Could cause data loss, crashes, or security vulnerabilities
- **Medium**: Could cause incorrect behavior or degraded performance
- **Low**: Code smell or minor inconsistency

If no risks found, state clearly: "Quality check passed — no risks identified."

### 5. Skill Update Check

If the current changes introduce new conventions, patterns, or workflow requirements:
- Ask: "This change introduces a new pattern. Should I update the Skill definitions to reflect it?"
- Wait for user confirmation before modifying any skill files
- If confirmed, update the relevant SKILL.md under `.claude/skills/`

### 5b. Skill Completeness Check (when Skill files are changed)

If any Skill files were modified or created in this changeset, verify:

1. **Each skill folder** has both `SKILL.md` and `README.md`
2. **Skills README** (`.claude/skills/README.md` or equivalent) includes the new/updated skill in:
   - Command overview table
   - Detailed description section
   - Directory structure tree
3. **Generic skills directory** (`skill_personal/` or equivalent) — evaluate if the change should sync:
   - Generic improvement (applies to any project) → sync and strip project-specific hardcodes
   - Project-specific fix → do not sync
4. **Generic skills README** updated if generic directory was changed
5. **Project configuration** (e.g., `CLAUDE.md`) skills list includes the skill
6. **Skill changes do NOT go into project git** — they are managed via `skill_personal/` (its own git repo) → `https://github.com/SWSekai/skill_personal.git` remote only

Report any missing items to the user before proceeding.

### 5c. Implementation Review (post-implementation flow verification)

After implementation is complete and before commit, perform a full end-to-end flow review on each modified code path:

1. **Re-read the modified code**: Do not rely on memory — read the final version of each file
2. **Walk through data flow step by step**: From trigger (button / API call) to final output, verify each step's input/output is correct
3. **Verify cross-layer consistency**:
   - Field names / types sent by frontend match what backend expects
   - DB columns queried match actual schema
   - External service calls (object storage / cache / database) use correct parameters
4. **Evaluate edge cases one by one**: List possible exception scenarios (null values, missing data, network failures), confirm code handles them or explicitly documents as known limitations
5. **Output confirmation table**:

| Check Item | Result | Notes |
|------------|:------:|-------|
| Data flow integrity | ✓/✗ | |
| Cross-layer type consistency | ✓/✗ | |
| Edge case handling | ✓/✗ | |
| Unmodified logic unaffected | ✓/✗ | |

If any ✗ items exist, **they must be fixed before entering commit flow**.

### 6. Modify Log Reminder

**CRITICAL**: After quality check passes and commit is made, the `modify-log` skill **must** be invoked to create the modification log. **Logs are stored locally only — they are NOT added to git version control.**

Arguments: $ARGUMENTS (optional — specific files to check, otherwise checks all staged/changed files)
