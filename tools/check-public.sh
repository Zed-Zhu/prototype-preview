#!/bin/bash
# ──────────────────────────────────────────────────────
#  发布前隐私审计
#
#  用法:  bash tools/check-public.sh
#  退出码: 0 = 通过，1 = 发现问题
#
#  检查当前 git 仓库**已追踪**的文件里有没有：
#    1. 个人绝对路径（/Users/<name>、/home/<name>）
#    2. .private-terms 里列出的私有词（该文件本身不入库）
#    3. 凭据 / 密钥
#    4. 二进制垃圾（.DS_Store 等）
#
#  ⚠️ 为什么私有词要放外部文件：如果把私有项目名硬编码进这个脚本，
#     而这个脚本本身是要公开的，那等于把要保护的名字写进了公开仓库。
#     所以词表走 gitignored 的 .private-terms。
# ──────────────────────────────────────────────────────
cd "$(git rev-parse --show-toplevel 2>/dev/null)" || {
    echo "❌ 不在 git 仓库里" >&2; exit 1
}

FAIL=0
fail() { echo "  ❌ $1"; FAIL=1; }
pass() { echo "  ✅ $1"; }

echo "━━━ 发布前隐私审计 ━━━"
echo

# ── 1. 个人绝对路径 ────────────────────────────────────
echo "[1/5] 个人绝对路径"
# /Users/you 是文档里允许出现的占位符
HITS=$(git grep -nIE '/(Users|home)/[A-Za-z0-9._-]+' -- . 2>/dev/null \
       | grep -v '/Users/you' || true)
if [ -n "$HITS" ]; then
    echo "$HITS"
    fail "发现个人绝对路径（上面几行）"
else
    pass "无个人绝对路径"
fi

# ── 2. 私有词表 ────────────────────────────────────────
echo "[2/5] 私有词表 .private-terms"
if [ ! -f .private-terms ]; then
    echo "  ⏭  没有 .private-terms，跳过（建议为本仓库建一个）"
else
    TERM_FAIL=0
    while IFS= read -r term || [ -n "$term" ]; do
        case "$term" in ''|'#'*) continue ;; esac
        T=$(git grep -nIiF -e "$term" -- . 2>/dev/null || true)
        if [ -n "$T" ]; then
            echo "$T" | sed "s/^/  [$term] /"
            TERM_FAIL=1
        fi
    done < .private-terms
    if [ "$TERM_FAIL" -eq 1 ]; then
        fail "命中私有词表中的词"
    else
        pass "未命中任何私有词"
    fi
fi

# ── 3. 凭据 / 密钥 ─────────────────────────────────────
echo "[3/5] 凭据 / 密钥"
CRED=$(git grep -nIE 'sk-[A-Za-z0-9]{20,}|gh[pous]_[A-Za-z0-9]{20,}|xox[baprs]-|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY|AIza[0-9A-Za-z_-]{35}' -- . 2>/dev/null || true)
if [ -n "$CRED" ]; then
    echo "$CRED"
    fail "疑似凭据/密钥"
else
    pass "无凭据/密钥"
fi

# ── 4. 二进制垃圾 ──────────────────────────────────────
echo "[4/5] 二进制垃圾"
BAD=$(git ls-files -z | xargs -0 file 2>/dev/null \
      | grep -viE 'text|JSON|empty|script|source' || true)
if [ -n "$BAD" ]; then
    echo "$BAD"
    fail "追踪了非文本文件"
else
    pass "无二进制文件"
fi

# .DS_Store 单独查（可能是 UTF-16，git grep 查不出内容，但绝不能追踪）
DS=$(git ls-files | grep -i 'DS_Store' || true)
if [ -n "$DS" ]; then
    echo "$DS"
    fail "追踪了 .DS_Store（即使内容是 UTF-16 也要拦）"
else
    pass "无 .DS_Store"
fi

# ── 5. 绝不该入库的目录 ────────────────────────────────
echo "[5/5] 构建产物 / 依赖目录"
JUNK=$(git ls-files | grep -E '(^|/)(node_modules|\.build|xcuserdata|__pycache__|\.xcodeproj)/' || true)
if [ -n "$JUNK" ]; then
    echo "$JUNK" | head -20
    fail "追踪了构建产物或依赖"
else
    pass "无构建产物 / 依赖目录"
fi

# ── 汇总 ───────────────────────────────────────────────
echo
if [ "$FAIL" -eq 0 ]; then
    echo "✅ 全部通过，可以发布"
else
    echo "❌ 有问题，先修再发"
fi
exit "$FAIL"
