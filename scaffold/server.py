#!/usr/bin/env python3
"""
原型预览服务器
- 列出所有 .html 文件（支持子目录，按修改时间倒序）
- 提供 /api/list JSON 接口供 iOS App 调用
- 提供 /api/last 返回最新创建的原型
- 常规静态文件服务
"""

import http.server
import json
import os
import sys
from pathlib import Path
from typing import Optional
from urllib.parse import unquote

# ── 参数 ─────────────────────────────────────────────
# 用法: python3 server.py [port] [--host HOST]
# 位置参数 port 保持向后兼容（preview.sh 就是这样调的）。
PORT = 8080
HOST = os.environ.get("PROTO_HOST", "127.0.0.1")

_argv = sys.argv[1:]
_i = 0
while _i < len(_argv):
    a = _argv[_i]
    if a == "--host" and _i + 1 < len(_argv):
        HOST = _argv[_i + 1]
        _i += 2
    elif a in ("-h", "--help"):
        print(__doc__.strip())
        print("\n用法: python3 server.py [port] [--host HOST]")
        print("  默认只监听 127.0.0.1（仅本机可访问），真机预览才需要 --host 0.0.0.0")
        sys.exit(0)
    elif a.isdigit():
        PORT = int(a)
        _i += 1
    else:
        _i += 1

ROOT = Path(__file__).resolve().parent
LAST_FILE = ROOT / ".last-prototype"


SKIP_DIRS = {".build", "ios-app", "node_modules", "__pycache__", ".xcodeproj"}


def scan_html_files(base: Path) -> list[dict]:
    """扫描所有 .html 文件，按修改时间倒序（最新的在前）"""
    files = []
    for p in base.rglob("*.html"):
        rel = p.relative_to(base)
        parts = rel.parts
        # 跳过隐藏目录、构建产物、node_modules 等
        if any(part.startswith(".") or part in SKIP_DIRS for part in parts):
            continue
        files.append({
            "path": str(rel),
            "name": p.stem,
            "folder": str(rel.parent) if str(rel.parent) != "." else "",
            "mtime": p.stat().st_mtime,  # 用于排序
        })
    # 按修改时间倒序
    files.sort(key=lambda f: f["mtime"], reverse=True)
    # 去掉 mtime 不返回给客户端
    for f in files:
        del f["mtime"]
    return files


def get_active_project() -> Optional[str]:
    """读取最近一次生成的原型项目路径，用于自动跳转"""
    if LAST_FILE.exists():
        try:
            target = LAST_FILE.read_text().strip()
            full = ROOT / target
            if full.exists() and full.suffix == ".html":
                return target
        except Exception:
            pass
    return None


class ProtoHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(ROOT), **kwargs)

    def end_headers(self):
        # 禁止 WKWebView 缓存原型 HTML，保证每次都拿最新版本
        self.send_header("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0")
        self.send_header("Pragma", "no-cache")
        self.send_header("Expires", "0")
        super().end_headers()

    def do_GET(self):
        path = unquote(self.path.split("?")[0])

        # API: 列出所有 HTML 文件
        if path == "/api/list":
            files = scan_html_files(ROOT)
            active = get_active_project()
            body = json.dumps({
                "files": files,
                "active": active,  # 自动跳转到这个文件
            }, ensure_ascii=False).encode()
            self.send_response(200)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Content-Length", len(body))
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            self.wfile.write(body)
            return

        # 默认: 静态文件服务
        super().do_GET()

    def log_message(self, format, *args):
        # 简洁日志
        print(f"  {'📄' if '.html' in str(args[0]) else '📦'} {args[0]}")


if __name__ == "__main__":
    files = scan_html_files(ROOT)
    print()
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("  📱 原型预览服务器")
    print(f"  📂 {ROOT}")
    print(f"  🌐 http://localhost:{PORT}")
    print()

    # 绑非回环地址 = 同一网络下的任何人都能读到工作区里的全部 .html
    if HOST not in ("127.0.0.1", "localhost", "::1"):
        print(f"  ⚠️  已绑定 {HOST} —— 同一网络下的任何人都能访问")
        print("     本目录下的所有 .html（含任何私有原型）。")
        print("     仅在你清楚风险、且不在公共网络下时使用。")
        print()

    if files:
        print("  可用页面:")
        for f in files:
            label = f["path"]
            print(f"    • {label}")
    else:
        print("  ⚠️  还没有 .html 文件")
    print()
    print("  在 Xcode 中运行 ProtoViewer 即可预览")
    print("  按 Ctrl+C 停止")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print()

    server = http.server.HTTPServer((HOST, PORT), ProtoHandler)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n👋 已停止")
        server.server_close()
