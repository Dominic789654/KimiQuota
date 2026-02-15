#!/usr/bin/env python3
"""
Kimi Coding Plan 余量 - macOS 菜单栏应用

用法:
    python kimi_menu.py          # 直接运行
    python kimi_menu.py --hide-icon  # 隐藏菜单栏图标，只显示文字
"""

from __future__ import annotations

import json
import os
import sys
import threading
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import requests

# 尝试导入 rumps，如果失败则给出友好提示
try:
    import rumps
except ImportError:
    print("错误: 请先安装 rumps 库")
    print("运行: pip install rumps py2app")
    sys.exit(1)


# ============== 配置 ==============
APP_NAME = "KimiQuota"
DEFAULT_REFRESH_INTERVAL = 300  # 默认 5 分钟刷新一次
CREDENTIALS_PATH = Path.home() / ".kimi" / "credentials" / "kimi-code.json"
API_URL = "https://api.kimi.com/coding/v1/usages"

# 图标（使用 emoji）
ICONS = {
    "high": "🟢",    # > 50%
    "medium": "🟡",  # 20-50%
    "low": "🔴",     # < 20%
    "error": "⚠️",
    "loading": "⏳",
}


# ============== 核心功能函数 ==============

def load_access_token() -> str | None:
    """从凭证文件加载 access token."""
    if not CREDENTIALS_PATH.exists():
        return None
    
    try:
        with open(CREDENTIALS_PATH, "r") as f:
            data = json.load(f)
        return data.get("access_token", "")
    except (json.JSONDecodeError, IOError):
        return None


def fetch_usage_sync() -> dict[str, Any] | None:
    """同步方式获取使用量信息."""
    token = load_access_token()
    if not token:
        return None
    
    try:
        response = requests.get(
            API_URL,
            headers={"Authorization": f"Bearer {token}"},
            timeout=10
        )
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException:
        return None


def parse_quota(data: dict[str, Any] | None) -> dict[str, Any]:
    """解析余量数据."""
    if not data:
        return {"error": "无法获取数据", "percentage": 0, "remaining": 0, "limit": 0}
    
    usage = data.get("usage", {})
    if not usage:
        return {"error": "无使用量数据", "percentage": 0, "remaining": 0, "limit": 0}
    
    try:
        limit = int(usage.get("limit", 0) or 0)
        used = int(usage.get("used", 0) or 0)
        remaining = int(usage.get("remaining", 0) or 0)
        
        if limit > 0:
            percentage = (remaining / limit) * 100
        else:
            percentage = 0
            
        # 解析重置时间
        reset_time_str = usage.get("resetTime", "")
        reset_hint = format_reset_time(reset_time_str) if reset_time_str else None
        
        return {
            "limit": limit,
            "used": used,
            "remaining": remaining,
            "percentage": percentage,
            "reset_hint": reset_hint,
            "error": None,
        }
    except (ValueError, TypeError) as e:
        return {"error": f"数据解析错误: {e}", "percentage": 0, "remaining": 0, "limit": 0}


def format_reset_time(reset_time_str: str) -> str | None:
    """格式化重置时间."""
    try:
        if "." in reset_time_str and reset_time_str.endswith("Z"):
            base, frac = reset_time_str[:-1].split(".")
            frac = frac[:6]
            reset_time_str = f"{base}.{frac}Z"
        
        dt = datetime.fromisoformat(reset_time_str.replace("Z", "+00:00"))
        now = datetime.now(timezone.utc)
        
        delta = dt - now
        if delta.total_seconds() <= 0:
            return "即将重置"
        
        days = delta.days
        hours = delta.seconds // 3600
        minutes = (delta.seconds % 3600) // 60
        
        if days > 0:
            return f"{days}天{hours}小时后重置"
        elif hours > 0:
            return f"{hours}小时{minutes}分钟后重置"
        else:
            return f"{minutes}分钟后重置"
    except (ValueError, TypeError):
        return None


def get_icon_and_color(percentage: float) -> tuple[str, str]:
    """根据余量百分比获取图标和颜色描述."""
    if percentage >= 50:
        return ICONS["high"], "充足"
    elif percentage >= 20:
        return ICONS["medium"], "一般"
    else:
        return ICONS["low"], "紧张"


# ============== rumps 应用类 ==============

