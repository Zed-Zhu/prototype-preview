#!/bin/bash
# ──────────────────────────────────────────────────────
#  📱 原型一键预览 — iOS 模拟器自动编译 + 启动
#
#  用法:
#    ./preview.sh                              # 预览
#    ./preview.sh --no-build                   # 跳过编译（App 没变时更快）
#    ./preview.sh --device "iPhone 17"         # 指定设备（默认自动选最新的可用 iPhone）
#    ./preview.sh --port 8090                  # 换端口（默认 8080）
#    ./preview.sh --active <project>/index.html # 自动打开指定页面
#    ./preview.sh --help                       # 显示帮助
#
#  环境变量:
#    PROTO_PORT  默认端口（--port 优先级更高）
#    PROTO_HOST  服务器绑定地址，默认 127.0.0.1（真机预览才需要改）
# ──────────────────────────────────────────────────────
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR/ios-app"
SERVER_PORT="${PROTO_PORT:-8080}"
SERVER_HOST="${PROTO_HOST:-127.0.0.1}"
BUNDLE_ID="com.prototypes.ProtoViewer"
TARGET_DEVICE="${TARGET_DEVICE:-}"
NO_BUILD=false
ACTIVE_FILE=""

usage() {
    # 打印文件开头的注释块（跳过 shebang，遇第一行非注释即停）
    awk 'NR==1{next} /^#/{sub(/^# ?/,""); print; next} {exit}' "$0"
    exit 0
}

# ── 解析参数 ────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        --no-build) NO_BUILD=true; shift ;;
        --device) TARGET_DEVICE="$2"; shift 2 ;;
        --port)   SERVER_PORT="$2"; shift 2 ;;
        --host)   SERVER_HOST="$2"; shift 2 ;;
        --active) ACTIVE_FILE="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) echo "未知参数: $1（用 --help 看用法）" >&2; exit 2 ;;
    esac
done

# ── 颜色 ───────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

log()  { echo -e "${BLUE}→${NC} $*"; }
ok()   { echo -e "${GREEN}✅${NC} $*"; }
err()  { echo -e "\n${RED}❌ $*${NC}" >&2; exit 1; }
hdr()  { echo -e "\n${BOLD}━━━ $* ━━━${NC}"; }

# ── 清理函数 ────────────────────────────────────────
cleanup() {
    if [ -n "$SERVER_PID" ] && kill -0 "$SERVER_PID" 2>/dev/null; then
        kill "$SERVER_PID" 2>/dev/null || true
    fi
}
trap cleanup EXIT

# ── 1. 环境检查 ────────────────────────────────────
log "检查环境..."

command -v xcodebuild >/dev/null 2>&1 || err "需要安装 Xcode 命令行工具: xcode-select --install"
command -v xcrun >/dev/null 2>&1     || err "需要安装 Xcode"
command -v python3 >/dev/null 2>&1   || err "需要 Python 3"

# 检查 iOS 运行时（需 17+：ContentView.swift 用了 iOS 17 的 .onChange(of:) 双参数闭包）
MAX_IOS=$(xcrun simctl list runtimes 2>/dev/null \
    | grep -oE 'iOS [0-9]+' | grep -oE '[0-9]+' | sort -n | tail -1)
if [ -z "$MAX_IOS" ]; then
    err "没有 iOS 模拟器运行时。请在 Xcode → Settings → Platforms → 下载 iOS Simulator"
fi
if [ "$MAX_IOS" -lt 17 ]; then
    err "需要 iOS 17.0 或更高的模拟器运行时，当前最高只有 iOS ${MAX_IOS}.0
   打开 Xcode → Settings → Platforms → 下载一个 iOS 17+ Simulator"
fi

# ── 2. Xcode 项目 ──────────────────────────────────
if [ ! -f "$PROJECT_DIR/ProtoViewer.xcodeproj/project.pbxproj" ]; then
    log "生成 Xcode 项目..."
    python3 "$SCRIPT_DIR/generate-project.py"
fi

# ── 3. 启动服务器 ──────────────────────────────────
log "检查服务器..."

