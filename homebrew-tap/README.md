# KimiQuota Homebrew Tap

通过 Homebrew 安装 KimiQuota macOS 菜单栏应用。

## 安装

### 添加 Tap

```bash
brew tap yourusername/kimiquota
```

### 安装菜单栏应用

```bash
brew install --cask kimiquota
```

### 安装命令行工具

```bash
brew install kimiquota
```

## 使用

### 启动菜单栏应用

```bash
# 方式1: 在启动台中搜索 "KimiQuota"
# 方式2: 命令行启动
kimiquota

# 方式3: 直接打开应用
open /Applications/KimiQuota.app
```

### 命令行工具

```bash
kimiquota-cli              # 查看余量
kimiquota-cli --json       # JSON 格式
kimiquota-cli --no-color   # 禁用颜色
```

## 设置开机启动

```bash
# 方式1: 系统设置
# 系统设置 → 通用 → 登录项 → 添加 KimiQuota.app

# 方式2: 使用 LaunchAgent (命令行)
brew services start kimiquota
```

## 卸载

```bash
brew uninstall kimiquota
brew untap yourusername/kimiquota
```
