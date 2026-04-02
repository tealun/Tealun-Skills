#!/bin/bash
# Memory Forest v5.1 - Installation Script
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_VERSION="1.0.0"

echo ""
echo "🌳 Memory Forest v${SKILL_VERSION}"
echo "===================================="
echo ""

# 检查依赖
for cmd in bash date grep sed awk; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "❌ Missing: $cmd"
        exit 1
    fi
done
echo "✅ All dependencies satisfied"

# 安装命令
INSTALL_DIR="${HOME}/.local/bin"
mkdir -p "$INSTALL_DIR"

if [[ -w "$INSTALL_DIR" ]]; then
    ln -sf "${SCRIPT_DIR}/core/forest.sh" "${INSTALL_DIR}/memory-forest"
    echo "✅ Installed: memory-forest"
else
    echo "⚠️  Cannot write to ${INSTALL_DIR}"
    exit 1
fi

echo ""
echo "===================================="
echo "✅ Installation complete!"
echo ""
echo "Quick start:"
echo "  memory-forest init"
echo "  memory-forest remember default corrections 'Test' 'Context'"
echo "  memory-forest status"
echo ""