# 检查端口
EXISTING_PID=$(lsof -ti :$SERVER_PORT 2>/dev/null || true)
if [ -n "$EXISTING_PID" ]; then
    # 检查是否是 Python 服务器（我们的或其他的）
    if ps -p "$EXISTING_PID" -o comm= 2>/dev/null | grep -qE "python|Python"; then
        ok "服务器已运行 (PID: $EXISTING_PID)"
        # 验证它确实在提供 api/list
        if ! curl -s "http://localhost:$SERVER_PORT/api/list" >/dev/null 2>&1; then
            log "旧服务器无响应，重启..."
            kill "$EXISTING_PID" 2>/dev/null || true
            sleep 0.5
        fi
    else
        # 端口被非 Python 进程占用 → 重启
        log "端口被占用 (PID: $EXISTING_PID)，释放..."
        kill "$EXISTING_PID" 2>/dev/null || true
        sleep 0.5
    fi
fi

# 再次检查是否需要启动
if ! curl -s "http://localhost:$SERVER_PORT/api/list" >/dev/null 2>&1; then
    log "启动原型服务器..."
    python3 "$SCRIPT_DIR/server.py" "$SERVER_PORT" --host "$SERVER_HOST" > /tmp/proto-server.log 2>&1 &
    SERVER_PID=$!

    for i in $(seq 1 20); do
        if curl -s "http://localhost:$SERVER_PORT/api/list" >/dev/null 2>&1; then
            break
        fi
        sleep 0.2
    done

    if ! curl -s "http://localhost:$SERVER_PORT/api/list" >/dev/null 2>&1; then
        err "服务器启动失败，查看日志: cat /tmp/proto-server.log"
    fi
    ok "服务器已启动 (PID: $SERVER_PID, port $SERVER_PORT)"
fi

# ── 3.5 写入激活文件（告诉服务器和 App 自动打开哪个页面）──
if [ -n "$ACTIVE_FILE" ]; then
    echo "$ACTIVE_FILE" > "$SCRIPT_DIR/.last-prototype"
    log "自动打开: $ACTIVE_FILE"
fi

# ── 4. 查找/创建模拟器 ─────────────────────────────
log "查找 iPhone 模拟器..."

SIMULATOR_UDID=""
SIMULATOR_NAME=""

# 收集全部可用 iPhone。simctl 按 runtime 分组输出，越靠后 runtime 越新。
CANDIDATES=()
while IFS= read -r line; do
    name=$(echo "$line" | sed -E 's/^[[:space:]]*(.+) \([A-F0-9-]+\) \([^)]*\)[[:space:]]*$/\1/')
    udid=$(echo "$line" | grep -oE '[A-F0-9]{8}-([A-F0-9]{4}-){3}[A-F0-9]{12}')
    # sed 没匹配上时 name 会等于原行，据此排除解析失败的行
    if [ -n "$udid" ] && [ "$name" != "$line" ]; then
        CANDIDATES+=("$name|$udid")
    fi
done < <(xcrun simctl list devices available 2>/dev/null | grep -E "iPhone")

pick() { SIMULATOR_NAME="$1"; SIMULATOR_UDID="$2"; }

if [ -n "$TARGET_DEVICE" ]; then
    # 1) 精确匹配设备名
    for c in ${CANDIDATES[@]+"${CANDIDATES[@]}"}; do
        if [ "${c%%|*}" = "$TARGET_DEVICE" ]; then pick "${c%%|*}" "${c##*|}"; break; fi
    done
    # 2) 退而求其次：子串匹配（"iPhone 17" 能命中 "iPhone 17 Pro"）
    if [ -z "$SIMULATOR_UDID" ]; then
        for c in ${CANDIDATES[@]+"${CANDIDATES[@]}"}; do
            case "${c%%|*}" in
                *"$TARGET_DEVICE"*) pick "${c%%|*}" "${c##*|}"; break ;;
            esac
        done
    fi
    if [ -z "$SIMULATOR_UDID" ]; then
        err "找不到模拟器 \"$TARGET_DEVICE\"。可用的有:
$(for c in ${CANDIDATES[@]+"${CANDIDATES[@]}"}; do echo "     • ${c%%|*}"; done)"
    fi
