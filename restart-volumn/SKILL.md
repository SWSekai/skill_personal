---
name: restart-volumn
description: "Execute container restart/rebuild with pre-flight checks, health verification, and automatic error recovery. Handles the full lifecycle: check active tasks → restart/rebuild → verify health → check logs for errors → auto-recover if possible."
allowed-tools: Bash(docker *), Bash(sleep *), Read, Grep
---

## Container Restart & Recovery Protocol

### Usage

```
/restart-volumn [service...]
```

- No arguments: auto-detect which containers need restart from latest commit
- Specify services: `/restart-volumn api-gateway worker`
- Restart all: `/restart-volumn all`

---

### Step 1: Determine restart targets

**If no arguments**, auto-detect from recent changes:
```bash
git diff --name-only HEAD~1
```
Map changed files to services using `docker-compose.yml` mount/build config.

**If arguments provided**, use specified service names directly.

List the containers to be restarted and confirm with the user.

---

### Step 2: Pre-flight checks

Before restarting, complete these checks in order:

#### 2-1. Current container status

```bash
docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Service}}"
```

Confirm target containers are currently Running / Restarting / Exited.

#### 2-2. Background worker check (if restarting any worker/queue service)

Detect Celery, Sidekiq, Bull, or similar background job processors:

```bash
# Celery example
docker compose exec <worker> sh -c 'celery -A <app> inspect active --timeout=5 2>/dev/null'
```

- **Active tasks found** → warn user, list task IDs, ask whether to wait or force
- **No active tasks** → safe to proceed

#### 2-3. Real-time service check (if restarting stream/inference services)

If the service handles persistent connections (WebSocket, RTSP, SSE):
- Warn user that active connections will drop
- Suggest restarting during low-traffic periods

#### 2-4. Mount type determination

Read `docker-compose.yml` to classify each service:

| Mount type | Action |
|---|---|
| Volume-mounted code (`:ro` or `:rw`) | `docker compose restart <service>` |
| Code baked into image | `docker compose build <service> && docker compose up -d <service>` |
| Shared image (multiple services) | Build once, recreate all |

---

### Step 3: Execute restart

#### Volume-mounted services (restart is sufficient)

```bash
docker compose restart <service>
```

#### Image-baked services (need build + recreate)

```bash
# Build shared images together
docker compose build <service1> <service2>
docker compose up -d <service1> <service2>
```

---

### Step 4: Health check (wait for startup)

Wait 8 seconds, then verify:

```bash
sleep 8
docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Service}}" | grep -E "<services>"
```

**Expected**: `Up X seconds` or `Up X seconds (healthy)`

**Abnormal states**:
- `Restarting` → proceed to Step 5 (error diagnosis)
- `Exited` → proceed to Step 5

---

### Step 5: Log inspection & error diagnosis

```bash
docker compose logs --tail=30 <service>
```

Scan logs for these keywords:

| Keyword | Severity | Description |
|---------|----------|-------------|
| `Error` / `ERROR` | HIGH | Startup error |
| `ImportError` / `ModuleNotFoundError` | HIGH | Python package issue |
| `Cannot find module` | HIGH | Node.js package issue |
| `ConnectionRefusedError` | MEDIUM | Dependency not ready (may auto-resolve) |
| `WARNING` | LOW | Usually non-blocking |
| `Application startup complete` | OK | uvicorn healthy |
| `Listening on` / `ready` | OK | Service healthy |

---

### Step 6: Automatic error recovery

Based on Step 5 diagnosis, attempt auto-repair:

#### 6-1. ImportError / ModuleNotFoundError / Cannot find module

**Likely cause**: package installation corruption or build cache issue

```bash
docker compose build --no-cache <service>
docker compose up -d <service>
```

If still failing:
1. Read Dockerfile and dependency files (requirements.txt, package.json)
2. Check for version conflicts
3. Attempt fix with pinned versions
4. Report specific error and suggested fix to user

#### 6-2. ConnectionRefusedError (dependency not ready)

```bash
# Wait for dependency to become healthy, then restart
docker compose up -d --wait <dependency>
docker compose restart <service>
```

#### 6-3. Database migration error

Check for pending schema changes and report the required DDL commands to the user.

#### 6-4. Port conflict / already in use

```bash
docker compose down <service>
docker compose up -d <service>
```

#### 6-5. Cannot auto-repair

Report to user:
- Full error log excerpt
- Root cause analysis
- Suggested manual fix steps

---

### Step 7: Final verification

#### 7-1. API reachability test

Attempt a basic health/docs endpoint call within the container:
```bash
docker compose exec <service> sh -c 'curl -s http://localhost:<port>/health || curl -s http://localhost:<port>/docs' 2>/dev/null
```

#### 7-2. Worker connectivity (if applicable)

```bash
docker compose exec <worker> sh -c 'celery -A <app> inspect ping --timeout=5 2>/dev/null'
```

#### 7-3. Output final report

```
Restart Report
━━━━━━━━━━━━━━
| Service          | Action   | Status | Duration |
|------------------|----------|--------|----------|
| api-gateway      | restart  | ✓ OK   | ~3s      |
| training-service | rebuild  | ✓ OK   | ~45s     |
| celery-worker    | rebuild  | ✓ OK   | ~45s     |

Auto-repairs: None
```

---

### Error Recovery Cheat Sheet

| Symptom | Auto-repair | Fallback |
|---------|------------|----------|
| ImportError | `--no-cache` rebuild | Pin package versions |
| Container keeps restarting | Read logs → diagnose | `docker compose down <svc>` → fix → `up -d` |
| DB connection refused | Wait for DB healthy → restart | Check DB logs |
| Port already in use | `down` → `up -d` | Find PID → kill |
| Out of disk space | `docker system prune` | Clean images/volumes |
| Build timeout (proxy) | Retry build | Check proxy config |

Arguments: $ARGUMENTS (optional service names, or "all")
