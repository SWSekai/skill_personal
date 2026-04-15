#!/bin/bash
# ============================================================
# sp-sync.sh — Sekai_workflow 遠端同步 + 專案 Skills 更新
# 用法：在專案根目錄執行 bash Sekai_workflow/setup/sp-sync.sh
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_DIR="$(cd "$SP_DIR/.." && pwd)"
SKILLS_DIR="$PROJECT_DIR/.claude/skills"

echo ""
echo "========================================"
echo " Sekai_workflow Sync Tool"
echo "========================================"
echo ""
echo "[INFO] Sekai_workflow : $SP_DIR"
echo "[INFO] Project skills : $SKILLS_DIR"
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
SKIP_DIRS="setup docs .git"

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

# --- Step 3: Summary ---
echo ""
echo "========================================"
echo " Sync Summary"
echo "========================================"
echo "  Added    : $ADDED"
echo "  Updated  : $UPDATED"
echo "  No change: $UNCHANGED"
echo "========================================"
echo ""

if [ "$ADDED" -gt 0 ]; then
    echo "[REMINDER] New skills added. Update CLAUDE.md \"Available Skills\" section."
fi

if [ "$AHEAD" != "0" ]; then
    echo "[INFO] Local has $AHEAD unpushed commit(s)."
    echo "       Run: cd Sekai_workflow && git push origin main"
fi

echo "[DONE]"
