#!/bin/bash
# ============================================================
# sp-sync.sh — Sekai_workflow 遠端同步 + 專案 Skills 更新
# 用法：在專案根目錄執行 bash Sekai_workflow/_bootstrap/sp-sync.sh
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_DIR="$(cd "$SP_DIR/.." && pwd)"
SKILLS_DIR="$PROJECT_DIR/.claude/skills"
HOOKS_DIR="$PROJECT_DIR/.claude/hooks"
USER_CLAUDE_DIR="$HOME/.claude"

echo ""
echo "========================================"
echo " Sekai_workflow Sync Tool"
echo "========================================"
echo ""
echo "[INFO] Sekai_workflow : $SP_DIR"
echo "[INFO] Project skills : $SKILLS_DIR"
echo "[INFO] Project hooks  : $HOOKS_DIR"
echo "[INFO] User .claude   : $USER_CLAUDE_DIR"
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
