#!/bin/bash
# ============================================================
# sp-pack.sh — 專案打包：收集 AI 上下文 → 清除 skill 環境
# 用法：bash skill_personal/setup/sp-pack.sh
#
# 流程：
#   1. 收集 AI 上下文到 .local/ai-context/
#   2. 比對找出專案專屬 skill，保存到 project-skills/
#   3. 刪除 .claude/skills/、skill_personal/、CLAUDE.md
#   4. 產生 manifest.txt
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_DIR="$(cd "$SP_DIR/.." && pwd)"
SKILLS_DIR="$PROJECT_DIR/.claude/skills"
AI_CONTEXT="$PROJECT_DIR/.local/ai-context"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
GIT_HASH=$(cd "$PROJECT_DIR" && git rev-parse --short HEAD 2>/dev/null || echo "unknown")

# Memory 路徑（動態推導，適用於任何專案位置）
# Claude Code 將專案路徑編碼為：drive letter + -- + path with - replacing separators
# 例如 D:\cm_wip_setup → D--cm_wip_setup
MEMORY_DIR=""
CLAUDE_HOME="${HOME:-$USERPROFILE}/.claude/projects"

if [ -d "$CLAUDE_HOME" ]; then
    # 取得專案絕對路徑，轉換為 Claude Code 的編碼格式
    ABS_PROJECT=$(cd "$PROJECT_DIR" && pwd -W 2>/dev/null || pwd)
    # 嘗試在 projects/ 下尋找匹配的 memory 目錄
    # Claude Code 的路徑編碼會因 OS 而異，直接搜尋最可靠
    PROJECT_BASENAME=$(basename "$PROJECT_DIR")
    for candidate_dir in "$CLAUDE_HOME"/*/memory; do
        [ ! -d "$candidate_dir" ] && continue
        parent_name=$(basename "$(dirname "$candidate_dir")")
        # 匹配：編碼路徑名稱包含專案資料夾名稱
        if echo "$parent_name" | grep -qi "$PROJECT_BASENAME"; then
            MEMORY_DIR="$candidate_dir"
            break
        fi
    done
fi

echo ""
echo "========================================"
echo " sp-pack — 專案打包工具"
echo "========================================"
echo ""
echo "[INFO] 專案目錄  : $PROJECT_DIR"
echo "[INFO] 打包目標  : $AI_CONTEXT"
echo "[INFO] Git hash  : $GIT_HASH"
echo "[INFO] 時間      : $TIMESTAMP"
echo ""

# --- 安全確認 ---
echo "[WARN] 此操作將："
echo "       1. 收集 AI 上下文到 .local/ai-context/"
echo "       2. 刪除 .claude/skills/ 目錄"
echo "       3. 刪除 skill_personal/ 目錄"
echo "       4. 刪除 CLAUDE.md"
echo ""
read -p "確認執行？(y/N) " confirm
if [[ ! "$confirm" =~ ^[yY]$ ]]; then
    echo "[ABORT] 使用者取消"
    exit 0
fi

echo ""

# --- Step 1: 清理舊的打包 ---
if [ -d "$AI_CONTEXT" ]; then
    echo "[Step 0] 清理舊的 ai-context/..."
    rm -rf "$AI_CONTEXT"
fi

mkdir -p "$AI_CONTEXT"

# --- Step 2: 收集 CLAUDE.md ---
echo "[Step 1] 收集 CLAUDE.md..."
if [ -f "$PROJECT_DIR/CLAUDE.md" ]; then
    cp "$PROJECT_DIR/CLAUDE.md" "$AI_CONTEXT/CLAUDE.md"
    echo "  [OK] CLAUDE.md"
else
    echo "  [SKIP] CLAUDE.md 不存在"
fi

# --- Step 3: 收集 .local/ 子目錄 ---
echo "[Step 2] 收集 .local/ 工作紀錄..."
for subdir in docs modify_logs summary reports; do
    src="$PROJECT_DIR/.local/$subdir"
    if [ -d "$src" ] && [ "$(ls -A "$src" 2>/dev/null)" ]; then
        cp -r "$src" "$AI_CONTEXT/$subdir"
        count=$(find "$AI_CONTEXT/$subdir" -type f | wc -l)
        echo "  [OK] $subdir/ ($count 檔案)"
    else
        echo "  [SKIP] $subdir/ (空或不存在)"
    fi
done

# --- Step 4: 收集 Memory ---
echo "[Step 3] 收集 Memory..."
if [ -n "$MEMORY_DIR" ] && [ -d "$MEMORY_DIR" ]; then
    mkdir -p "$AI_CONTEXT/memory"
    cp "$MEMORY_DIR"/*.md "$AI_CONTEXT/memory/" 2>/dev/null || true
    count=$(find "$AI_CONTEXT/memory" -type f | wc -l)
    echo "  [OK] memory/ ($count 檔案) ← $MEMORY_DIR"
else
    echo "  [SKIP] Memory 目錄未找到"
fi

# --- Step 4b: 回寫 portable memory 到 skill_personal ---
echo "[Step 3b] 回寫 portable memory..."
MEM_PORTABLE="$SP_DIR/memory-portable"
if [ -n "$MEMORY_DIR" ] && [ -d "$MEMORY_DIR" ] && [ -d "$MEM_PORTABLE" ]; then
    WRITEBACK_COUNT=0
    for mem_file in "$MEMORY_DIR"/feedback_*.md "$MEMORY_DIR"/user_*.md; do
        [ ! -f "$mem_file" ] && continue
        fname=$(basename "$mem_file")
        if [ -f "$MEM_PORTABLE/$fname" ]; then
            # Update only if content differs
            if ! diff -q "$mem_file" "$MEM_PORTABLE/$fname" >/dev/null 2>&1; then
                cp "$mem_file" "$MEM_PORTABLE/$fname"
                echo "  [UPDATE] $fname"
                WRITEBACK_COUNT=$((WRITEBACK_COUNT + 1))
            fi
        else
            cp "$mem_file" "$MEM_PORTABLE/$fname"
            echo "  [ADD] $fname"
            WRITEBACK_COUNT=$((WRITEBACK_COUNT + 1))
        fi
    done
    if [ "$WRITEBACK_COUNT" -eq 0 ]; then
        echo "  [INFO] portable memory 已是最新"
    else
        echo "  [OK] 回寫 $WRITEBACK_COUNT 個 memory 到 skill_personal/memory-portable/"
        # Auto commit within skill_personal
        cd "$SP_DIR"
        git add memory-portable/ 2>/dev/null
        git commit -m "sync: 回寫 portable memory from $(basename "$PROJECT_DIR")

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>" 2>/dev/null || true
        echo "  [INFO] 已 commit 到 skill_personal (記得 push)"
    fi
else
    echo "  [SKIP] Memory 或 memory-portable/ 不存在"
fi

# --- Step 5: 收集全部 skills 快照 ---
echo "[Step 4] 收集 skills 快照..."
if [ -d "$SKILLS_DIR" ]; then
    mkdir -p "$AI_CONTEXT/skills"
    for skill_dir in "$SKILLS_DIR"/*/; do
        [ ! -d "$skill_dir" ] && continue
        skill_name=$(basename "$skill_dir")
        mkdir -p "$AI_CONTEXT/skills/$skill_name"
        cp "$skill_dir"/*.md "$AI_CONTEXT/skills/$skill_name/" 2>/dev/null || true
    done
    skill_count=$(find "$AI_CONTEXT/skills" -mindepth 1 -maxdepth 1 -type d | wc -l)
    echo "  [OK] skills/ ($skill_count 個 skill)"
fi

# --- Step 6: 比對找出專案專屬 skill ---
echo "[Step 5] 偵測專案專屬 skill..."
PROJECT_SKILL_COUNT=0

if [ -d "$SKILLS_DIR" ] && [ -d "$SP_DIR" ]; then
    mkdir -p "$AI_CONTEXT/project-skills"
    for skill_dir in "$SKILLS_DIR"/*/; do
        [ ! -d "$skill_dir" ] && continue
        skill_name=$(basename "$skill_dir")

        # 如果 skill_personal/ 沒有同名目錄 → 專案專屬
        if [ ! -d "$SP_DIR/$skill_name" ]; then
            cp -r "$skill_dir" "$AI_CONTEXT/project-skills/$skill_name"
            echo "  [SAVE] $skill_name (專案專屬)"
            PROJECT_SKILL_COUNT=$((PROJECT_SKILL_COUNT + 1))
        fi
    done

    if [ "$PROJECT_SKILL_COUNT" -eq 0 ]; then
        rmdir "$AI_CONTEXT/project-skills" 2>/dev/null || true
        echo "  [INFO] 無專案專屬 skill"
    fi
