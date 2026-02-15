#!/bin/bash
# KimiQuota Menu Bar 安装脚本

set -e

echo "🌙 KimiQuota Menu Bar 安装脚本"
echo "================================"
echo ""

# 检查 Python
if ! command -v python3 &> /dev/null; then
    echo "❌ 错误: 未找到 Python3"
    echo "请先安装 Python 3.8 或更高版本"
    exit 1
fi

echo "✅ Python3 已找到: $(python3 --version)"

# 安装依赖
echo ""
echo "📦 安装依赖..."
pip3 install --user requests rumps py2app

# 检查安装
if ! python3 -c "import rumps, requests" 2>/dev/null; then
    echo "⚠️  警告: 依赖安装可能失败，尝试使用 pip..."
    pip install requests rumps py2app
fi

echo "✅ 依赖安装完成"

# 询问是否打包
echo ""
read -p "🛠️  是否打包为独立应用? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "📦 正在打包应用..."
    python3 setup.py py2app
    
    if [ -d "dist/KimiQuota.app" ]; then
        echo "✅ 打包成功!"
        echo ""
        read -p "📂 是否移动到应用程序文件夹? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            cp -r dist/KimiQuota.app /Applications/
            echo "✅ 已移动到 /Applications/KimiQuota.app"
            echo ""
            echo "🚀 启动方式:"
            echo "   1. 在启动台中找到 KimiQuota 并点击"
            echo "   2. 或使用 Spotlight (Cmd+Space) 搜索 'KimiQuota'"
        fi
    else
        echo "❌ 打包失败"
    fi
fi

echo ""
echo "📝 快速使用:"
echo "   命令行: python3 $(pwd)/kimi_quota.py"
echo "   菜单栏: ./$(pwd)/run.sh"
echo ""
echo "✨ 安装完成!"