class KimiQuotaApp(rumps.App):
    def __init__(self, hide_icon: bool = False):
        # 初始状态
        self.quota_data = {"error": "加载中...", "percentage": 0, "remaining": 0, "limit": 0}
        self.hide_icon = hide_icon
        
        # 初始化菜单
        super().__init__(
            title="⏳",
            name=APP_NAME,
            menu=[
                rumps.MenuItem("刷新", callback=self.manual_refresh),
                None,  # 分隔线
                rumps.MenuItem("自动刷新: 开启", callback=self.toggle_auto_refresh),
                None,
                rumps.MenuItem("打开 Kimi Code", callback=self.open_kimi),
                None,
                rumps.MenuItem("退出", callback=self.quit_app),
            ]
        )
        
        # 自动刷新定时器
        self.auto_refresh_enabled = True
        self.refresh_timer = rumps.Timer(self.auto_refresh, DEFAULT_REFRESH_INTERVAL)
        self.refresh_timer.start()
        
        # 立即刷新一次
        self.manual_refresh(None)
    
    def update_display(self):
        """更新菜单栏显示."""
        if self.quota_data.get("error"):
            self.title = f"{ICONS['error']} --"
            return
        
        remaining = self.quota_data.get("remaining", 0)
        percentage = self.quota_data.get("percentage", 0)
        icon, status = get_icon_and_color(percentage)
        
        if self.hide_icon:
            # 只显示文字
            self.title = f"{remaining}"
        else:
            # 显示图标 + 余量
            self.title = f"{icon} {remaining}"
    
    def update_menu_items(self):
        """更新菜单项内容."""
        # 清空当前菜单（保留固定项）
        new_menu = []
        
        # 添加余量信息
        if self.quota_data.get("error"):
            new_menu.append(rumps.MenuItem(f"⚠️ {self.quota_data['error']}", callback=None))
        else:
            remaining = self.quota_data.get("remaining", 0)
            limit = self.quota_data.get("limit", 0)
            used = self.quota_data.get("used", 0)
            percentage = self.quota_data.get("percentage", 0)
            icon, status = get_icon_and_color(percentage)
            
            new_menu.append(rumps.MenuItem(f"{icon} 状态: {status}", callback=None))
            new_menu.append(rumps.MenuItem(f"💚 剩余: {remaining} / {limit}", callback=None))
            new_menu.append(rumps.MenuItem(f"📊 已用: {used} ({100-percentage:.0f}%)", callback=None))
            
            reset_hint = self.quota_data.get("reset_hint")
            if reset_hint:
                new_menu.append(rumps.MenuItem(f"⏰ {reset_hint}", callback=None))
        
        new_menu.append(None)  # 分隔线
        
        # 刷新按钮
        new_menu.append(rumps.MenuItem("🔄 立即刷新", callback=self.manual_refresh))
        
        # 自动刷新开关
        auto_refresh_text = "✅ 自动刷新" if self.auto_refresh_enabled else "⬜ 自动刷新"
        new_menu.append(rumps.MenuItem(auto_refresh_text, callback=self.toggle_auto_refresh))
        
        new_menu.append(None)
        
        # 打开 Kimi Code
        new_menu.append(rumps.MenuItem("🌙 打开 Kimi Code", callback=self.open_kimi))
        
        new_menu.append(None)
        
        # 退出
        new_menu.append(rumps.MenuItem("👋 退出", callback=self.quit_app))
        
        # 更新菜单
        self.menu.clear()
        for item in new_menu:
            if item is None:
                self.menu.add(None)
            else:
                self.menu.add(item)
    
    def refresh_data(self):
        """在后台线程中刷新数据."""
        data = fetch_usage_sync()
        self.quota_data = parse_quota(data)
        
        # 在主线程中更新 UI
        rumps.notification(
            title="Kimi Quota",
            subtitle="数据已更新",
            message=f"剩余: {self.quota_data.get('remaining', 0)}",
            sound=False,
        )
        
        self.update_display()
        self.update_menu_items()
    
    def manual_refresh(self, _):
        """手动刷新."""
        self.title = f"{ICONS['loading']} ..."
        # 在后台线程中执行刷新
        thread = threading.Thread(target=self.refresh_data)
        thread.daemon = True
        thread.start()
    
    def auto_refresh(self, _):
        """自动刷新回调."""
        if self.auto_refresh_enabled:
            thread = threading.Thread(target=self.refresh_data)
            thread.daemon = True
            thread.start()
    
    def toggle_auto_refresh(self, _):
        """切换自动刷新状态."""
        self.auto_refresh_enabled = not self.auto_refresh_enabled
        self.update_menu_items()
        
        if self.auto_refresh_enabled:
            rumps.notification(
                title="Kimi Quota",
                subtitle="设置",
                message="自动刷新已开启",
                sound=False,
            )
        
        return
    
    def open_kimi(self, _):
        """打开 Kimi Code CLI 网站或文档."""
        import webbrowser
        webbrowser.open("https://kimi.com")
    
    def quit_app(self, _):
        """退出应用."""
        if self.refresh_timer:
            self.refresh_timer.stop()
        rumps.quit_application()


# ============== 主入口 ==============

def main():
    # 检查命令行参数
    hide_icon = "--hide-icon" in sys.argv
    
    # 检查依赖
    try:
        import rumps
    except ImportError:
        print("请先安装 rumps:")
        print("  pip install rumps")
        sys.exit(1)
    
    # 创建并运行应用
    app = KimiQuotaApp(hide_icon=hide_icon)
    app.run()


if __name__ == "__main__":
    main()
