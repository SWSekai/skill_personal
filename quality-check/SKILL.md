---
name: quality-check
description: "Pre-commit code quality audit — redundancy, impact analysis, architecture conformance, and risk assessment. IMPORTANT: After quality check passes, ensure modify-log skill is invoked to create the mandatory modification log before committing."
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

### 6. Modify Log Reminder

**CRITICAL**: After quality check passes, the `modify-log` skill **must** be invoked to create the mandatory modification log before any commit proceeds. This applies to ALL commit flows — `/commit-push`, Claude Code self-planned commits, or manual commits.

Arguments: $ARGUMENTS (optional — specific files to check, otherwise checks all staged/changed files)
