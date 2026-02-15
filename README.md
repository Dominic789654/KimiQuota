# KimiQuota

🌙 查看 Kimi Coding Plan 余量的 macOS 菜单栏应用

[![GitHub](https://img.shields.io/github/license/Dominic789654/KimiQuota)](https://github.com/Dominic789654/KimiQuota/blob/main/LICENSE)
[![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-blue)](https://github.com/Dominic789654/KimiQuota)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange)](https://swift.org)

![Menu Bar](https://img.shields.io/badge/menu%20bar-🟢%2083-green)

[English](#english) | [中文](#中文)

---

## 中文

用 Swift 重写的原生 macOS 菜单栏应用，用于查看 Kimi Code CLI 的使用量余量。

### ✨ 功能特点

| 功能 | 描述 |
|------|------|
| 🟢🟡🔴 状态指示 | 根据余量显示颜色（绿≥50%，黄≥20%，红<20%） |
| 📊 实时显示 | 菜单栏直接显示剩余额度 |
| ⏰ 自动刷新 | 每 5 分钟自动更新 |
| 🔄 手动刷新 | 点击菜单立即刷新 |
| 📝 详细菜单 | 显示状态、已用、重置时间等 |
| 🌙 快速打开 | 一键打开 Kimi 网站 |
| 💾 原生应用 | Swift 编写，真正的 macOS 应用 |

### 📥 安装

#### 方式一: 下载预编译版本 (推荐)

1. 从 [GitHub Releases](https://github.com/Dominic789654/KimiQuota/releases) 下载 `KimiQuota.app.zip`
2. 解压，将 `KimiQuota.app` 拖到 **应用程序** 文件夹
3. 双击打开

#### 方式二: Homebrew

```bash
brew tap Dominic789654/kimiquota
brew install --cask kimiquota
```

#### 方式三: 从源码构建

```bash
git clone https://github.com/Dominic789654/KimiQuota.git
cd KimiQuota
./build.sh
# 然后拖拽 KimiQuota.app 到 Applications
```

### 🚀 使用

**首次使用**: 确保已登录 Kimi CLI
```bash
kimi login
```

启动应用后，你会在菜单栏看到：

```
🟢 83
```

点击图标显示详细菜单：
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

### ⚙️ 设置开机启动

```bash
osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/KimiQuota.app", hidden:false}'
```

或手动: 系统设置 → 通用 → 登录项 → 添加 KimiQuota.app

---

## English

A native macOS menu bar app written in Swift to check Kimi Code CLI usage quota.

### ✨ Features

| Feature | Description |
|---------|-------------|
| 🟢🟡🔴 Status Indicator | Color based on quota (Green≥50%, Yellow≥20%, Red<20%) |
| 📊 Real-time Display | Show remaining quota in menu bar |
| ⏰ Auto Refresh | Auto update every 5 minutes |
| 🔄 Manual Refresh | Click menu to refresh instantly |
| 📝 Detailed Menu | Show status, usage, reset time |
| 🌙 Quick Open | One-click to open Kimi website |
| 💾 Native App | Written in Swift, true macOS app |

### 📥 Installation

#### Option 1: Download Pre-built (Recommended)

1. Download `KimiQuota.app.zip` from [GitHub Releases](https://github.com/Dominic789654/KimiQuota/releases)
2. Extract and drag `KimiQuota.app` to **Applications**
3. Double-click to open

#### Option 2: Homebrew

```bash
brew tap Dominic789654/kimiquota
brew install --cask kimiquota
```

#### Option 3: Build from Source

```bash
git clone https://github.com/Dominic789654/KimiQuota.git
cd KimiQuota
./build.sh
# Then drag KimiQuota.app to Applications
```

### 🚀 Usage

**First time**: Make sure you've logged in to Kimi CLI
```bash
kimi login
```

Once launched, you'll see in the menu bar:

```
🟢 83
```

Click the icon to show the detailed menu:
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

### ⚙️ Auto-start on Login

```bash
osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/KimiQuota.app", hidden:false}'
```

Or manually: System Settings → General → Login Items → Add KimiQuota.app

---

## 📦 Project Structure

```
KimiQuota/
├── Sources/KimiQuota/
│   └── main.swift          # Swift source code
├── Package.swift           # Swift Package Manager
├── build.sh                # Build script
├── KimiQuota.app/          # Built app (after running build.sh)
├── kimi_quota.py           # Legacy Python CLI (optional)
└── README.md               # This file
```

## 🛠️ Development

### Requirements

- macOS 14+ (Sonoma)
- Xcode 15+ or Swift 5.9+
- `kimi` CLI logged in (`kimi login`)

### Build

```bash
swift build
swift build -c release
./build.sh
```

### Run

```bash
swift run
# or
open KimiQuota.app
```

## 🔗 Related

- Homebrew Tap: [Dominic789654/homebrew-kimiquota](https://github.com/Dominic789654/homebrew-kimiquota)
- Kimi CLI: https://github.com/MoonshotAI/kimi-cli

## 📄 License

MIT License - see [LICENSE](LICENSE) file
