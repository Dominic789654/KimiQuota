#!/bin/bash
# 本地 Homebrew 风格安装脚本
# 模拟 brew install 的体验，但不需要发布到 GitHub

set -e

echo "🌙 KimiQuota 本地安装脚本 (Homebrew 风格)"
echo "=========================================="
echo ""

# 检查 macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ 错误: 此应用仅支持 macOS"
    exit 1
fi

# 检查 Homebrew
if ! command -v brew &> /dev/null; then
    echo "⚠️  未找到 Homebrew"
    echo "请先安装 Homebrew: https://brew.sh"
    exit 1
fi

echo "✅ Homebrew 已安装"

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 创建本地 tap 目录
TAP_DIR="$(brew --prefix)/Library/Taps/local-kimiquota"
echo ""
echo "📁 创建本地 tap..."
mkdir -p "$TAP_DIR/Formula"

# 复制 formula
cp "$SCRIPT_DIR/homebrew-tap/Formula/kimiquota.rb" "$TAP_DIR/Formula/"

# 更新 formula 中的路径
cd "$SCRIPT_DIR"
# 计算当前目录的 sha256 (使用 tar)
ARCHIVE="/tmp/kimiquota-local.tar.gz"
tar czf "$ARCHIVE" --exclude='.git' --exclude='__pycache__' -C "$SCRIPT_DIR/.." "$(basename "$SCRIPT_DIR")"
SHA256=$(shasum -a 256 "$ARCHIVE" | cut -d' ' -f1)

# 修改 formula 使用本地路径
sed -i '' "s|url \"https://github.com/yourusername/kimiquota/archive/refs/tags/v1.0.0.tar.gz\"|url \"file://$ARCHIVE\"|" "$TAP_DIR/Formula/kimiquota.rb"
sed -i '' "s/sha256 \"PLACEHOLDER_SHA256\"/sha256 \"$SHA256\"/" "$TAP_DIR/Formula/kimiquota.rb"

echo "✅ Formula 已创建"

# 安装依赖
echo ""
echo "📦 安装依赖..."
brew install python@3.11 2>/dev/null || true

# 创建安装目录
INSTALL_DIR="$(brew --prefix)/opt/kimiquota"
echo ""
echo "📂 安装到: $INSTALL_DIR"

# 创建虚拟环境
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

if [ ! -d "venv" ]; then
    python3.11 -m venv venv
fi

source venv/bin/activate

# 安装依赖
echo ""
echo "📦 安装 Python 依赖..."
pip install --upgrade pip
pip install rumps requests

# 复制应用文件
echo ""
echo "📂 复制应用文件..."
mkdir -p "$INSTALL_DIR/KimiQuotaMenuBar.app/Contents/MacOS"
cp "$SCRIPT_DIR/KimiQuotaMenuBar.app/Contents/MacOS/kimi_menu.py" "$INSTALL_DIR/KimiQuotaMenuBar.app/Contents/MacOS/"
cp "$SCRIPT_DIR/kimi_quota.py" "$INSTALL_DIR/"

# 创建启动脚本
echo ""
echo "🚀 创建启动脚本..."

# kimiquota 命令 (菜单栏应用)
cat > "$(brew --prefix)/bin/kimiquota" << EOF
#!/bin/bash
cd "$INSTALL_DIR"
source venv/bin/activate
exec python KimiQuotaMenuBar.app/Contents/MacOS/kimi_menu.py "\$@"
EOF
chmod +x "$(brew --prefix)/bin/kimiquota"

# kimiquota-cli 命令 (命令行)
cat > "$(brew --prefix)/bin/kimiquota-cli" << EOF
#!/bin/bash
cd "$INSTALL_DIR"
source venv/bin/activate
exec python kimi_quota.py "\$@"
EOF
chmod +x "$(brew --prefix)/bin/kimiquota-cli"

# 创建应用包
echo ""
echo "📦 创建应用包..."
APP_DIR="/Applications/KimiQuota.app"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# Info.plist
cat > "$APP_DIR/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>KimiQuota</string>
    <key>CFBundleDisplayName</key>
    <string>KimiQuota Menu Bar</string>
    <key>CFBundleIdentifier</key>
    <string>com.local.kimiquota</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSUIElement</key>
    <true/>
    <key>CFBundleExecutable</key>
    <string>KimiQuota</string>
</dict>
</plist>
EOF

# 启动脚本
cat > "$APP_DIR/Contents/MacOS/KimiQuota" << EOF
#!/bin/bash
cd "$INSTALL_DIR"
source venv/bin/activate
exec python KimiQuotaMenuBar.app/Contents/MacOS/kimi_menu.py "\$@"
EOF
chmod +x "$APP_DIR/Contents/MacOS/KimiQuota"

# 清理
rm -f "$ARCHIVE"

echo ""
echo "✅ 安装完成!"
echo ""
echo "🚀 启动方式:"
echo "   • 菜单栏: kimiquota"
echo "   • 命令行: kimiquota-cli"
echo "   • 应用:   在启动台中点击 KimiQuota"
echo ""
echo "📋 设置开机启动:"
echo "   系统设置 → 通用 → 登录项 → 添加 KimiQuota.app"
echo ""
echo "🗑️  卸载方式:"
echo "   rm -rf $INSTALL_DIR"
echo "   rm $(brew --prefix)/bin/kimiquota"
echo "   rm $(brew --prefix)/bin/kimiquota-cli"
echo "   rm -rf $APP_DIR"
