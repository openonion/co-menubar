# co-menubar

macOS menu bar app for [ConnectOnion](https://connectonion.com) — chat with `co ai` from your menu bar.

No Python or CLI setup required. The `co` binary is bundled inside the app.

## Install

Download `CoMenuBar.app` from [Releases](https://github.com/openonion/co-menubar/releases), drag to `/Applications`, open it.

That's it.

## Usage

| Action | What happens |
|---|---|
| Left-click ⚡ | Opens chat popover |
| **Start** | Launches `co ai` |
| Type + Enter | Sends message |
| **Stop** | Terminates the session |
| Right-click ⚡ | Check for updates / Quit |

The icon dims when stopped, brightens when running.

## Build from Source

Requires macOS 12+, Swift 5.9+, Python 3.

```bash
cd platform/co-menubar

# Build distributable .app (bundles co binary via PyInstaller)
./build-app.sh
cp -r CoMenuBar.app /Applications/

# Debug build (requires co CLI on PATH)
swift build
.build/debug/CoMenuBar
```

## How it works

- The `co` CLI binary is compiled with PyInstaller and embedded in `CoMenuBar.app/Contents/Resources/co`
- When launched from Finder, the app reads your login shell environment so API keys (`OPENAI_API_KEY` etc.) are available
- Updates are delivered as new app releases on GitHub — right-click the icon to check
