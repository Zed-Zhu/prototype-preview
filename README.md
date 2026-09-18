[English](README.EN.md) | **中文**

# prototype-preview

**写完 HTML 原型，不用再手动开 Xcode、选模拟器、编译、等、然后点到那一页 —— 一条命令直接看效果。**

一个 Claude Code skill：Claude 写 HTML，它自动编译成一个 iOS 容器 App，装进 iPhone 模拟器，并打开你刚改的那一页。改完下拉刷新就是新版。

## 为什么用它

| 没有它 | 有它 |
|---|---|
| 写完 HTML → 开 Xcode → 选模拟器 → 编译 → 等 → 手动翻到那一页 | 说一句「preview 一下」 |
| 每次改一点内容都要重新编译 | **改 HTML 不用重编译**，下拉刷新即见 |
| 想给别人看，得先教对方配环境 | 一条 `git clone`，10 秒装好 |
| 原型散落在各种临时目录，找不到 | 统一工作区，自动发现全部 `.html` |

**核心好处：**

- **零 Swift、零 Xcode 配置** —— 容器 App 的 Swift 源码和 Xcode 工程都由 skill 自带/按需生成，你只写 HTML
- **快到不用等** —— 只有容器 App 本身变了才需要重编译，日常改原型走 `--no-build` 秒起
- **自动发现** —— 工作区里所有 `.html` 自动进 App 的页面选择器，按文件夹分组、按修改时间排序，新增文件下拉即出现
- **能调试** —— Mac Safari → 开发 → Simulator 直接挂开发者工具，跟调网页一样
- **自带工具栏** —— 点屏幕底部唤出，可切页、可刷新，3 秒无操作自动隐藏，不挡内容

## 安装

```bash
git clone https://github.com/Zed-Zhu/prototype-preview.git ~/.claude/skills/prototype-preview
```

Claude Code 只识别 `~/.claude/skills/<name>/SKILL.md`（**恰好一层**），所以 clone 路径必须正好是这个。更新用 `cd ~/.claude/skills/prototype-preview && git pull`。

装好后对 Claude 说「做个 xxx 原型」「在手机上看看效果」即可触发。

## 环境要求

| 需要 | 说明 |
|---|---|
| macOS | 模拟器只在 macOS 上有 |
| Xcode 14+ | 需要 `xcodebuild` / `xcrun simctl` |
| **iOS 17+ 模拟器运行时** | Xcode → Settings → Platforms 下载。容器 App 用了 iOS 17 的 SwiftUI API |
| Python 3.9+ | 只用标准库 |

## 工作区

原型文件放在**工作区**里，默认 `~/prototypes`。要换位置：

```bash
export PROTO_WORKSPACE="$HOME/my-prototypes"
```

首次使用时 skill 会自动把脚手架铺进工作区（幂等，**不会覆盖你已有的文件**）。也可以手动：

```bash
bash ~/.claude/skills/prototype-preview/bin/bootstrap.sh
# 末行输出 WORKSPACE=/Users/you/prototypes

# 升级脚手架到最新版（只覆盖那 10 个脚手架文件，不碰你的原型）
bash ~/.claude/skills/prototype-preview/bin/bootstrap.sh --update
```

铺完的工作区长这样：

```
~/prototypes/
├── preview.sh              ← 一键编译 + 模拟器预览 ⭐
├── server.py               ← 本地 HTTP 服务器
├── generate-project.py     ← Xcode 工程生成器
├── serve.sh / setup.sh / index.html
├── ios-app/                ← SwiftUI 容器 App 源码
└── <你的原型>/
    └── index.html
```

用这个 skill 的时候工作区细节由 Claude 处理，你只要提需求。

## 手动用法

```bash
cd ~/prototypes

./preview.sh                              # 编译 + 启动模拟器
./preview.sh --no-build                   # App 没变时跳过编译（日常最常用）
./preview.sh --device "iPhone 17 Pro"     # 指定设备（默认自动选最新的可用 iPhone）
./preview.sh --port 8090                  # 换端口（默认 8080）
./preview.sh --active my-proto/index.html # 直接打开指定页面
./preview.sh --help
```

## iOS App 操作

| 操作 | 方式 |
|------|------|
| 唤出/隐藏工具栏 | 点屏幕底部边缘 |
| 切换原型页面 | 点 📁 → 选择页面（按文件夹分组） |
| 刷新当前页 | 🔄 按钮 / 下拉手势 |
| 调试 HTML | Mac Safari → 开发 → Simulator → 页面 |

## 安全提示

预览服务器**默认只监听 `127.0.0.1`**，只有本机能访问。

真机预览需要改 `ContentView.swift` 里的 `serverHost` 为 Mac 的局域网 IP，并用 `./preview.sh --host 0.0.0.0` 启动。**此时同一 Wi-Fi 下的任何人都能读到工作区里的全部 `.html`** —— 只在可信网络下开，用完改回默认值。

## 真机预览

1. iPhone 和 Mac 连同一个 Wi-Fi
2. `ipconfig getifaddr en0` 拿到 Mac 的 IP
3. 改 `ios-app/ContentView.swift` 里的 `serverHost` 为那个 IP
4. `./preview.sh --host 0.0.0.0`
5. 数据线连 iPhone → Xcode 里选手机 → 运行

## 已知限制

- 只支持 macOS + iOS 模拟器，没有别的平台方案
- 容器 App 的 `CODE_SIGNING_ALLOWED = NO`，只适合模拟器；真机跑要在 Xcode 里配签名
- `ios-app/ProtoViewer.xcodeproj/` 不在版本库里，由 `generate-project.py` 按需生成（确定性输出，不会每次 diff 都变）

## License

MIT，见 [LICENSE](LICENSE)。
