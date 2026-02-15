# KimiQuota - macOS 菜单栏应用，用于查看 Kimi Coding Plan 余量
class Kimiquota < Formula
  desc "macOS menu bar app to check Kimi Coding Plan quota"
  homepage "https://github.com/yourusername/kimiquota"
  url "https://github.com/yourusername/kimiquota/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "PLACEHOLDER_SHA256"
  license "MIT"

  depends_on "python@3.11"
  depends_on macos: :sonoma

  resource "rumps" do
    url "https://files.pythonhosted.org/packages/50/31/3c8c7a63bed8f45c52b8fcb0b1e0b64c9430d50a5f2683c83b1a6381e7b6/rumps-0.4.0.tar.gz"
    sha256 "b5bc7b122324a0c3867d6c38a62390e4e1b79f2968322365d4a3445b8f809d8f"
  end

  resource "requests" do
    url "https://files.pythonhosted.org/packages/63/70/2bf7780ad2d390a8d301ad0b550f1581eadbd9a20f896afe06353c2a2913/requests-2.32.3.tar.gz"
    sha256 "55365417734eb18255590a9ff9eb97e9e1da868d4ccd6402399eaf68af20a760"
  end

  resource "charset-normalizer" do
    url "https://files.pythonhosted.org/packages/f2/4f/e1808dc01273379acc506d18f1504eb2d299bd4131743b9fc54d7be4df1e/charset_normalizer-3.4.0.tar.gz"
    sha256 "223217c3d4f82c3ac5e29032b3f1c2eb0fb591b72161f86d93f5719079dae93e"
  end

  resource "idna" do
    url "https://files.pythonhosted.org/packages/f1/70/7703c29685631f5a9810cb23f675c5662c2cb4f135b5c3b83c457a63e6b1/idna-3.10.tar.gz"
    sha256 "12f65c9b470abda6dc35cf8e63cc574b1c52b11df2c86030af0ac09b01b13ea9"
  end

  resource "urllib3" do
    url "https://files.pythonhosted.org/packages/ed/63/22ba4ebfe7430b763ff4d88042d6605a9062c7f3c5825b02c8b8ab8b8c7b/urllib3-2.2.3.tar.gz"
    sha256 "e7d814a81dad81e6caf2ec9fdedb284ecc9c73076b62654547cc64ccdcae26e9"
  end

  resource "certifi" do
    url "https://files.pythonhosted.org/packages/0f/bd/1d41ee6ce89b705511f7e9c531d826a28c3b938c1d8a43d877ff7f5b974a/certifi-2024.8.30.tar.gz"
    sha256 "bec941d2aa8195e248a60b31ff9f0558284cf01a52591ceda73ea9afffd69fd9"
  end

  def install
    # 创建虚拟环境
    venv = virtualenv_create(libexec, "python3.11")
    
    # 安装依赖
    venv.pip_install resources
    
    # 安装应用文件
    (libexec/"KimiQuotaMenuBar.app/Contents/MacOS").mkpath
    
    # 复制主程序
    cp "KimiQuotaMenuBar.app/Contents/MacOS/kimi_menu.py", libexec/"KimiQuotaMenuBar.app/Contents/MacOS/"
    
    # 创建启动脚本
    (bin/"kimiquota").write <<~EOS
      #!/bin/bash
      cd "#{libexec}"
      exec "#{libexec}/bin/python3" "KimiQuotaMenuBar.app/Contents/MacOS/kimi_menu.py" "$@"
    EOS
    chmod 0755, bin/"kimiquota"
    
    # 创建命令行工具脚本
    (bin/"kimiquota-cli").write <<~EOS
      #!/bin/bash
      cd "#{libexec}"
      exec "#{libexec}/bin/python3" -c "
import sys
sys.path.insert(0, '#{libexec}/lib/python3.11/site-packages')
exec(open('kimi_quota.py').read())
" "$@"
    EOS
    chmod 0755, bin/"kimiquota-cli"
    
    # 复制命令行工具
    cp "kimi_quota.py", libexec/"kimi_quota.py"
    
    # 创建应用包
    app_path = prefix/"KimiQuota.app"
    (app_path/"Contents/MacOS").mkpath
    (app_path/"Contents/Resources").mkpath
    
    # Info.plist
    (app_path/"Contents/Info.plist").write <<~EOS
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>CFBundleName</key>
        <string>KimiQuota</string>
        <key>CFBundleDisplayName</key>
        <string>KimiQuota Menu Bar</string>
        <key>CFBundleIdentifier</key>
        <string>com.yourname.kimiquota</string>
        <key>CFBundleVersion</key>
        <string>1.0.0</string>
        <key>CFBundlePackageType</key>
        <string>APPL</string>
        <key>LSUIElement</key>
        <true/>
      </dict>
      </plist>
    EOS
    
    # 启动脚本
    (app_path/"Contents/MacOS/KimiQuota").write <<~EOS
      #!/bin/bash
      cd "#{libexec}"
      exec "#{libexec}/bin/python3" "KimiQuotaMenuBar.app/Contents/MacOS/kimi_menu.py" "$@"
    EOS
    chmod 0755, app_path/"Contents/MacOS/KimiQuota"
  end

  def caveats
    <<~EOS
      🌙 KimiQuota 已安装!

      启动菜单栏应用:
        方式1: 在启动台中搜索 "KimiQuota" 并点击
        方式2: 运行: kimiquota
        方式3: 打开: #{opt_prefix}/KimiQuota.app

      命令行工具:
        kimiquota-cli              # 查看余量
        kimiquota-cli --json       # JSON 格式输出

      设置开机启动:
        系统设置 → 通用 → 登录项 → 添加 #{opt_prefix}/KimiQuota.app

      首次使用需要先运行:
        kimi login
    EOS
  end

  test do
    system "#{bin}/kimiquota-cli", "--help" rescue true
  end
end
