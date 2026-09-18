#!/bin/bash
# ──────────────────────────────────────────────────────
#  一次性环境搭建
#  检查依赖 → 生成 Xcode 项目 → 验证
# ──────────────────────────────────────────────────────
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  📱 ProtoViewer 环境搭建"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 1. Xcode 协议
if ! xcodebuild -license check 2>/dev/null; then
    echo "⚠️  需要先同意 Xcode 协议:"
    echo "   sudo xcodebuild -license"
    echo ""
fi

# 2. 生成项目
echo "→ 生成 Xcode 项目..."
python3 "$SCRIPT_DIR/generate-project.py"
echo ""

# 3. 验证文件
echo "→ 验证文件..."
MISSING=0
for f in \
    "ios-app/ProtoViewerApp.swift" \
    "ios-app/ContentView.swift" \
    "ios-app/Info.plist" \
    "ios-app/ProtoViewer.xcodeproj/project.pbxproj" \
    "ios-app/ProtoViewer.xcodeproj/xcshareddata/xcschemes/ProtoViewer.xcscheme" \
    "server.py" \
    "preview.sh"
do
    if [ -f "$SCRIPT_DIR/$f" ]; then
        echo "  ✅ $f"
    else
        echo "  ❌ $f 缺失"
        MISSING=1
    fi
done

echo ""

if [ "$MISSING" -eq 1 ]; then
    echo "⚠️  部分文件缺失，请检查"
    exit 1
fi

# 4. 自动打开 Xcode 项目
echo "→ 打开 Xcode 项目..."
open "$SCRIPT_DIR/ios-app/ProtoViewer.xcodeproj"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ 搭建完成！"
echo ""
echo "  日常使用:"
echo "    cd \"$SCRIPT_DIR\" && ./preview.sh"
echo ""
echo "  手动方式:"
echo "    ./serve.sh           启动服务器"
echo "    ./preview.sh         模拟器预览"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
