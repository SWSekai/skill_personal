#!/bin/bash
# ============================================================
# sp-sync.sh — Sekai_workflow 遠端同步 + 專案 Skills 更新
# 用法：在專案根目錄執行 bash Sekai_workflow/_bootstrap/sp-sync.sh
# ============================================================

set -euo pipefail

# Version gates (paired with file_manifest.json):
#   SCRIPT_VERSION         — bump when this script's logic changes
#   SCRIPT_SCHEMA_COMPAT   — the highest manifest.schema_version this script can parse
# If manifest.schema_version > SCRIPT_SCHEMA_COMPAT, this script aborts so the
# receiver cannot silently misinterpret newer-structure manifests.
SCRIPT_VERSION="1.1"
SCRIPT_SCHEMA_COMPAT=1

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_DIR="$(cd "$SP_DIR/.." && pwd)"
SKILLS_DIR="$PROJECT_DIR/.claude/skills"
HOOKS_DIR="$PROJECT_DIR/.claude/hooks"
USER_CLAUDE_DIR="$HOME/.claude"
MANIFEST_FILE="$SP_DIR/file_manifest.json"

echo ""
echo "========================================"
echo " Sekai_workflow Sync Tool"
echo "========================================"
echo ""
echo "[INFO] Sekai_workflow : $SP_DIR"
echo "[INFO] Project skills : $SKILLS_DIR"
echo "[INFO] Project hooks  : $HOOKS_DIR"
echo "[INFO] User .claude   : $USER_CLAUDE_DIR"
echo "[INFO] Script version : $SCRIPT_VERSION (schema compat up to $SCRIPT_SCHEMA_COMPAT)"
echo ""

# Helper: parse manifest schema_version via node. Empty string if missing/unreadable.
read_manifest_schema() {
    local mf="$1"
    [ ! -f "$mf" ] && return 0
    command -v node >/dev/null 2>&1 || return 0
    MF_PATH="$mf" node -e '
        try {
            const m = JSON.parse(require("fs").readFileSync(process.env.MF_PATH, "utf8"));
            const v = (m.schema_version == null) ? "" : String(m.schema_version);
            process.stdout.write(v);
        } catch(e) { /* swallow */ }
    ' 2>/dev/null
}

# --- Step 0: Pre-fetch manifest compat check ---
echo "[Step 0] Checking manifest schema compatibility..."
LOCAL_SCHEMA=$(read_manifest_schema "$MANIFEST_FILE")
if [ -z "$LOCAL_SCHEMA" ]; then
    echo "  [SKIP] No local manifest / node unavailable — deferring check to Step 1c."
else
    if [ "$LOCAL_SCHEMA" -gt "$SCRIPT_SCHEMA_COMPAT" ] 2>/dev/null; then
        echo "  [ABORT] manifest.schema_version ($LOCAL_SCHEMA) > SCRIPT_SCHEMA_COMPAT ($SCRIPT_SCHEMA_COMPAT)"
        echo "          This sp-sync.sh ($SCRIPT_VERSION) is too old to parse the current manifest."
        echo "          Update sp-sync.sh from the latest Sekai_workflow and rerun."
        exit 2
    fi
    echo "  [OK] Local manifest schema_version=$LOCAL_SCHEMA (within compat)."
fi
echo ""

# --- Step 1: Git fetch + pull ---
echo "[Step 1] Fetching remote updates..."
cd "$SP_DIR"

if ! git fetch origin 2>/dev/null; then
    echo "[ERROR] git fetch failed. Check network or remote config."
    exit 1
fi

BEHIND=$(git rev-list HEAD..origin/main --count 2>/dev/null || echo 0)
AHEAD=$(git rev-list origin/main..HEAD --count 2>/dev/null || echo 0)

if [ "$BEHIND" = "0" ] && [ "$AHEAD" = "0" ]; then
    echo "[INFO] Already up to date with remote."
    echo ""
elif [ "$BEHIND" != "0" ]; then
    echo "[INFO] Remote: $BEHIND commit(s) behind, $AHEAD commit(s) ahead"
    echo "[Step 1a] Pulling $BEHIND new commit(s)..."
    if ! git pull --rebase origin main; then
        echo "[ERROR] git pull failed. Resolve conflicts manually."
        exit 1
    fi
    echo "[OK] Pull successful."
    echo ""
