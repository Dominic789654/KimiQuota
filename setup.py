"""
KimiQuota Menu Bar - macOS 菜单栏应用打包脚本

使用方法:
    python setup.py py2app  # 打包应用
    
打包完成后，在 dist/ 目录下会生成 KimiQuota.app
"""

from setuptools import setup

APP = ['KimiQuotaMenuBar.app/Contents/MacOS/kimi_menu.py']
DATA_FILES = []
OPTIONS = {
    'argv_emulation': True,
    'iconfile': None,  # 可以添加自定义图标文件路径
    'plist': {
        'CFBundleName': 'KimiQuota',
        'CFBundleDisplayName': 'KimiQuota Menu Bar',
        'CFBundleIdentifier': 'com.yourname.kimiquota',
        'CFBundleVersion': '1.0.0',
        'LSUIElement': True,  # 关键：设置为 True 使其作为菜单栏应用运行，不在 Dock 显示
    },
    'packages': ['rumps', 'requests'],
}

setup(
    app=APP,
    data_files=DATA_FILES,
    options={'py2app': OPTIONS},
    setup_requires=['py2app'],
)
