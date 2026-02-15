#!/bin/bash
# 设置 KimiQuota 开机自动启动

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLIST_NAME="com.user.kimiquota.plist"
PLIST_TEMPLATE="$SCRIPT_DIR/LaunchAgents/${PLIST_NAME}.template"
PLIST_DST="$HOME/Library/LaunchAgents/$PLIST_NAME"

echo "🚀 设置 KimiQuota 开机自动启动"
echo "==============================="
echo ""

# 检查模板文件
if [ ! -f "$PLIST_TEMPLATE" ]; then
    echo "❌ 错误: 找不到模板文件"
    exit 1
fi

# 读取模板并替换 INSTALL_DIR
echo "📄 生成启动配置文件..."
sed "s|INSTALL_DIR|$SCRIPT_DIR|g" "$PLIST_TEMPLATE" > "$PLIST_DST"

echo "✅ 配置文件已创建: $PLIST_DST"

# 加载 plist
echo ""
echo "🔄 加载服务..."
launchctl load "$PLIST_DST" 2>/dev/null || launchctl load -w "$PLIST_DST"

echo "✅ 服务已加载"

# 启动服务
echo ""
echo "▶️  启动 KimiQuota..."
launchctl start "$PLIST_NAME"

echo ""
echo "✨ 设置完成!"
echo ""
echo "📋 管理命令:"
echo "   查看状态: launchctl list | grep kimiquota"
echo "   停止服务: launchctl stop $PLIST_NAME"
echo "   启动服务: launchctl start $PLIST_NAME"
echo "   卸载服务: launchctl unload $PLIST_DST"
echo ""
echo "📝 日志文件:"
echo "   标准输出: /tmp/kimiquota.out"
echo "   错误日志: /tmp/kimiquota.err"