fi

# --- Step 1c: Post-pull version drift check ---
echo "[Step 1c] Post-pull version drift check..."
NEW_SCHEMA=$(read_manifest_schema "$MANIFEST_FILE")
DRIFT_ABORT=0

if [ -n "$NEW_SCHEMA" ] && [ "$NEW_SCHEMA" -gt "$SCRIPT_SCHEMA_COMPAT" ] 2>/dev/null; then
    echo "  [ABORT] Pulled manifest.schema_version=$NEW_SCHEMA > current script compat=$SCRIPT_SCHEMA_COMPAT."
    echo "          A new sp-sync.sh has arrived on disk — rerun this same command to use it:"
    echo "            bash $0"
    DRIFT_ABORT=1
fi

# Check disk-vs-running script version (only if different, hint rerun)
if [ -f "$0" ] && command -v grep >/dev/null 2>&1; then
    DISK_VERSION=$(grep -m1 '^SCRIPT_VERSION=' "$0" | cut -d'"' -f2 2>/dev/null || echo "")
    if [ -n "$DISK_VERSION" ] && [ "$DISK_VERSION" != "$SCRIPT_VERSION" ]; then
        echo "  [WARN] On-disk sp-sync.sh is version $DISK_VERSION; running process is $SCRIPT_VERSION."
        echo "         Rerun to pick up new sync logic:  bash $0"
        DRIFT_ABORT=1
    fi
fi

if [ "$DRIFT_ABORT" = "1" ]; then
    exit 3
fi
echo "  [OK] Script $SCRIPT_VERSION and manifest schema $NEW_SCHEMA are in sync."
echo ""

# --- Step 2: Compare and sync skills ---
echo "[Step 2] Comparing skills..."
echo ""

UPDATED=0
ADDED=0
UNCHANGED=0

mkdir -p "$SKILLS_DIR"

# 排除非 skill 目錄
SKIP_DIRS="_bootstrap docs .git hooks references handbook"

