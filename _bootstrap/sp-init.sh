#!/bin/bash

# ============================================================
#  sekai-workflow project init script (Unix/Linux)
#  Usage: ./sp-init.sh [project-path]
# ============================================================

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( dirname "$SCRIPT_DIR" )"

PROJECT_DIR="${1:-$(pwd)}"
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"

echo ""
echo "===================================================="
echo "  Sekai-workflow Project Init (Unix)"
echo "===================================================="
echo ""
echo "  Repo:    $REPO_ROOT"
echo "  Target:  $PROJECT_DIR"
echo ""

# 1. Sync Agents
echo "[1/9] Synchronizing Agent Rules & Skills..."
node "$REPO_ROOT/scripts/sync-agents.js"

# 2. gitignore
echo "[5/9] Updating .gitignore..."
GITIGNORE="$PROJECT_DIR/.gitignore"
touch "$GITIGNORE"
for entry in CLAUDE.md GEMINI.md .cursorrules .claude/ .sekai-workflow/ .local/; do
    if ! grep -qxF "$entry" "$GITIGNORE"; then
        echo "$entry" >> "$GITIGNORE"
        echo "      + $entry"
    fi
done

# 3. pre-commit hook
echo "[6/9] Installing pre-commit hook..."
if [ -d "$PROJECT_DIR/.git" ]; then
    mkdir -p "$PROJECT_DIR/.git/hooks"
    cp "$SCRIPT_DIR/hooks/pre-commit" "$PROJECT_DIR/.git/hooks/pre-commit"
    chmod +x "$PROJECT_DIR/.git/hooks/pre-commit"
    echo "      Installed pre-commit hook"
fi

echo ""
echo "Init complete! Run 'node .sekai-workflow/scripts/sync-agents.js' anytime to refresh links."
