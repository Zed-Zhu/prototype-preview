#!/bin/bash
# 启动原型预览服务器（支持多文件、子目录）
# 用法: ./serve.sh [端口号]
cd "$(dirname "$0")" && python3 server.py "$@"
