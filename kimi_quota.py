#!/usr/bin/env python3
"""
查看 Kimi Coding Plan 余量的脚本

用法:
    python kimi_quota.py
    python kimi_quota.py --json    # 输出 JSON 格式
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import requests


def get_credentials_path() -> Path:
    """获取 Kimi OAuth 凭证文件路径."""
    home = Path.home()
    return home / ".kimi" / "credentials" / "kimi-code.json"


def load_access_token() -> str:
    """从凭证文件加载 access token."""
    cred_path = get_credentials_path()
    
    if not cred_path.exists():
        print(f"错误: 凭证文件不存在: {cred_path}", file=sys.stderr)
        print("请先运行 'kimi login' 登录", file=sys.stderr)
        sys.exit(1)
    
    try:
        with open(cred_path, "r") as f:
            data = json.load(f)
        return data.get("access_token", "")
    except (json.JSONDecodeError, IOError) as e:
        print(f"错误: 读取凭证文件失败: {e}", file=sys.stderr)
        sys.exit(1)


def fetch_usage(access_token: str) -> dict[str, Any]:
    """调用 Kimi API 获取使用量信息."""
    url = "https://api.kimi.com/coding/v1/usages"
    headers = {"Authorization": f"Bearer {access_token}"}
    
    try:
        response = requests.get(url, headers=headers, timeout=30)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.HTTPError as e:
        if e.response.status_code == 401:
            print("错误: 授权失败，请重新运行 'kimi login' 登录", file=sys.stderr)
        elif e.response.status_code == 404:
            print("错误: 使用量接口不可用", file=sys.stderr)
        else:
            print(f"错误: HTTP {e.response.status_code}: {e}", file=sys.stderr)
        sys.exit(1)
    except requests.exceptions.RequestException as e:
        print(f"错误: 请求失败: {e}", file=sys.stderr)
        sys.exit(1)


def format_number(num: int) -> str:
    """格式化数字，添加千位分隔符."""
    return f"{num:,}"


def format_reset_time(reset_time_str: str | None) -> str | None:
    """格式化重置时间为人类可读的格式."""
    if not reset_time_str:
        return None
    
    try:
        # 解析 ISO 格式时间
        if "." in reset_time_str and reset_time_str.endswith("Z"):
            base, frac = reset_time_str[:-1].split(".")
            frac = frac[:6]  # 只保留微秒
            reset_time_str = f"{base}.{frac}Z"
        
        dt = datetime.fromisoformat(reset_time_str.replace("Z", "+00:00"))
        now = datetime.now(timezone.utc)
        
        delta = dt - now
        if delta.total_seconds() <= 0:
            return "即将重置"
        
        days = delta.days
        hours = delta.seconds // 3600
        minutes = (delta.seconds % 3600) // 60
        
        parts = []
        if days > 0:
            parts.append(f"{days}天")
        if hours > 0:
            parts.append(f"{hours}小时")
        if minutes > 0 and days == 0:
            parts.append(f"{minutes}分钟")
        
        if parts:
            return f"{''.join(parts)}后重置"
        return "即将重置"
    except (ValueError, TypeError):
        return None


def parse_usage_data(data: dict[str, Any]) -> dict[str, Any]:
    """解析 API 返回的使用量数据."""
    result = {
        "summary": None,
        "limits": [],
    }
    
    # 解析总使用量
    usage = data.get("usage")
    if isinstance(usage, dict):
        result["summary"] = {
            "label": usage.get("name", usage.get("title", "Weekly limit")),
            "used": int(usage.get("used", 0) or 0),
            "limit": int(usage.get("limit", 0) or 0),
            "remaining": int(usage.get("remaining", 0) or 0),
            "reset_time": usage.get("resetTime") or usage.get("reset_time"),
        }
    
    # 解析各项限制
    limits = data.get("limits", [])
    if isinstance(limits, list):
        for item in limits:
            if not isinstance(item, dict):
                continue
            
            detail = item.get("detail", item)
            if not isinstance(detail, dict):
                detail = item
            
            limit_info = {
                "label": detail.get("name", detail.get("title", detail.get("scope", "Limit"))),
                "used": int(detail.get("used", 0) or 0),
                "limit": int(detail.get("limit", 0) or 0),
                "remaining": int(detail.get("remaining", 0) or 0),
                "reset_time": detail.get("resetTime") or detail.get("reset_time"),
            }
            
            # 尝试从 window 获取时间信息
            window = item.get("window", {})
            if isinstance(window, dict):
                duration = window.get("duration")
                time_unit = window.get("timeUnit", "")
                if duration:
                    if "MINUTE" in time_unit:
                        if duration >= 60 and duration % 60 == 0:
                            limit_info["label"] = f"{duration // 60}h limit"
                        else:
                            limit_info["label"] = f"{duration}m limit"
                    elif "HOUR" in time_unit:
                        limit_info["label"] = f"{duration}h limit"
                    elif "DAY" in time_unit:
                        limit_info["label"] = f"{duration}d limit"
            
            result["limits"].append(limit_info)
    
    return result


def print_usage(data: dict[str, Any], use_color: bool = True) -> None:
    """以人类可读的格式打印使用量信息."""
    parsed = parse_usage_data(data)
    
    # 获取终端宽度
    try:
        width = os.get_terminal_size().columns
    except OSError:
        width = 60
    width = min(width, 70)  # 最大宽度限制
    
    print("=" * width)
    print("🌙 Kimi Coding Plan 余量查询".center(width - 2))
    print("=" * width)
    
    # 打印总使用量
    if parsed["summary"]:
        summary = parsed["summary"]
        reset_hint = format_reset_time(summary.get("reset_time"))
        print(f"\n📊 {summary['label']}:")
        _print_quota_bar(summary["used"], summary["limit"], reset_hint=reset_hint, use_color=use_color)
    
    # 打印各项限制
    if parsed["limits"]:
        print("\n📋 详细限制:")
        for limit in parsed["limits"]:
            reset_hint = format_reset_time(limit.get("reset_time"))
            print(f"\n  • {limit['label']}:")
            _print_quota_bar(limit["used"], limit["limit"], indent="    ", reset_hint=reset_hint, use_color=use_color)
    
    print("\n" + "=" * width)


def supports_color() -> bool:
    """检测终端是否支持颜色."""
    if os.environ.get("NO_COLOR"):
        return False
    if os.environ.get("FORCE_COLOR"):
        return True
    # 简单的启发式检测
    return sys.stdout.isatty() and os.environ.get("TERM") not in ("dumb", None)


def _print_quota_bar(used: int, limit: int, indent: str = "", reset_hint: str | None = None, use_color: bool = True) -> None:
    """打印配额进度条."""
    use_color = use_color and supports_color()
    
    if limit <= 0:
        print(f"{indent}  已使用: {format_number(used)} (无限制)")
        return
    
    remaining = limit - used
    percentage = (remaining / limit) * 100 if limit > 0 else 0
    
    # 确定颜色 (使用 ANSI 颜色码)
    if use_color:
        if percentage >= 50:
            color = "\033[32m"  # 绿色
        elif percentage >= 20:
            color = "\033[33m"  # 黄色
        else:
            color = "\033[31m"  # 红色
        reset = "\033[0m"
    else:
        color = ""
        reset = ""
    
    # 绘制进度条
    bar_width = 30
    filled = int((used / limit) * bar_width) if limit > 0 else 0
    empty = bar_width - filled
    bar = "█" * filled + "░" * empty
    
    print(f"{indent}  [{color}{bar}{reset}]")
    
    # 显示详细信息
    detail_line = f"{indent}  已用: {format_number(used)} / 限额: {format_number(limit)}"
    if reset_hint:
        detail_line += f"  |  {reset_hint}"
    print(detail_line)
    
    print(f"{indent}  剩余: {color}{format_number(remaining)} ({percentage:.1f}%){reset}")


def main() -> int:
    parser = argparse.ArgumentParser(
        description="查看 Kimi Coding Plan 余量",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
    python kimi_quota.py           # 显示人类可读的格式
    python kimi_quota.py --json    # 输出 JSON 格式
        """
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="以 JSON 格式输出原始数据",
    )
    parser.add_argument(
        "--no-color",
        action="store_true",
        help="禁用彩色输出",
    )
    
    args = parser.parse_args()
    
    # 加载 token
    access_token = load_access_token()
    
    # 获取使用量数据
    data = fetch_usage(access_token)
    
    if args.json:
        print(json.dumps(data, indent=2, ensure_ascii=False))
    else:
        print_usage(data, use_color=not args.no_color)
    
    return 0


if __name__ == "__main__":
    sys.exit(main())
