**English** | [中文](README.md)

# prototype-preview

**Write an HTML prototype, and see it running on a phone — no opening Xcode, no picking a simulator, no compile-and-wait, no hunting for the page you just edited.**

A Claude Code skill. Claude writes the HTML; this compiles it into an iOS container app, installs it into the iPhone Simulator, and opens the page you last touched. Change the HTML, pull to refresh, see the result.

## Why use it

| Without it | With it |
|---|---|
| Write HTML → open Xcode → pick simulator → build → wait → navigate to your page | Say "preview it" |
| Recompile for every content tweak | **HTML changes need no rebuild** — just pull to refresh |
| Sharing with someone means walking them through the setup | One `git clone`, working in 10 seconds |
| Prototypes scattered across random temp folders | One workspace, every `.html` auto-discovered |

**What you actually get:**

- **No Swift, no Xcode configuration** — the container app's Swift sources and Xcode project ship with the skill and are generated on demand. You only write HTML.
- **No waiting** — only the container app itself needs a rebuild. Everyday prototype edits run with `--no-build` and start instantly.
- **Automatic discovery** — every `.html` in the workspace shows up in the app's page picker, grouped by folder and sorted by modification time. New files appear on pull-to-refresh.
- **Debuggable** — attach Safari's Web Inspector to the simulator page from your Mac. It's just a web page.
- **Built-in toolbar** — tap the bottom edge of the screen to switch pages or reload. It auto-hides after 3 seconds so it never covers your design.

## Install

```bash
git clone https://github.com/Zed-Zhu/prototype-preview.git ~/.claude/skills/prototype-preview
```

Claude Code only discovers `~/.claude/skills/<name>/SKILL.md` — **exactly one level deep** — so the clone path has to be exactly that. Update with `cd ~/.claude/skills/prototype-preview && git pull`.

Then just tell Claude "build me an xxx prototype" or "show me how it looks on a phone".

## Requirements

| Need | Notes |
|---|---|
| macOS | Simulators only exist on macOS |
| Xcode 14+ | For `xcodebuild` / `xcrun simctl` |
| **iOS 17+ simulator runtime** | Xcode → Settings → Platforms. The container app uses iOS 17 SwiftUI APIs |
| Python 3.9+ | Standard library only |

## Workspace

Prototypes live in a **workspace**, `~/prototypes` by default. To change it:

```bash
export PROTO_WORKSPACE="$HOME/my-prototypes"
```

On first use the skill lays the scaffolding into the workspace automatically (idempotent — **it never overwrites files you already have**). Or do it yourself:

```bash
bash ~/.claude/skills/prototype-preview/bin/bootstrap.sh
# prints WORKSPACE=/Users/you/prototypes

# Upgrade the scaffolding (only the 10 scaffolding files; your prototypes are untouched)
bash ~/.claude/skills/prototype-preview/bin/bootstrap.sh --update
```

The workspace looks like this:

```
~/prototypes/
├── preview.sh              ← one-shot build + simulator preview ⭐
├── server.py               ← local HTTP server
├── generate-project.py     ← Xcode project generator
├── serve.sh / setup.sh / index.html
├── ios-app/                ← SwiftUI container app sources
└── <your prototype>/
    └── index.html
```

When you use the skill, Claude handles the workspace details — you just describe what you want.

## Manual usage

```bash
cd ~/prototypes

./preview.sh                              # build + launch simulator
./preview.sh --no-build                   # skip the build (your everyday command)
./preview.sh --device "iPhone 17 Pro"     # pick a device (default: newest available iPhone)
./preview.sh --port 8090                  # different port (default 8080)
./preview.sh --active my-proto/index.html # open a specific page
./preview.sh --help
```

## Inside the app

| Action | How |
|------|------|
| Show/hide the toolbar | Tap the bottom edge of the screen |
| Switch prototypes | Tap 📁 → pick a page (grouped by folder) |
| Reload the current page | 🔄 button / pull gesture |
| Debug the HTML | Mac Safari → Develop → Simulator → page |

## Security note

The preview server **listens on `127.0.0.1` only** by default, so only your machine can reach it.

Real-device preview requires pointing `serverHost` in `ContentView.swift` at your Mac's LAN IP and starting with `./preview.sh --host 0.0.0.0`. **At that point anyone on the same Wi-Fi can read every `.html` in your workspace** — only do it on a network you trust, and switch back afterwards.

## Real-device preview

1. iPhone and Mac on the same Wi-Fi
2. `ipconfig getifaddr en0` to get the Mac's IP
3. Set `serverHost` in `ios-app/ContentView.swift` to that IP
4. `./preview.sh --host 0.0.0.0`
5. Plug in the iPhone → select it in Xcode → run

## Known limitations

- macOS + iOS Simulator only; there is no other-platform path
- The container app sets `CODE_SIGNING_ALLOWED = NO`, so it is simulator-only; running on a real device needs signing set up in Xcode
- `ios-app/ProtoViewer.xcodeproj/` is not committed — `generate-project.py` generates it on demand (deterministic output, so it won't churn your diffs)

## License

MIT — see [LICENSE](LICENSE).
