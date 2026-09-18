**English** | [中文](README.md)

# prototype-preview

**Write an HTML prototype, and see it running on a phone — no opening Xcode, no picking a simulator, no compile-and-wait, no hunting for the page you just edited.**

A Claude Code skill. Claude writes the HTML; this compiles it into an iOS container app, installs it into the iPhone Simulator, and opens the page you last touched. Change the HTML, pull to refresh, see the result.

## Why use it

The whole point of building a prototype is **seeing what it actually looks like on a real phone** — not imagining it from a mockup, not squinting at a phone-shaped box in a browser, but running it in the iOS Simulator and poking at it with your finger.

Getting to that point is where all the time goes: open Xcode, pick a simulator, build, wait, then navigate back to the page you just edited. This skill turns that chain into "preview it".

And once that's handled, three other things come along with it: **fast edits, easy screenshots and sharing, and easy upkeep.**

### 1. See it on a phone, immediately

- It really runs in the iPhone Simulator — not a "mobile preview" frame inside a browser
- System fonts, scroll physics, safe areas, pull-to-refresh: real iOS behaviour, not an imitation
- The container app ships a toolbar — tap the bottom edge to switch pages or reload. It auto-hides after 3 seconds so it never covers your design

### 2. Fast iteration

- **HTML changes need no rebuild** — only the container app itself does. Everyday edits run with `--no-build` and start instantly
- Change the HTML, **pull to refresh** in the simulator. No switching windows, no re-running
- You're still in the conversation with Claude — it can preview for you the moment it finishes an edit

### 3. Screenshots and sharing

- The simulator *is* an actual iPhone, so **a screenshot is a presentable phone screenshot** — drop it straight into a PRD, a status update, or a design review, no device frame needed
- Because the toolbar auto-hides, **it won't show up in your screenshots**
- Prototypes are **plain HTML files** — send them to anyone; for multi-page prototypes the recipient just runs the bundled `serve.sh` locally

### 4. Easy to maintain

- Every prototype lives in one workspace, **auto-discovered** and grouped by folder, sorted by modification time. New files appear on pull-to-refresh
- **Tooling and content are separate** — the scaffolding (compiler, server, container app) and your prototypes are two independent directories. Upgrade the tooling with `git pull` + `bootstrap.sh --update`; **your prototypes are never touched**
- Prototypes are plain text, so they version-control cleanly — diffs tell you exactly what changed
- **No Swift, no Xcode configuration** — the container app's sources and project file ship with the skill and are generated on demand. You only write HTML
- **Debuggable** — attach Safari's Web Inspector to the simulator page from your Mac. It's just a web page

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
