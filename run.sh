#!/bin/bash
# KimiQuota Menu Bar 启动脚本

cd "$(dirname "$0")"

# 检查 Python
if ! command -v python3 &> /dev/null; then
    echo "错误: 未找到 Python3"
    exit 1
fi

# 检查依赖
python3 -c "import rumps, requests" 2>/dev/null
if [ $? -ne 0 ]; then
    echo "正在安装依赖..."
    pip3 install rumps requests
fi

# 启动应用
python3 KimiQuotaMenuBar.app/Contents/MacOS/kimi_menu.py "$@"
