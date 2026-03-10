# OO MenuBar v0.7.9 - Polished UI & Settings

## 🎨 Major UI Redesign

Complete redesign following **native macOS patterns** (WiFi, Bluetooth, iStat Menus style). Clean, elegant, everything visible - no more right-click hunting!

### ✨ What's New

#### Polished Native macOS UI
- **Taller, narrower popover** (280×420px) - More native feel
- **Large centered status** - Glanceable at a glance (⚡ Running / 💤 Stopped)
- **Stats card** - Shows uptime and request count when running
- **Menu-style items** - Icons + hover effects (like WiFi menu)
- **All actions visible** - Open Chat, View Logs, Settings (no right-click needed!)
- **Clean sections** - Proper separators and spacing
- **Quit button** - Always visible at bottom with ⌘Q shortcut

#### New Settings Window
- **⚙️ Settings** - Full preferences window with tabs:
  - **General**: Default model, .co folder location, auto-start
  - **Keys & Auth**: Edit .env file, view/copy agent private key
  - **Advanced**: Logs path, custom co binary, debug mode
- **Native tabbed interface** - Clean, organized settings
- **Instant save** - Changes apply immediately

#### Better Stats Tracking
- **Live uptime** - Updates every second while running
- **Request counter** - Tracks completed requests
- **Stats card** - Beautiful card UI showing metrics

#### Improved UX
- **Hover effects** - Subtle backgrounds on menu items (native feel)
- **Progressive disclosure** - Stats only shown when running
- **Loading states** - Spinner + message when starting/stopping
- **Better typography** - Font weights create clear hierarchy
- **Generous spacing** - Breathing room, not cramped

### 📦 Installation

Same as before:

1. **Download** `OOMenuBar.app.zip`
2. **Unzip** the file
3. **Move** `OOMenuBar.app` to `/Applications/`
4. **Right-click → Open** (first time, due to code signing)
5. **Enjoy** the beautiful new UI!

### 🎯 Before & After

**Before (v0.7.8):**
- Header bar with title
- Horizontal button layout
- Important actions hidden in right-click
- No settings
- Static stats

**After (v0.7.9):**
- Clean, centered status
- Vertical menu-style layout (like WiFi)
- All actions visible in main popover
- Full settings window with tabs
- Live updating stats with beautiful card UI
- Hover effects on menu items
- Quit button always visible

### 🐛 Bug Fixes

- Fixed deprecation warning (borderType → isTransparent)
- Improved stats tracking accuracy
- Better state management for loading indicators

### 📚 Technical Details

- Completely redesigned MainViewController (polished native style)
- New SettingsWindowController with tabbed interface
- Updated StatsTracker with live uptime formatting
- Custom HoverButton class for menu-style interactions
- Better typography and spacing throughout

### 🙏 Credits

Designed following Apple Human Interface Guidelines and inspired by native macOS menus (WiFi, Bluetooth, iStat Menus).

---

**Full Changelog**: https://github.com/openonion/co-menubar/compare/v0.7.8...v0.7.9
