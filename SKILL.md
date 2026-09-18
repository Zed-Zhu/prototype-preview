---
name: ios-prototype-preview
version: 1.0.0
description: "iOS 原型设计预览。当用户想做移动端原型设计、H5 原型、手机端 Demo、在 iOS 模拟器中预览 HTML 原型，或提到「原型」「prototype」「在手机上看看效果」「做个 Demo」时使用。生成 HTML 原型后自动编译并在 iPhone 模拟器中展示。"
---

# iOS 原型预览

在 iOS 模拟器中预览 HTML 原型，支持多页面、下拉刷新、文件切换。

**本 skill 自带一套脚手架**（Xcode 工程生成器 + HTTP 服务器 + SwiftUI 容器 App），放在 skill 目录的 `scaffold/` 下。首次使用时会铺到工作区。

---

## 第 0 步：解析工作区（每次都先做）

脚手架必须在工作区里才跑得起来。**每次都先运行**（幂等，不会覆盖已有文件）：

```bash
bash "${CLAUDE_SKILL_DIR}/bin/bootstrap.sh"
```

取输出的**末行** `WORKSPACE=<绝对路径>` 作为本次会话的工作区根。下文所有 `$PROTO_WORKSPACE` 都指这个值。

- 默认工作区是 `~/prototypes`
- 用户想换位置就设 `PROTO_WORKSPACE` 环境变量，或跑 `bootstrap.sh --workspace <dir>`
- 想升级脚手架到最新版：`bootstrap.sh --update`（只覆盖那 10 个脚手架文件，不碰用户的原型目录）

> 工作区是**用户数据目录**，不要往里写任何非原型文件。

---

## 工作流

### 1. 理解需求，确定原型结构

问清楚：
- **页面有哪些？** 单页还是多页？
- **核心交互是什么？** 列表、表单、Tab 切换、弹出层？
- **风格参考？** iOS 原生感 / Material Design / 特定 App 风格？

### 2. 创建原型目录和 HTML

```bash
# 用 kebab-case 命名，避免中文路径
mkdir -p "$PROTO_WORKSPACE/<project-name>"
```

然后 Write HTML 文件到 `$PROTO_WORKSPACE/<project-name>/<page>.html`。

### 3. HTML 写作规范

每个页面必须包含以下要素：

```html
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <!-- 关键：设置 viewport 适配手机屏幕 -->
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>页面标题</title>
    <style>
        /* 使用 iOS 系统字体 */
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'SF Pro', sans-serif;
            -webkit-font-smoothing: antialiased;
            /* 背景色用 iOS 系统色 */
            background: #f2f2f7;
            color: #1d1d1f;
        }
    </style>
</head>
<body>
    <!-- 原型内容 -->
</body>
</html>
```

**设计建议：**
- 宽度基准 390px（iPhone 逻辑宽度）
- 圆角卡片风格，白色背景 + 12-20px 圆角
- 颜色：主色 `#007aff`、文字 `#1d1d1f`、次要 `#86868b`、背景 `#f2f2f7`
- 字号：标题 17-28px、正文 15px、辅助 12-13px
- 底部留 80px 避免被工具栏遮挡
- 按钮间距至少 44px（方便手指点击）

### 4. 标记目标文件 → 启动预览

**每次生成新原型后，必须写 `.last-prototype` 文件**，这样 App 启动时自动加载该页面，无需手动选择。

```bash
# 写入自动加载标记（路径相对工作区根）
echo "<project>/index.html" > "$PROTO_WORKSPACE/.last-prototype"

# 然后启动预览
cd "$PROTO_WORKSPACE" && ./preview.sh --no-build
```

**首次使用或 App 代码有改动时**（去掉 `--no-build`）：

```bash
cd "$PROTO_WORKSPACE" && ./preview.sh
```

或者一步到位（`preview.sh` 支持 `--active`）：

```bash
cd "$PROTO_WORKSPACE" && ./preview.sh --no-build --active "<project>/index.html"
```

常用参数：`--device "<名称>"` 指定模拟器、`--port N` 换端口、`--help` 看全部。