for skill_dir in "$SP_DIR"/*/; do
    [ ! -d "$skill_dir" ] && continue

    SKILL_NAME=$(basename "$skill_dir")

    # 跳過非 skill 目錄
    skip=false
    for s in $SKIP_DIRS; do
        [ "$SKILL_NAME" = "$s" ] && skip=true && break
    done
    $skip && continue

    # 必須有 SKILL.md 才算 skill
    [ ! -f "$skill_dir/SKILL.md" ] && continue

    TARGET="$SKILLS_DIR/$SKILL_NAME"

    if [ ! -d "$TARGET" ]; then
        # 新 skill
        echo "  [ADD]    $SKILL_NAME"
        mkdir -p "$TARGET"
        cp "$skill_dir/SKILL.md" "$TARGET/SKILL.md"
        [ -f "$skill_dir/README.md" ] && cp "$skill_dir/README.md" "$TARGET/README.md"
        ADDED=$((ADDED + 1))
    else
        # 已存在 — 比對內容
        NEED_UPDATE=false

        if ! diff -q "$skill_dir/SKILL.md" "$TARGET/SKILL.md" >/dev/null 2>&1; then
            NEED_UPDATE=true
        fi

        if [ -f "$skill_dir/README.md" ] && [ -f "$TARGET/README.md" ]; then
            if ! diff -q "$skill_dir/README.md" "$TARGET/README.md" >/dev/null 2>&1; then
                NEED_UPDATE=true
            fi
        fi

        if $NEED_UPDATE; then
            echo "  [UPDATE] $SKILL_NAME"
            cp "$skill_dir/SKILL.md" "$TARGET/SKILL.md"
            [ -f "$skill_dir/README.md" ] && cp "$skill_dir/README.md" "$TARGET/README.md"
            UPDATED=$((UPDATED + 1))
        else
            echo "  [OK]     $SKILL_NAME"
            UNCHANGED=$((UNCHANGED + 1))
        fi
    fi
done

# --- Step 2b: Manifest reconciliation (detect stale/renamed folders) ---
echo ""
echo "[Step 2b] Checking file_manifest.json for stale folders..."
echo ""

MANIFEST="$SP_DIR/file_manifest.json"
STALE_COUNT=0

if [ ! -f "$MANIFEST" ]; then
    echo "  [SKIP] No manifest at $MANIFEST — skipping reconciliation."
elif ! command -v node >/dev/null 2>&1; then
    echo "  [SKIP] node not in PATH — cannot parse manifest."
else
    STALE_LIST=$(
        SP_DIR="$SP_DIR" SKILLS_DIR="$SKILLS_DIR" MANIFEST="$MANIFEST" \
        node -e '
            const fs = require("fs");
            const m = JSON.parse(fs.readFileSync(process.env.MANIFEST, "utf8"));
            const aliases = m.skill_aliases || {};
            const skillsDir = process.env.SKILLS_DIR;
            const spDir = process.env.SP_DIR;
            const found = [];
            for (const oldName of Object.keys(aliases)) {
                const a = `${skillsDir}/${oldName}`;
                const b = `${spDir}/${oldName}`;
                if (fs.existsSync(a)) found.push(a);
                if (fs.existsSync(b)) found.push(b);
            }
            process.stdout.write(found.join("\n"));
        '
    )

    if [ -n "$STALE_LIST" ]; then
        echo "  [STALE] Folders renamed/retired per manifest (skill_aliases):"
        echo "$STALE_LIST" | sed 's/^/    - /'
        echo ""
        if [ -t 0 ]; then
            read -p "  Remove these stale folders? (y/N): " CONFIRM
        else
            CONFIRM="n"
            echo "  [INFO] Non-interactive mode — skipping removal."
        fi
        if [ "$CONFIRM" = "y" ] || [ "$CONFIRM" = "Y" ]; then
            while IFS= read -r dir; do
                [ -z "$dir" ] && continue
                if [ -d "$dir" ]; then
                    rm -rf "$dir"
                    echo "  [REMOVED] $dir"
                    STALE_COUNT=$((STALE_COUNT + 1))
                fi
            done <<< "$STALE_LIST"
        else
            echo "  [KEEP] Stale folders preserved. Remove manually or rerun sync."
        fi
    else
        echo "  [OK] No stale folders detected."
    fi
fi

# --- Step 3: Sync hooks ---
echo ""
echo "[Step 3] Comparing hooks..."
echo ""

HOOK_ADDED=0
HOOK_UPDATED=0
HOOK_UNCHANGED=0

if [ -d "$SP_DIR/hooks" ]; then
    mkdir -p "$HOOKS_DIR"

    for hook_file in "$SP_DIR/hooks"/*.cjs "$SP_DIR/hooks"/*.sh; do
        [ ! -f "$hook_file" ] && continue

        HOOK_NAME=$(basename "$hook_file")
        TARGET="$HOOKS_DIR/$HOOK_NAME"

        if [ ! -f "$TARGET" ]; then
            echo "  [ADD]    $HOOK_NAME"
            cp "$hook_file" "$TARGET"
            HOOK_ADDED=$((HOOK_ADDED + 1))
        elif ! diff -q "$hook_file" "$TARGET" >/dev/null 2>&1; then
            echo "  [UPDATE] $HOOK_NAME"
            cp "$hook_file" "$TARGET"
            HOOK_UPDATED=$((HOOK_UPDATED + 1))
        else
            echo "  [OK]     $HOOK_NAME"
            HOOK_UNCHANGED=$((HOOK_UNCHANGED + 1))
        fi
    done
else
    echo "  [SKIP] No hooks directory in $SP_DIR"
fi

# --- Step 4: Sync statusline (user-level ~/.claude/) ---
echo ""
echo "[Step 4] Syncing statusline..."
echo ""

STATUSLINE_TEMPLATE="$SP_DIR/_bootstrap/templates/statusline.cjs"
STATUSLINE_TARGET="$USER_CLAUDE_DIR/statusline.cjs"
SETTINGS_FILE="$USER_CLAUDE_DIR/settings.json"
STATUSLINE_FILE_STATUS="[SKIP]"
SETTINGS_PATCH_STATUS="[SKIP]"

if [ ! -f "$STATUSLINE_TEMPLATE" ]; then
    echo "  [SKIP] No statusline template at $STATUSLINE_TEMPLATE"
else
    mkdir -p "$USER_CLAUDE_DIR"

    if [ ! -f "$STATUSLINE_TARGET" ]; then
        cp "$STATUSLINE_TEMPLATE" "$STATUSLINE_TARGET"
        STATUSLINE_FILE_STATUS="[ADD]"
    elif ! diff -q "$STATUSLINE_TEMPLATE" "$STATUSLINE_TARGET" >/dev/null 2>&1; then
        cp "$STATUSLINE_TEMPLATE" "$STATUSLINE_TARGET"
        STATUSLINE_FILE_STATUS="[UPDATE]"
    else
        STATUSLINE_FILE_STATUS="[OK]"
    fi
    echo "  $STATUSLINE_FILE_STATUS statusline.cjs → $STATUSLINE_TARGET"

    # Patch settings.json statusLine.command (idempotent — only rewrites when needed)
    if [ ! -f "$SETTINGS_FILE" ]; then
        echo "  [SKIP] $SETTINGS_FILE not found; leaving statusLine binding untouched"
    elif ! command -v node >/dev/null 2>&1; then
        echo "  [SKIP] node not in PATH; cannot patch settings.json"
    else
        SETTINGS_PATCH_STATUS=$(
            SP_STATUSLINE_TARGET="$STATUSLINE_TARGET" \
            SP_SETTINGS_FILE="$SETTINGS_FILE" \
            node -e '
                const fs = require("fs");
                const path = process.env.SP_SETTINGS_FILE;
                const target = "node " + process.env.SP_STATUSLINE_TARGET;
                const raw = fs.readFileSync(path, "utf8");
                const obj = JSON.parse(raw);
                const current = obj.statusLine && obj.statusLine.command;
                if (current === target) { process.stdout.write("[OK]"); process.exit(0); }
                const hadBlock = !!obj.statusLine;
                obj.statusLine = { type: "command", command: target };
                fs.writeFileSync(path, JSON.stringify(obj, null, 2) + "\n");
                process.stdout.write(hadBlock ? "[UPDATE]" : "[ADD]");
            '
        )
        echo "  $SETTINGS_PATCH_STATUS settings.json statusLine.command"
    fi
fi

# --- Step 5: Summary ---
echo ""
echo "========================================"
echo " Sync Summary"
echo "========================================"
echo "  Version    — Script: $SCRIPT_VERSION / Schema: ${NEW_SCHEMA:-n/a} (compat ≤ $SCRIPT_SCHEMA_COMPAT)"
echo "  Skills     — Added: $ADDED / Updated: $UPDATED / No change: $UNCHANGED"
echo "  Manifest   — Stale removed: $STALE_COUNT"
echo "  Hooks      — Added: $HOOK_ADDED / Updated: $HOOK_UPDATED / No change: $HOOK_UNCHANGED"
echo "  Statusline — File: $STATUSLINE_FILE_STATUS / Settings: $SETTINGS_PATCH_STATUS"
echo "========================================"
echo ""

if [ "$ADDED" -gt 0 ]; then
    echo "[REMINDER] New skills added. Update CLAUDE.md \"Available Skills\" section."
fi

if [ "$HOOK_ADDED" -gt 0 ]; then
    echo "[REMINDER] New hooks added. Verify .claude/settings.local.json has matching"
    echo "           matcher/command bindings (reference: _bootstrap/templates/hooks.json)."
fi

if [ "$STATUSLINE_FILE_STATUS" = "[UPDATE]" ] || [ "$SETTINGS_PATCH_STATUS" = "[UPDATE]" ] \
   || [ "$STATUSLINE_FILE_STATUS" = "[ADD]" ] || [ "$SETTINGS_PATCH_STATUS" = "[ADD]" ]; then
    echo "[REMINDER] Statusline updated. Restart Claude Code to see the new status line."
fi

if [ "$AHEAD" != "0" ]; then
    echo "[INFO] Local has $AHEAD unpushed commit(s)."
    echo "       Run: cd Sekai_workflow && git push origin main"
fi

echo "[DONE]"