else
    echo "  [SKIP] 無法比對（目錄不存在）"
fi

# --- Step 7: 收集通用指南文件 ---
echo "[Step 6] 收集通用指南文件..."
mkdir -p "$AI_CONTEXT/guides"
GUIDE_COUNT=0

# 掃描已知位置的指南文件
GUIDE_SEARCH_DIRS=(
    "$PROJECT_DIR/.local/docs"
    "$PROJECT_DIR/docs"
    "$PROJECT_DIR"
)
GUIDE_PATTERNS=("*guide*" "*指南*")

for search_dir in "${GUIDE_SEARCH_DIRS[@]}"; do
    [ ! -d "$search_dir" ] && continue
    for pattern in "${GUIDE_PATTERNS[@]}"; do
        while IFS= read -r -d '' guide_file; do
            # 跳過 node_modules, dist, .local/ai-context 自身
            case "$guide_file" in
                */node_modules/*|*/dist/*|*/.local/ai-context/*) continue ;;
            esac
            # 計算相對路徑作為子目錄保留來源資訊
            rel_path="${guide_file#$PROJECT_DIR/}"
            # 用 --- 取代路徑分隔符作為檔名前綴，避免衝突
            flat_name=$(echo "$rel_path" | sed 's|/|---|g')
            cp "$guide_file" "$AI_CONTEXT/guides/$flat_name"
            echo "  [OK] $rel_path"
            GUIDE_COUNT=$((GUIDE_COUNT + 1))
        done < <(find "$search_dir" -maxdepth 3 -type f -iname "$pattern" -print0 2>/dev/null)
    done
done

if [ "$GUIDE_COUNT" -eq 0 ]; then
    rmdir "$AI_CONTEXT/guides" 2>/dev/null || true
    echo "  [INFO] 未找到指南文件"
else
    echo "  [OK] 共收集 $GUIDE_COUNT 份指南"
fi

# --- Step 8: 收集 .claude/settings.local.json ---
echo "[Step 7] 收集 Claude 設定..."
if [ -f "$PROJECT_DIR/.claude/settings.local.json" ]; then
    cp "$PROJECT_DIR/.claude/settings.local.json" "$AI_CONTEXT/settings.local.json"
    echo "  [OK] settings.local.json"
else
    echo "  [SKIP] settings.local.json 不存在"
fi

# --- Step 9: 產生 manifest.txt ---
echo "[Step 8] 產生 manifest.txt..."
cat > "$AI_CONTEXT/manifest.txt" << MANIFEST
================================================================
 AI Context Pack — 打包資訊
================================================================

打包時間    : $TIMESTAMP
Git commit  : $GIT_HASH
專案目錄    : $PROJECT_DIR
打包工具    : sp-pack.sh

----------------------------------------------------------------
 收集內容
----------------------------------------------------------------
$(find "$AI_CONTEXT" -type f | sort | sed "s|$AI_CONTEXT/||")

----------------------------------------------------------------
 專案專屬 Skill（已保存至 project-skills/）
----------------------------------------------------------------
$(if [ -d "$AI_CONTEXT/project-skills" ]; then
    ls "$AI_CONTEXT/project-skills" 2>/dev/null || echo "(無)"
else
    echo "(無)"
fi)

----------------------------------------------------------------
 還原指引
----------------------------------------------------------------
1. 執行 skill_personal/setup/sp-init.bat 重建 skill 環境
2. 執行 bash skill_personal/setup/sp-sync.sh 同步最新 skill
3. 將 project-skills/ 內容複製回 .claude/skills/
4. 將 CLAUDE.md 複製回專案根目錄
5. Memory 檔案複製回 ~/.claude/projects/.../memory/
================================================================
MANIFEST
echo "  [OK] manifest.txt"

# --- Step 10: 刪除 skill 環境 ---
echo ""
echo "[Step 9] 清除 skill 環境..."

# 刪除 .claude/skills/
if [ -d "$SKILLS_DIR" ]; then
    rm -rf "$SKILLS_DIR"
    echo "  [DEL] .claude/skills/"
fi

# 刪除 skill_personal/（先確認不在其中工作）
cd "$PROJECT_DIR"
if [ -d "$SP_DIR" ]; then
    rm -rf "$SP_DIR"
    echo "  [DEL] skill_personal/"
fi

# 刪除 CLAUDE.md
if [ -f "$PROJECT_DIR/CLAUDE.md" ]; then
    rm "$PROJECT_DIR/CLAUDE.md"
    echo "  [DEL] CLAUDE.md"
fi

# --- Summary ---
echo ""
echo "========================================"
echo " 打包完成"
echo "========================================"
echo ""
echo "  AI 上下文已保存至: .local/ai-context/"
echo "  專案專屬 skill   : $PROJECT_SKILL_COUNT 個"
echo ""
echo "  已清除："
echo "    - .claude/skills/"
echo "    - skill_personal/"
echo "    - CLAUDE.md"
echo ""
echo "  還原方式請參閱: .local/ai-context/manifest.txt"
echo ""
echo "[DONE]"
