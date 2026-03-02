#!/bin/bash

set -e  # 遇到错误立即退出
set -o pipefail  # 管道命令任一失败则整体失败

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMP_DIR=$(mktemp -d)
SOURCE_DIR="$TEMP_DIR/cn_dicts"
TARGET_DIR="$SCRIPT_DIR/../cn_dicts"
REPO_URL="https://github.com/iDvel/rime-ice.git"

# 清理函数 - 确保临时目录被删除
cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
        echo "🧹 已清理临时文件"
    fi
}
trap cleanup EXIT  # 脚本退出时自动清理

echo "📥 开始同步 cn_dicts..."

# 克隆并只获取 cn_dicts 文件夹
if ! git clone --depth 1 --filter=blob:none --sparse "$REPO_URL" "$TEMP_DIR" 2>&1 | grep -v "^Cloning"; then
    echo "❌ 克隆仓库失败"
    exit 1
fi

cd "$TEMP_DIR"
if ! git sparse-checkout set cn_dicts >/dev/null 2>&1; then
    echo "❌ sparse-checkout 设置失败"
    exit 1
fi

# 检查源目录是否存在
if [ ! -d "$SOURCE_DIR" ]; then
    echo "❌ 源目录不存在: $SOURCE_DIR"
    exit 1
fi

# 使用 rsync 同步（保留权限，删除目标中多余文件）
if command -v rsync >/dev/null 2>&1; then
    rsync -a --delete "$SOURCE_DIR/" "$TARGET_DIR/"
    echo "✅ 使用 rsync 同步完成"
else
    # 降级到 cp（如果没有 rsync）
    rm -rf "$TARGET_DIR"
    mkdir -p "$TARGET_DIR"
    cp -r "$SOURCE_DIR"/* "$TARGET_DIR/"
    echo "✅ 使用 cp 同步完成"
fi

# 显示统计信息
FILE_COUNT=$(find "$TARGET_DIR" -type f | wc -l | tr -d ' ')
echo "📊 共同步 $FILE_COUNT 个文件"
echo "📁 目标路径: $TARGET_DIR"
