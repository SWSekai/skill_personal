# Error Recovery Reference

## Automatic Error Recovery Procedures

### 6-1. ImportError / ModuleNotFoundError / Cannot find module

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

### 6-2. ConnectionRefusedError (dependency not ready)

```bash
# Wait for dependency to become healthy, then restart
docker compose up -d --wait <dependency>
docker compose restart <service>
```

### 6-3. Database migration error

Check for pending schema changes and report the required DDL commands to the user.

### 6-4. Port conflict / already in use

```bash
docker compose down <service>
docker compose up -d <service>
```

### 6-5. Cannot auto-repair

Report to user:
- Full error log excerpt
- Root cause analysis
- Suggested manual fix steps

---

## Error Recovery Cheat Sheet

| Symptom | Auto-repair | Fallback |
|---------|------------|----------|
| ImportError | `--no-cache` rebuild | Pin package versions |
| Container keeps restarting | Read logs → diagnose | `docker compose down <svc>` → fix → `up -d` |
| DB connection refused | Wait for DB healthy → restart | Check DB logs |
| Port already in use | `down` → `up -d` | Find PID → kill |
| Out of disk space | `docker system prune` | Clean images/volumes |
| Build timeout (proxy) | Retry build | Check proxy config |
