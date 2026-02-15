# KimiQuota

🌙 查看 Kimi Coding Plan 余量的 macOS 菜单栏应用

[![GitHub](https://img.shields.io/github/license/Dominic789654/KimiQuota)](https://github.com/Dominic789654/KimiQuota/blob/main/LICENSE)
[![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-blue)](https://github.com/Dominic789654/KimiQuota)
[![Homebrew](https://img.shields.io/badge/Homebrew-tap-orange)](https://github.com/Dominic789654/homebrew-kimiquota)

![Menu Bar](https://img.shields.io/badge/menu%20bar-🟢%2083-green)

[English](#english) | [中文](#中文)

---

## 中文

一套完整的工具，用于查看 Kimi Code CLI 的使用量余量。

### 功能特点

| 功能 | 描述 |
|------|------|
| 🟢🟡🔴 状态指示 | 根据余量显示颜色（绿≥50%，黄≥20%，红<20%） |
| 📊 实时显示 | 菜单栏直接显示剩余额度 |
| ⏰ 自动刷新 | 每 5 分钟自动更新 |
| 🔄 手动刷新 | 点击菜单立即刷新 |
| 📝 详细菜单 | 显示状态、已用、重置时间等 |
| 🌙 快速打开 | 一键打开 Kimi 网站 |

### 安装

#### 方式一: Homebrew (推荐 ⭐⭐⭐)

```bash
# 一步安装菜单栏应用
brew install --cask Dominic789654/kimiquota/kimiquota

# 或仅安装命令行工具
brew install Dominic789654/kimiquota/kimiquota
```

#### 方式二: 手动安装

```bash
# 克隆仓库
git clone https://github.com/Dominic789654/KimiQuota.git
cd KimiQuota

# 安装依赖
pip install requests rumps

# 启动
./run.sh
```

### 使用

#### 菜单栏应用

```bash
kimiquota        # 启动菜单栏应用
```

菜单栏会显示: `🟢 83`

点击后显示:
```
🟢 状态: 充足
💚 剩余: 83 / 100
📊 已用: 17 (17%)
⏰ 5天3小时后重置
─────────────
🔄 立即刷新
✅ 自动刷新
─────────────
🌙 打开 Kimi Code
─────────────
👋 退出
```

#### 命令行工具

```bash
kimiquota-cli              # 查看余量
kimiquota-cli --json       # JSON 格式
kimiquota-cli --no-color   # 禁用颜色
```

### 设置开机启动

```bash
# Homebrew 安装后，添加到登录项
osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/KimiQuota.app", hidden:false}'
```

或手动: 系统设置 → 通用 → 登录项 → 添加 KimiQuota.app

---

## English

A complete set of tools to check Kimi Coding Plan quota on macOS.

### Features

| Feature | Description |
|---------|-------------|
| 🟢🟡🔴 Status Indicator | Color based on quota (Green≥50%, Yellow≥20%, Red<20%) |
| 📊 Real-time Display | Show remaining quota in menu bar |
| ⏰ Auto Refresh | Auto update every 5 minutes |
| 🔄 Manual Refresh | Click menu to refresh instantly |
| 📝 Detailed Menu | Show status, usage, reset time |
| 🌙 Quick Open | One-click to open Kimi website |

### Installation

#### Option 1: Homebrew (Recommended ⭐⭐⭐)

```bash
# One-line install menu bar app
brew install --cask Dominic789654/kimiquota/kimiquota

# Or CLI only
brew install Dominic789654/kimiquota/kimiquota
```

#### Option 2: Manual Install

```bash
# Clone repo
git clone https://github.com/Dominic789654/KimiQuota.git
cd KimiQuota

# Install dependencies
pip install requests rumps

# Run
./run.sh
```

### Usage

#### Menu Bar App

```bash
kimiquota        # Start menu bar app
```

Menu bar shows: `🟢 83`

Click to show:
```
🟢 Status: Good
💚 Remaining: 83 / 100
📊 Used: 17 (17%)
⏰ Resets in 5d 3h
─────────────
🔄 Refresh Now
✅ Auto Refresh
─────────────
🌙 Open Kimi Code
─────────────
👋 Quit
```

#### CLI Tool

```bash
kimiquota-cli              # Check quota
kimiquota-cli --json       # JSON format
kimiquota-cli --no-color   # Disable colors
```

### Auto-start on Login

```bash
# Add to login items
osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/KimiQuota.app", hidden:false}'
```

Or manually: System Settings → General → Login Items → Add KimiQuota.app

---

## 📦 Project Structure

```
KimiQuota/
├── kimi_quota.py                  # CLI version
├── KimiQuotaMenuBar.app/          # Menu bar app bundle
│   └── Contents/MacOS/kimi_menu.py
├── homebrew-tap/                  # Homebrew formula
├── install.sh                     # Install script
├── install-brew.sh                # Homebrew-style local install
├── run.sh                         # Quick start
└── README.md                      # This file
```

## ⚠️ Requirements

- macOS 14+ (Sonoma)
- Python 3.11+
- `kimi` CLI logged in (`kimi login`)

## 🔗 Related

- Homebrew Tap: [Dominic789654/homebrew-kimiquota](https://github.com/Dominic789654/homebrew-kimiquota)
- Kimi CLI: https://github.com/MoonshotAI/kimi-cli

## 📄 License

MIT License - see [LICENSE](LICENSE) file