else
    # 未指定 → 取最后一个（runtime 最新的）
    if [ ${#CANDIDATES[@]} -gt 0 ]; then
        last="${CANDIDATES[${#CANDIDATES[@]}-1]}"
        pick "${last%%|*}" "${last##*|}"
    fi
fi

# 一台可用的都没有 → 创建
if [ -z "$SIMULATOR_UDID" ]; then
    if [ -n "$TARGET_DEVICE" ]; then
        CREATE_DEVICE="$TARGET_DEVICE"
    else
        CREATE_DEVICE=$(xcrun simctl list devicetypes 2>/dev/null \
            | grep -oE 'com\.apple\.CoreSimulator\.SimDeviceType\.iPhone-[0-9A-Za-z]+' | tail -1)
    fi
    [ -n "$CREATE_DEVICE" ] || err "找不到任何 iPhone 设备类型，请在 Xcode 中安装 iOS Simulator"
    log "未找到可用模拟器，创建 $CREATE_DEVICE..."
    SIMULATOR_UDID=$(xcrun simctl create "$CREATE_DEVICE" "$CREATE_DEVICE" 2>&1)
    SIMULATOR_NAME="$CREATE_DEVICE"
    [ -n "$SIMULATOR_UDID" ] || err "无法创建模拟器: $CREATE_DEVICE"
fi

ok "使用: $SIMULATOR_NAME"

# ── 5. 编译 App ─────────────────────────────────────
if [ "$NO_BUILD" = false ]; then
    hdr "编译"
    log "编译 ProtoViewer..."
    xcodebuild \
        -project "$PROJECT_DIR/ProtoViewer.xcodeproj" \
        -scheme ProtoViewer \
        -destination "id=$SIMULATOR_UDID" \
        -configuration Debug \
        -derivedDataPath "$SCRIPT_DIR/.build" \
        build 2>&1 | tail -3

    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        err "编译失败。查看完整日志: xcodebuild -project $PROJECT_DIR/ProtoViewer.xcodeproj -scheme ProtoViewer build"
    fi
    ok "编译完成"
else
    ok "跳过编译 (--no-build)"
fi

# ── 6. 安装并启动 ──────────────────────────────────
hdr "启动"
APP_PATH="$SCRIPT_DIR/.build/Build/Products/Debug-iphonesimulator/ProtoViewer.app"

if [ ! -d "$APP_PATH" ]; then
    err "找不到 App: $APP_PATH。请先编译: ./preview.sh"
fi

# 启动模拟器
xcrun simctl boot "$SIMULATOR_UDID" 2>/dev/null || true

# 安装
xcrun simctl install "$SIMULATOR_UDID" "$APP_PATH" 2>&1 | grep -v "^$" || true

# 终止旧实例再启动
xcrun simctl terminate "$SIMULATOR_UDID" "$BUNDLE_ID" 2>/dev/null || true
sleep 0.5

PID=$(xcrun simctl launch "$SIMULATOR_UDID" "$BUNDLE_ID" 2>&1)
if [ $? -eq 0 ]; then
    ok "App 已启动 (PID: $PID)"
else
    echo "$PID" >&2
    err "App 启动失败"
fi

open -a Simulator

# ── 7. 展示当前原型列表 ─────────────────────────────
hdr "就绪"
echo ""
echo "   📱 设备: $SIMULATOR_NAME"
echo "   🌐 服务器: http://localhost:$SERVER_PORT"
echo ""
echo "   📄 可用的原型页面:"
curl -s "http://localhost:$SERVER_PORT/api/list" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    for f in data.get('files', []):
        print(f'     • {f[\"path\"][:50]}')
    print(f'\n   共 {len(data.get(\"files\", []))} 个页面')
except: pass
" 2>/dev/null || true

echo ""
echo "   💡 操作提示:"
echo "     点屏幕底部 — 唤出工具栏"
echo "     点 📁 按钮 — 切换原型页面"
echo "     点 🔄 / 下拉 — 刷新页面"
echo "     Safari → 开发 → Simulator → 调试元素"
echo ""
