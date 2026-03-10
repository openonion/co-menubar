# Release Guide - OO MenuBar

## 🚀 Complete Release Process

### Step 1: Build the Signed App

```bash
cd /Users/changxing/project/OnCourse/platform/oo-menubar

# Build the app bundle (code-signed)
./build-app.sh
```

This creates:
- `OOMenuBar.app` - Signed app bundle
- `OOMenuBar.app.zip` - Distribution archive

### Step 2: Set Version Number

The version is automatically pulled from `../connectonion/pyproject.toml`.

To set a new version:
```bash
cd ../connectonion
# Edit pyproject.toml
vim pyproject.toml
# Change: version = "0.7.7"  →  version = "0.7.8"
```

Or set manually in build-app.sh:
```bash
# Edit build-app.sh line 9:
VERSION="0.7.8"  # Override version
```

### Step 3: Commit All Changes

```bash
cd /Users/changxing/project/OnCourse/platform/oo-menubar

# Stage all changes
git add .

# Create commit
git commit -m "feat: UI redesign with loading states, error alerts, and ANSI colors

- Add loading spinner for immediate feedback
- Fix menu bar icon rendering (18x18pt template)
- Add error alerts for failures
- Add button hover states
- Increase spacing (8px → 16px)
- Improve visual hierarchy (22pt bold status)
- Add copy URL button (📋)
- ANSI color support in logs
- Chat URL from keys.env
- Auto-start on launch"
```

### Step 4: Create Git Tag

```bash
# Create annotated tag with version
git tag -a v0.7.8 -m "Release v0.7.8 - UI Redesign"

# Push commits
git push origin main

# Push tags
git push origin v0.7.8
```

### Step 5: Create GitHub Release

**Option A: Using GitHub CLI (`gh`)**

```bash
# Install gh if needed
brew install gh

# Login
gh auth login

# Create release with app bundle
gh release create v0.7.8 \
  --title "OO MenuBar v0.7.8 - UI Redesign" \
  --notes-file RELEASE_NOTES.md \
  OOMenuBar.app.zip

# Or with inline notes:
gh release create v0.7.8 \
  --title "OO MenuBar v0.7.8 - UI Redesign" \
  --notes "## 🎨 Major UI Redesign

### What's New
- ✅ Loading spinner for immediate feedback
- ✅ Error alerts (no more silent failures)
- ✅ Button hover states (buttons feel alive)
- ✅ Better spacing (16px gaps vs 8px)
- ✅ Visual hierarchy (22pt bold status)
- ✅ Copy URL button (📋 one-click copy)
- ✅ ANSI color support in logs
- ✅ Menu bar icon (OpenOnion logo)
- ✅ Auto-start on launch

### Download
Download \`OOMenuBar.app.zip\`, unzip, and move to \`/Applications\`.

### Full Changelog
See commit history for details." \
  OOMenuBar.app.zip
```

**Option B: Using GitHub Web UI**

1. Go to: https://github.com/openonion/co-menubar/releases/new

2. Fill in:
   - **Tag**: `v0.7.8` (select existing tag or create new)
   - **Title**: `OO MenuBar v0.7.8 - UI Redesign`
   - **Description**: (see RELEASE_NOTES.md below)
   - **Attach file**: Upload `OOMenuBar.app.zip`

3. Click **Publish release**

---

## 📝 Release Notes Template

Save this as `RELEASE_NOTES.md`:

