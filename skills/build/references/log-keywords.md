# Log Keyword Severity Guide

Log inspection keywords for container health diagnosis:

| Keyword | Severity | Description |
|---------|----------|-------------|
| `Error` / `ERROR` | HIGH | Startup error |
| `ImportError` / `ModuleNotFoundError` | HIGH | Python package issue |
| `Cannot find module` | HIGH | Node.js package issue |
| `ConnectionRefusedError` | MEDIUM | Dependency not ready (may auto-resolve) |
| `WARNING` | LOW | Usually non-blocking |
| `Application startup complete` | OK | uvicorn healthy |
| `Listening on` / `ready` | OK | Service healthy |
