# 📱 原型一键预览

**CC 写 HTML → 自动编译 → 模拟器弹出来直接看**

这个目录是**原型工作区**（默认 `~/prototypes/`，可用 `PROTO_WORKSPACE` 环境变量改）。
下面这些文件是脚手架，由 `ios-prototype-preview` skill 铺开的：

```
<工作区>/
├── index.html                  ← 原型主页（自动发现所有原型）
├── server.py                   ← HTTP 服务器 + 文件列表 API
├── generate-project.py         ← Xcode 项目生成器
├── setup.sh                    ← 一次性环境搭建
├── preview.sh                  ← 一键编译 + 模拟器预览 ⭐
├── serve.sh                    ← 仅启动服务器（手动模式）
│
├── <你的原型>/
│   └── index.html
│
├── ios-app/
│   ├── ProtoViewer.xcodeproj/   ← 自动生成（首次运行时）
│   ├── ProtoViewerApp.swift
│   ├── ContentView.swift
│   └── Info.plist
│
└── README.md
```

## 首次使用（只需一次）

```bash
./setup.sh
```

这会：检查 Xcode 环境 → 生成 iOS App 项目 → 自动打开 Xcode（看一眼就行，不需要手动操作）。

> `setup.sh` 不是必需的 —— `preview.sh` 首次运行会自动补上生成 Xcode 项目这一步。
> `setup.sh` 的额外价值是逐文件校验 + 打开 Xcode GUI。

## 日常使用

### 方式一：一键预览 ⭐

```bash
./preview.sh
```

自动完成：启动服务器 → 编译 App → 启动模拟器 → 加载原型页面。

常用参数：

```bash
./preview.sh --no-build                    # 跳过编译（App 没变时更快）
./preview.sh --device "iPhone 17 Pro"      # 指定设备（默认自动选最新的可用 iPhone）
./preview.sh --port 8090                   # 换端口
./preview.sh --active my-proto/index.html  # 直接打开指定页面
./preview.sh --help                        # 全部用法
```

环境变量：`PROTO_PORT`（默认 8080）、`PROTO_HOST`（默认 `127.0.0.1`）。

### 方式二：让 Claude 帮你预览

对 Claude Code 说：

> "帮我做一个 xxx 原型，然后 preview 一下"

Claude 会生成 HTML 后自动运行 `./preview.sh`。

### 方式三：手动

```bash
./serve.sh           # 终端 1：启动服务器
# Xcode → Cmd+R     # 终端 2：运行 App
```

## iOS App 操作

| 操作 | 方式 |
|------|------|
| 唤出/隐藏工具栏 | 点屏幕底部边缘 |
| 切换原型页面 | 点 📁 → 选择页面（按文件夹分组） |
| 刷新当前页面 | 🔄 按钮 / 下拉手势 |
| 调试 HTML | Safari → 开发 → Simulator → 页面 |

## 多原型管理

```
<工作区>/
├── 2026-06-02-login/        ← 按日期
│   ├── index.html
│   └── home.html
├── e-commerce/              ← 按项目
│   ├── index.html
│   └── checkout.html
└── chat-redesign/
    └── index.html
```

iOS App 自动发现所有 `.html` 文件，按文件夹分组。新增文件后会出现在文件选择器中（下拉刷新列表）。

## 真机预览

1. iPhone 和 Mac 同一 Wi-Fi
2. 获取 Mac IP：`ipconfig getifaddr en0`
3. 修改 `ios-app/ContentView.swift` 中 `serverHost` 为 Mac IP
4. 用 `./preview.sh --host 0.0.0.0` 让服务器监听局域网
5. 数据线连 iPhone → Xcode 选手机 → 运行

> ⚠️ `--host 0.0.0.0` 意味着同一网络下的任何人都能读到本目录下的**全部** `.html`。
> 只在可信网络下开，用完记得改回默认值。

## 清理

编译产物在 `.build/` 目录，可随时删除：

```bash
rm -rf .build
```
