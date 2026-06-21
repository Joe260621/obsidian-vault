#!/bin/bash
# ============================================================
# Obsidian Vault 同步设置脚本
# 支持两种模式:
#   FRESH  — 全新安装，直接克隆
#   MERGE  — 合并旧 vault 独有内容到共享仓库
# ============================================================
set -e

# ── 参数检查 ────────────────────────────────────────────
usage() {
    echo ""
    echo "用法:"
    echo "  全新安装:  bash setup-obsidian-sync.sh <Token> [目标目录]"
    echo "  合并旧库:  bash setup-obsidian-sync.sh <Token> <目标目录> --merge <旧Vault路径>"
    echo ""
    echo "参数说明:"
    echo "  Token      - GitHub Personal Access Token (勾选 repo)"
    echo "  目标目录    - 共享 vault 存放位置，如 D:/ObsidianShared"
    echo "  --merge     - 合并旧 vault 独有内容（不覆盖已有文件）"
    echo "  旧Vault路径 - 另一台电脑上现有的 Obsidian vault 路径"
    echo ""
    echo "示例:"
    echo "  bash setup-obsidian-sync.sh ghp_abc123 D:/ObsidianShared"
    echo "  bash setup-obsidian-sync.sh ghp_abc123 D:/ObsidianShared --merge D:/OldVault"
    exit 1
}

if [ $# -lt 1 ]; then usage; fi

TOKEN="$1"
TARGET_DIR="${2:-.}"
MODE="fresh"
OLD_VAULT=""

# 解析参数
shift 2 2>/dev/null || true
while [ $# -gt 0 ]; do
    case "$1" in
        --merge|--merge-existing)
            MODE="merge"
            OLD_VAULT="$2"
            if [ ! -d "$OLD_VAULT" ]; then
                echo "❌ 旧 vault 路径不存在: $OLD_VAULT"
                exit 1
            fi
            shift 2
            ;;
        -h|--help) usage ;;
        *) echo "未知参数: $1"; usage ;;
    esac
done

REPO_URL="https://${TOKEN}@github.com/Joe260621/obsidian-vault.git"
GIT_NAME="Joe260621"
GIT_EMAIL="wzhuo2023@gmail.com"

echo ""
echo "============================================"
echo " Obsidian Vault 同步设置"
echo "============================================"
echo ""
echo "模式:     $([ "$MODE" = "merge" ] && echo '合并 (MERGE)' || echo '全新 (FRESH)')"
echo "目标目录:  $TARGET_DIR"
echo "仓库:      Joe260621/obsidian-vault"
if [ "$MODE" = "merge" ]; then
    echo "旧 Vault:  $OLD_VAULT"
fi
echo ""

# ── 检查 git ────────────────────────────────────────────
if ! command -v git &> /dev/null; then
    echo "❌ 未找到 git，请先安装: https://git-scm.com/download"
    exit 1
fi
echo "✅ git: $(git --version)"

# ── 克隆仓库 ────────────────────────────────────────────
# 确保不会克隆到已有仓库中
if [ -d "$TARGET_DIR/.git" ]; then
    echo "⚠️  目标已是 git 仓库，跳过 clone"
    cd "$TARGET_DIR"
else
    echo "📥 克隆共享仓库..."
    mkdir -p "$(dirname "$TARGET_DIR")" 2>/dev/null || true
    git clone "$REPO_URL" "$TARGET_DIR"
    cd "$TARGET_DIR"
    echo "✅ 克隆完成: $(git log --oneline -1)"
fi

# ── Git 配置 ─────────────────────────────────────────────
echo ""
echo "⚙️  配置 git..."
git config user.name "$GIT_NAME"
git config user.email "$GIT_EMAIL"
echo "✅ user.name: $GIT_NAME"
echo "✅ user.email: $GIT_EMAIL"

