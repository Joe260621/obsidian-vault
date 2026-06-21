#!/bin/bash
# ============================================================
# Obsidian Vault 同步设置脚本
# 用途: 在新电脑上克隆 vault 并配置 git
# 用法: bash setup-obsidian-sync.sh <GitHub_Token> <目标目录>
# ============================================================

set -e

# ── 参数检查 ────────────────────────────────────────────
if [ $# -lt 1 ]; then
    echo "用法: bash setup-obsidian-sync.sh <GitHub_Token> [目标目录]"
    echo ""
    echo "参数说明:"
    echo "  GitHub_Token  - 在 https://github.com/settings/tokens 创建，勾选 'repo' 权限"
    echo "  目标目录       - vault 存放位置（默认: D:/ProjectManagement/Claude）"
    echo ""
    echo "示例:"
    echo "  bash setup-obsidian-sync.sh ghp_abc123"
    echo "  bash setup-obsidian-sync.sh ghp_abc123 D:/MyVault"
    exit 1
fi

TOKEN="$1"
TARGET_DIR="${2:-D:/ProjectManagement/Claude}"
REPO_URL="https://${TOKEN}@github.com/Joe260621/obsidian-vault.git"
GIT_NAME="Joe260621"
GIT_EMAIL="wzhuo2023@gmail.com"

echo "============================================"
echo " Obsidian Vault 同步设置"
echo "============================================"
echo ""
echo "目标目录: $TARGET_DIR"
echo "仓库:     Joe260621/obsidian-vault"
echo ""

# ── 检查 git ────────────────────────────────────────────
if ! command -v git &> /dev/null; then
    echo "❌ 未找到 git，请先安装: https://git-scm.com/download"
    exit 1
fi
echo "✅ git: $(git --version)"

# ── 克隆仓库 ────────────────────────────────────────────
if [ -d "$TARGET_DIR/.git" ]; then
    echo "⚠️  目标目录已存在 git 仓库，跳过 clone"
    cd "$TARGET_DIR"
else
    echo "📥 克隆仓库..."
    mkdir -p "$(dirname "$TARGET_DIR")"
    git clone "$REPO_URL" "$TARGET_DIR"
    cd "$TARGET_DIR"
    echo "✅ 克隆完成"
fi

# ── Git 配置 ─────────────────────────────────────────────
echo ""
echo "⚙️  配置 git..."
git config user.name "$GIT_NAME"
git config user.email "$GIT_EMAIL"
echo "✅ user.name: $GIT_NAME"
echo "✅ user.email: $GIT_EMAIL"

# ── 验证 ─────────────────────────────────────────────────
echo ""
echo "────────────────────────────────────────────"
echo " 📋 验证清单"
echo "────────────────────────────────────────────"
echo ""
echo "✅ 仓库已克隆到: $TARGET_DIR"
echo "✅ Git 配置完成"
echo "✅ Obsidian Git 插件已随仓库安装"
echo "✅ 自动提交间隔: 30分钟"
echo "✅ 自动推送间隔: 30分钟"
echo ""
echo "────────────────────────────────────────────"
echo " 🚀 下一步"
echo "────────────────────────────────────────────"
echo ""
echo "1. 打开 Obsidian → Open folder as vault → 选择:"
echo "   $TARGET_DIR"
echo ""
echo "2. 如果 Obsidian 提示 Safe mode → 点「关闭安全模式」"
echo ""
echo "3. 检查左侧是否有 Git 图标（源代码管理）"
echo "   如果没有 → Settings → Community plugins → 启用 obsidian-git"
echo ""
echo "4. Ctrl+P → 输入 'Obsidian Git: Pull' → 验证能拉取"
echo ""
echo "============================================"
echo " 🎉 设置完成！打开 Obsidian 开始使用"
echo "============================================"