### 5. 告知用户

模拟器启动后告知用户：

> **模拟器已就绪，自动打开了刚生成的原型。** 下拉刷新看最新改动。点屏幕底部唤出工具栏可切换其他页面。

---

## 项目结构

```
$PROTO_WORKSPACE/
├── preview.sh              ← 一键预览（编译 + 启动模拟器）⭐
├── server.py               ← 本地 HTTP 服务器（自动发现所有 .html）
├── generate-project.py     ← Xcode 项目生成器（首次自动运行）
├── serve.sh                ← 仅启动服务器（手动模式）
├── setup.sh                ← 一次性环境搭建 + 逐文件校验
├── index.html              ← 原型主页（从 /api/list 动态列出全部原型）
│
├── <project-a>/            ← 用户的原型
│   ├── index.html
│   └── detail.html
│
├── ios-app/                ← iOS App 源码 + Xcode 项目
│   ├── ProtoViewer.xcodeproj/   ← 自动生成，不在版本库里
│   ├── ContentView.swift
│   ├── ProtoViewerApp.swift
│   └── Info.plist
│
└── .build/                 ← 编译产物（可随时 rm -rf 清除）
```

**注意 `ios-app/ProtoViewer.xcodeproj/` 是生成的**，不存在时 `preview.sh` 会自动跑 `generate-project.py`。不要手动提交它。

---

## iOS App 功能

| 操作 | 方式 |
|------|------|
| 唤出/隐藏工具栏 | 点屏幕底部边缘 |
| 切换原型页面 | 点 📁 → 选择页面（按文件夹分组） |
| 刷新当前页 | 🔄 按钮 / 下拉手势 |
| 调试 HTML | Mac Safari → 开发 → Simulator → 页面 |

工具栏 3 秒无操作自动隐藏，不遮挡页面内容。

---

## 注意事项

- **首次使用**：`preview.sh` 会自动生成 Xcode 工程；也可以手动跑 `./setup.sh`（额外做逐文件校验并打开 Xcode GUI）
- **需要 iOS 17+ 模拟器运行时**（`ContentView.swift` 用了 iOS 17 的 `.onChange(of:)` 双参数闭包）。`preview.sh` 会在运行时版本不足时明确报错。在 Xcode → Settings → Platforms 下载
- **服务器默认只监听 `127.0.0.1`**，仅本机可访问。端口默认 8080，被占用会报错
- **真机预览**需三条同时满足：改 `ContentView.swift` 中 `serverHost` 为 Mac 局域网 IP、用 `./preview.sh --host 0.0.0.0` 启动、在 Xcode 中选择真机运行
  - ⚠️ `--host 0.0.0.0` 会让同一网络下的任何人都能读到工作区里的**全部** `.html`。只在可信网络下开
- 多页面原型中用 `<a href="/project-b/index.html">` 做页面跳转即可

---

## 故障排查

| 问题 | 解决 |
|------|------|
| 编译失败 | 看完整日志: `xcodebuild -project "$PROTO_WORKSPACE/ios-app/ProtoViewer.xcodeproj" -scheme ProtoViewer build` |
| 报「需要 iOS 17.0 或更高」 | Xcode → Settings → Platforms → 下载 iOS 17+ Simulator |
| 找不到模拟器 | `xcrun simctl create "iPhone 17" "iPhone 17"` 创建，或用 `./preview.sh --device "<确切设备名>"` |
| `--device` 指定的设备不存在 | 命令会列出所有可用设备名，照着填 |
| 服务器端口占用 | `lsof -ti :8080 \| xargs kill`，或 `./preview.sh --port 8090` |
| App 闪退 | `xcrun simctl spawn booted log show --predicate 'process == "ProtoViewer"' --last 2m` |
| 重新来过 | `rm -rf "$PROTO_WORKSPACE/.build" && "$PROTO_WORKSPACE/preview.sh"` |
| 脚手架文件损坏/丢失 | `bash "${CLAUDE_SKILL_DIR}/bin/bootstrap.sh" --update` |