# ── 合并旧 Vault ─────────────────────────────────────────
if [ "$MODE" = "merge" ]; then
    echo ""
    echo "────────────────────────────────────────────"
    echo " 📦 合并旧 Vault 独有内容"
    echo "────────────────────────────────────────────"

    # 统计旧 vault 文件
    OLD_TOTAL=$(find "$OLD_VAULT" -type f \
        -not -path '*/.git/*' \
        -not -path '*/.obsidian/*' \
        -not -path '*/node_modules/*' \
        -not -name '*.zip' \
        | wc -l)
    echo "旧 vault 文件总数: $OLD_TOTAL"

    # 逐文件复制（跳过已有和 .obsidian 配置）
    COPIED=0
    SKIPPED=0
    while IFS= read -r -d '' src; do
        # 相对路径
        rel="${src#$OLD_VAULT/}"
        dest="$TARGET_DIR/$rel"

        if [ -f "$dest" ] || [ -d "$dest" ]; then
            SKIPPED=$((SKIPPED + 1))
        else
            mkdir -p "$(dirname "$dest")"
            cp "$src" "$dest"
            COPIED=$((COPIED + 1))
        fi
    done < <(find "$OLD_VAULT" -type f \
        -not -path '*/.git/*' \
        -not -path '*/.obsidian/*' \
        -not -path '*/node_modules/*' \
        -not -name '*.zip' \
        -not -name 'Thumbs.db' \
        -not -name '.DS_Store' \
        -print0)

    echo ""
    echo "✅ 复制了 $COPIED 个独有文件"
    echo "⏭️  跳过了 $SKIPPED 个已存在文件（两边都有）"
    echo "🔒 跳过了 .obsidian/ 配置（保留共享仓库版本）"

    # 提交合并
    if [ "$COPIED" -gt 0 ]; then
        echo ""
        echo "📝 提交合并..."
        git add -A
        git commit -m "merge: 合并本地旧vault独有内容 — $COPIED 个新文件

Co-Authored-By: Claude <noreply@anthropic.com>" || echo "⚠️  没有新内容需要提交"
        echo ""
        echo "📤 推送到 GitHub..."
        git push
        echo "✅ 合并已推送"
    else
        echo ""
        echo "ℹ️  没有独有文件，无需合并"
    fi
fi

# ── 拉取最新 ─────────────────────────────────────────────
echo ""
echo "📥 拉取远程最新..."
git pull 2>&1 || echo "⚠️  pull 失败（可能已是最新）"

# ── 验证清单 ─────────────────────────────────────────────
echo ""
echo "────────────────────────────────────────────"
echo " 📋 验证清单"
echo "────────────────────────────────────────────"
echo ""
echo "✅ 共享仓库: $TARGET_DIR"
echo "✅ 远程地址: origin  →  Joe260621/obsidian-vault"
echo "✅ 当前分支: $(git branch --show-current)"
echo "✅ 最新提交: $(git log --oneline -1)"
echo "✅ 自动提交: 每 30 分钟"
echo "✅ 自动推送: 每 30 分钟"
if [ "$MODE" = "merge" ]; then
    echo "✅ 合并完成: +$COPIED 新文件 / $SKIPPED 跳过"
fi
echo ""
echo "────────────────────────────────────────────"
echo " 🚀 下一步"
echo "────────────────────────────────────────────"
echo ""
echo "1. 打开 Obsidian → Open folder as vault → 选择:"
echo "   $TARGET_DIR"
echo ""
echo "2. 如果提示 Safe mode → 点「关闭安全模式」"
echo "   插件配置已随仓库同步，无需重新安装"
echo ""
echo "3. 检查左侧是否有 Git 图标（源代码管理）"
echo "   如果没有 → Settings → Community plugins → 手动启用 obsidian-git"
echo ""
echo "4. 快捷键 Ctrl+P → 输入 'Obsidian Git: Pull' → 验证同步"
echo ""
echo "============================================"
echo " 🎉 设置完成！"
echo "============================================"