```markdown
# OO MenuBar v0.7.8 - UI Redesign

## 🎨 Major UI Improvements

This release completely redesigns the user interface based on professional design feedback, making the app feel 10x more polished and responsive.

### ✨ What's New

#### Critical Fixes
- **Loading States** - Shows spinner and message when starting/stopping (no more "did it work?" confusion)
- **Error Alerts** - Displays clear error messages instead of failing silently
- **Icon Rendering** - Proper 18x18pt menu bar icon with dark mode support

#### UX Improvements
- **Button Hover States** - Buttons now light up on hover for instant feedback
- **Better Spacing** - Increased gap from 8px to 16px for less cramped layout
- **Visual Hierarchy** - Status text is 22pt bold, clearer importance
- **Copy URL Button** - 📋 button next to "Open Chat" for one-click copying

#### Technical Enhancements
- **ANSI Color Support** - Logs display with full Rich formatting and colors
- **Chat URL Detection** - Automatically loaded from `~/.co/keys.env`
- **Auto-start** - Agent starts automatically on app launch
- **OpenOnion Logo** - Custom menu bar icon instead of emoji

### 📦 Installation

1. **Download** `OOMenuBar.app.zip`
2. **Unzip** the file
3. **Move** `OOMenuBar.app` to `/Applications/`
4. **Launch** from Applications folder
5. **Allow** in System Preferences → Privacy & Security if prompted

### 🎯 Before & After

**Before:**
- Click "Start" → nothing happens (feels broken)
- Cramped button layout (8px gaps)
- All text same size (hard to scan)
- Silent failures (no error messages)

**After:**
- Click "Start" → Instant spinner + "Starting agent..."
- Spacious layout (16px gaps)
- Clear hierarchy (bold status, medium model, regular subtitle)
- Error alerts with explanations

### 🐛 Bug Fixes

- Fixed menu bar icon not showing
- Fixed zombie process handling
- Fixed button layout with long model names

### 📚 Documentation

- Added `DESIGNER_CRITIQUE.md` - Full UX analysis
- Added `ANSI_COLORS_AND_CHAT_URL.md` - Technical details
- Updated all code with comprehensive documentation

### 🙏 Credits

Designed and built with feedback from professional UX designers and the Apple Human Interface Guidelines.

---

**Full Changelog**: https://github.com/openonion/co-menubar/compare/v0.7.7...v0.7.8
```

---

## 🔧 Quick Release Commands

**Complete release in one go:**

```bash
cd /Users/changxing/project/OnCourse/platform/oo-menubar

# 1. Build
./build-app.sh

# 2. Commit
git add .
git commit -m "feat: UI redesign with major UX improvements"

# 3. Tag and push
VERSION="0.7.8"
git tag -a v$VERSION -m "Release v$VERSION - UI Redesign"
git push origin main
git push origin v$VERSION

# 4. Create GitHub release
gh release create v$VERSION \
  --title "OO MenuBar v$VERSION - UI Redesign" \
  --notes-file RELEASE_NOTES.md \
  OOMenuBar.app.zip

echo "✅ Release v$VERSION published!"
echo "🔗 https://github.com/openonion/co-menubar/releases/tag/v$VERSION"
```

---

## 📋 Pre-Release Checklist

Before releasing, verify:

- [ ] App builds successfully (`./build-app.sh`)
- [ ] Code signing works (no errors in build output)
- [ ] App launches and menu bar icon appears
- [ ] All new features work (loading, errors, hover, copy URL)
- [ ] Version number is correct
- [ ] RELEASE_NOTES.md is updated
- [ ] All changes committed to Git
- [ ] Tests pass (if any)

---

## 🚨 Troubleshooting

### Build Fails
```bash
# Clean and rebuild
rm -rf .build OOMenuBar.app OOMenuBar.app.zip .build-pkg
./build-app.sh
```

### Code Signing Issues
```bash
# Check signing identity
security find-identity -v -p codesigning

# If notarization fails, it's okay - app is still code-signed
# Users can install by right-click → Open
```

### Git Push Fails
```bash
# Check remote
git remote -v

# Re-add remote if needed
git remote add origin https://github.com/openonion/co-menubar.git
git push -u origin main
```

### GitHub CLI Not Working
```bash
# Login again
gh auth login

# Or use web UI instead
open https://github.com/openonion/co-menubar/releases/new
```

---

## 🎯 After Release

1. **Announce** on Discord/X/etc
2. **Update documentation** if needed
3. **Monitor** for issues
4. **Respond** to feedback

---

## 📦 Asset Checklist

Release should include:

- [x] `OOMenuBar.app.zip` - Main download
- [x] Release notes (in GitHub release body)
- [x] Tag (v0.7.8)
- [x] Changelog link

Optional:
- [ ] Screenshots of new UI
- [ ] Demo video/GIF
- [ ] Migration guide (if breaking changes)

---

## 🔄 Version Numbering

Follow semantic versioning:
- **Major** (1.0.0): Breaking changes
- **Minor** (0.8.0): New features (backwards compatible)
- **Patch** (0.7.8): Bug fixes

This release: **0.7.8** (patch - UI improvements, no breaking changes)

---

## ✅ Done!

Your app is now:
- ✅ Built and signed
- ✅ Committed to Git
- ✅ Tagged with version
- ✅ Released on GitHub
- ✅ Ready for users to download

**Release URL**: `https://github.com/openonion/co-menubar/releases/tag/v0.7.8`
