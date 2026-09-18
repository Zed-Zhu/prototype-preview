#!/bin/bash
# ──────────────────────────────────────────────────────
#  把原型预览脚手架铺到工作区
#
#  用法:
#    ./bootstrap.sh                  # 铺到 $PROTO_WORKSPACE（默认 ~/prototypes）
#    ./bootstrap.sh --update         # 强制覆盖脚手架文件（不碰你的原型目录）
#    ./bootstrap.sh --workspace DIR  # 指定工作区
#    ./bootstrap.sh --help
#
#  行为:
#    · 幂等 —— 默认只补缺失的文件，绝不覆盖已存在的文件
#    · 只碰下面列出的 10 个脚手架文件，不碰工作区里的任何原型目录
#    · 末行输出 WORKSPACE=<绝对路径>，供调用方解析
# ──────────────────────────────────────────────────────
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCAFFOLD="$SCRIPT_DIR/../scaffold"

PROTO_WORKSPACE="${PROTO_WORKSPACE:-$HOME/prototypes}"
UPDATE=false

usage() {
    awk 'NR==1{next} /^#/{sub(/^# ?/,""); print; next} {exit}' "$0"
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --update)    UPDATE=true; shift ;;
        --workspace) PROTO_WORKSPACE="$2"; shift 2 ;;
        -h|--help)   usage ;;
        *) echo "未知参数: $1（用 --help 看用法）" >&2; exit 2 ;;
    esac
done

# 脚手架文件清单（只有这些会被拷贝/覆盖）
SCAFFOLD_FILES=(
    "README.md"
    "preview.sh"
    "server.py"
    "generate-project.py"
    "setup.sh"
    "serve.sh"
    "index.html"
    "ios-app/ProtoViewerApp.swift"
    "ios-app/ContentView.swift"
    "ios-app/Info.plist"
)

[ -d "$SCAFFOLD" ] || { echo "❌ 找不到脚手架目录: $SCAFFOLD" >&2; exit 1; }

mkdir -p "$PROTO_WORKSPACE"
WORKSPACE="$(cd "$PROTO_WORKSPACE" && pwd)"

added=0
updated=0
kept=0

for f in "${SCAFFOLD_FILES[@]}"; do
    src="$SCAFFOLD/$f"
    dst="$WORKSPACE/$f"

    [ -f "$src" ] || { echo "⚠️  脚手架缺少 $f，跳过" >&2; continue; }

    if [ ! -e "$dst" ]; then
        mkdir -p "$(dirname "$dst")"
        cp "$src" "$dst"
        added=$((added + 1))
    elif [ "$UPDATE" = true ]; then
        mkdir -p "$(dirname "$dst")"
        cp "$src" "$dst"
        updated=$((updated + 1))
    else
        kept=$((kept + 1))
    fi
done

chmod +x "$WORKSPACE/preview.sh" "$WORKSPACE/serve.sh" "$WORKSPACE/setup.sh" 2>/dev/null || true

echo "→ 工作区: $WORKSPACE"
echo "  新增 $added / 更新 $updated / 保留原有 $kept"

# 末行契约：调用方靠这行拿工作区绝对路径
echo "WORKSPACE=$WORKSPACE"
