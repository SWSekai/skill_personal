---
name: restart-eval
description: "Evaluate which services or containers need restart or rebuild after code changes. Auto-triggered after commits that modify service code."
model: haiku
effort: low
argument-hint: "[service...]"
allowed-tools: Bash(git *), Bash(docker *), Read, Glob, Grep
---

## Service Restart Evaluation

Determine which services need action after code changes.

### Step 1: Identify changed files

If $ARGUMENTS contains a commit range, use it. Otherwise compare against last commit:

```bash
git diff --name-only HEAD~1
```

### Step 2: Discover service topology

Read the project's orchestration config to understand the architecture:

```bash
# Try common locations
cat docker-compose.yml 2>/dev/null || cat docker-compose.yaml 2>/dev/null || cat compose.yml 2>/dev/null
```

For each service, determine:
- **Volume-mounted paths** (code changes reflected without rebuild)
- **Baked-in paths** (code only in image, needs rebuild)
- **Auto-reload capability** (uvicorn --reload, nodemon, webpack HMR, etc.)
- **Static file serving** (nginx, Apache — usually just browser refresh)

### Step 3: Classify each changed file

| Mount type | Auto-reload? | Action needed |
|---|---|---|
| Volume-mounted | Yes (e.g., `--reload`) | No action — auto-applied |
| Volume-mounted | No | `docker compose restart <service>` |
| Baked into image | N/A | `docker compose build <service> && docker compose up -d <service>` |
| Static files (web server) | N/A | Browser refresh only |
| DB init scripts | N/A | Manual migration (ALTER TABLE, etc.) |
| Dockerfile | N/A | `docker compose build <service> && docker compose up -d <service>` |
| Compose file | N/A | `docker compose up -d` (auto-detects changes) |
| Config/env files | N/A | `docker compose restart <service>` or recreate |
| Docs / non-deployed files | N/A | No action |

### Step 4: Impact assessment

For each service that needs restart, note side effects:
- **Web servers**: Brief downtime for connected clients
- **Stream processors / real-time services**: Active connections will drop
- **Background workers**: Running jobs may be interrupted — check status first
- **Databases**: All active sessions disconnected — avoid unless necessary
- **API gateways**: Brief request failures during restart

### Step 5: Output

1. **Table**: changed file → service → action
2. **Commands**: grouped and deduplicated, in suggested execution order
3. **Warnings**: side effects for each restart
4. **DB migrations**: if init scripts changed on an existing database

### Non-containerized projects

If the project doesn't use containers:
- Check for process managers (PM2, systemd, supervisor)
- Check for hot-reload tools (nodemon, watchdog, air)
- Provide the appropriate restart commands for the project's stack

Arguments: $ARGUMENTS (optional commit range like `abc123..def456`)
