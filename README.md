[English](README.EN.md) | **中文**

# prototype-preview

**写完 HTML 原型，不用再手动开 Xcode、选模拟器、编译、等、然后点到那一页 —— 一条命令直接看效果。**

一个 Claude Code skill：Claude 写 HTML，它自动编译成一个 iOS 容器 App，装进 iPhone 模拟器，并打开你刚改的那一页。改完下拉刷新就是新版。

## 为什么用它

原型做出来，最要紧的是**马上看到它在真手机上长什么样** —— 不是在设计稿里想象，也不是在浏览器里缩着一个手机框看，而是真的跑在 iOS 模拟器里，用手指点、滑、下拉。

这件事本身要花的时间，全被工具链吃掉了：开 Xcode、选模拟器、编译、等、再手动翻到你刚改的那一页。这个 skill 把这一串收成一句「preview 一下」。

围绕「即时看到」，它还顺手解决了另外三件事：**改得快、好截图分享、好维护**。

### 1. 即时看到手机端效果

- 真的跑在 iPhone 模拟器里，不是浏览器里的"手机预览框"
- 系统字体、滚动手感、安全区、下拉刷新，全是 iOS 的真实行为，不是模拟出来的
- 容器 App 自带工具栏：点屏幕底部唤出，可切页面、可刷新，3 秒无操作自动隐藏，不挡你的设计

### 2. 快速修改

- **改 HTML 不用重新编译** —— 只有容器 App 本身变了才要重编译，日常改原型走 `--no-build`，秒起
- 改完在模拟器里**下拉即刷新**，不用切窗口、不用重新运行
- 你还在跟 Claude 对话里，它改完可以直接帮你 preview，不用你离开对话干这些

### 3. 截图和分享

- 模拟器就是一台真的 iPhone，**截出来的图就是一张像样的手机截图** —— 直接贴进 PRD、周报、设计评审，不用再套壳
- 因为工具栏会自动隐藏，**截图里不会出现调试控件**
- 原型就是**纯 HTML 文件**，可以直接发给别人；多页面的原型对方本地起一下自带的 `serve.sh` 就能点着走

### 4. 方便维护

- 所有原型统一在一个工作区，**自动发现**全部 `.html`，按文件夹分组、按修改时间排序，新增文件下拉即出现
- **工具和内容分家** —— 脚手架（编译器、服务器、容器 App）和你的原型是两个独立的目录。升级工具用 `git pull` + `bootstrap.sh --update`，**永远不碰你的原型**
- 原型是纯文本，天然适合 git 管理，改了什么一目了然
- **零 Swift、零 Xcode 配置** —— 容器 App 的源码和工程文件由 skill 自带/按需生成，你只写 HTML
- **能调试** —— Mac Safari → 开发 → Simulator 直接挂开发者工具，跟调网页一样

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
