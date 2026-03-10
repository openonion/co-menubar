# OO MenuBar - Testing Guide

## Quick Start

```bash
cd /Users/changxing/project/OnCourse/platform/oo-menubar
swift build
.build/debug/OOMenuBar
```

## Visual Testing Checklist

### 1. Main Popover - Stopped State

**Expected:**
```
┌─────────────────────────────────────────────────────┐
│  ●  OpenOnion Agent                     [View Logs] │
├─────────────────────────────────────────────────────┤
│                                                     │
│                                                     │
│              💤 Agent is Stopped                    │
│                                                     │
│         Ready to help with your AI tasks           │
│                                                     │
│                                                     │
│              [Start Agent]                          │
│                                                     │
│                                                     │
└─────────────────────────────────────────────────────┘
```

**Test Steps:**
1. ✅ Click menu bar ⚡ icon
2. ✅ Popover opens (560×240px)
3. ✅ See 💤 emoji (large, centered)
4. ✅ See "Agent is Stopped" text
5. ✅ See "Ready to help..." subtitle
6. ✅ See "Start Agent" button (centered)
7. ✅ See "View Logs" button (top right)
8. ✅ No "Restart" button visible
9. ✅ Dark theme colors match design

---

### 2. Main Popover - Running State

**Test Steps:**
1. ✅ Click "Start Agent" button
2. ✅ Wait 1-2 seconds
3. ✅ Emoji changes to ⚡ (animated transition)
4. ✅ Text changes to "Agent is Running"
5. ✅ See "Connected to co/gemini-2.5-pro"
6. ✅ Button changes to "Stop Agent"
7. ✅ "Restart" button appears (to the right)
8. ✅ Subtitle ("Ready to help...") disappears
9. ✅ Both buttons are horizontally centered

---

### 3. Separate Log Window

**Test Steps:**
1. ✅ Click "View Logs" button in main popover
2. ✅ Separate window opens (700×500px)
3. ✅ Window title: "⚡ OpenOnion Logs"
4. ✅ See toolbar with [Clear] [Export] [Close]
5. ✅ See log content area (monospace font)
6. ✅ See initial message: "Waiting for logs from co ai..."
7. ✅ Window is resizable (drag edges)
8. ✅ Window is movable (drag title bar)
9. ✅ Minimum size is 500×300px
10. ✅ Can close window (red button or [Close])

**Additional Tests:**
- ✅ Click "View Logs" again → reuses same window (doesn't open new one)
- ✅ Close window, then click "View Logs" → opens window again
- ✅ Resize to very small → content still readable
- ✅ Resize to very large → content scales properly

---

### 4. Log Window - Functionality

**Test Steps:**

**Clear Button:**
1. ✅ Start agent (generate some logs)
2. ✅ Click "Clear" button
3. ✅ Logs are cleared
4. ✅ See message: "Logs cleared. Waiting for co ai..."

**Export Button:**
1. ✅ Click "Export" button
2. ✅ Save panel opens
3. ✅ Default filename: "oo-logs.txt"
4. ✅ Choose location and save
5. ✅ File is created with log content
6. ✅ Open file → see all logs

**Close Button:**
1. ✅ Click "Close" button
2. ✅ Window closes (same as red button)

**Real-time Logs:**
1. ✅ Keep log window open
2. ✅ Agent is running
3. ✅ New logs appear automatically
4. ✅ Auto-scrolls to bottom
5. ✅ Monospace font (SF Mono or system mono)

---

### 5. Right-Click Menu

**When Stopped:**
```
○ Agent is Stopped
────────────────
Start Agent
────────────────
View Logs...
────────────────
Check for Updates
────────────────
Quit OpenOnion      ⌘Q
```

**Test Steps:**
1. ✅ Right-click menu bar icon
2. ✅ See "○ Agent is Stopped" (disabled, gray)
3. ✅ See "Start Agent"
4. ✅ See "View Logs..."
5. ✅ Click "Start Agent" → agent starts
6. ✅ Click "View Logs..." → log window opens

**When Running:**
```
✓ Agent is Running
────────────────
Stop Agent
Restart Agent
────────────────
View Logs...
────────────────
Check for Updates
────────────────
Quit OpenOnion      ⌘Q
```

**Test Steps:**
1. ✅ Start agent
2. ✅ Right-click menu bar icon
3. ✅ See "✓ Agent is Running" (disabled, gray)
4. ✅ See "Stop Agent"
5. ✅ See "Restart Agent"
6. ✅ Click "Stop Agent" → agent stops
7. ✅ Click "Restart Agent" → agent restarts

---

### 6. Status Icon (Menu Bar)

**Test Steps:**
1. ✅ Agent stopped → icon is dim (opacity 0.55)
2. ✅ Start agent → icon brightens (opacity 1.0)
3. ✅ Stop agent → icon dims again
4. ✅ Transition is smooth (not instant)

---

### 7. Button Interactions

**Main Popover:**
- ✅ "Start Agent" button → starts agent
- ✅ "Stop Agent" button → stops agent
- ✅ "Restart" button → restarts agent
- ✅ "View Logs" button → opens log window
- ✅ All buttons have hover effect
- ✅ All buttons have visual feedback on click

**Log Window:**
- ✅ "Clear" button → clears logs
- ✅ "Export" button → opens save dialog
- ✅ "Close" button → closes window

---

### 8. Edge Cases

**Log File Doesn't Exist:**
1. ✅ Delete ~/.co/logs/oo.log
2. ✅ Open log window
3. ✅ See initial message (no crash)
4. ✅ Start agent → logs appear

**Agent Crashes:**
1. ✅ Start agent
2. ✅ Kill process manually: `pkill -f "co ai"`
3. ✅ Wait 1-2 seconds
4. ✅ Main popover updates to stopped state
5. ✅ Status icon dims

**Multiple Popover Opens:**
1. ✅ Click menu bar icon → opens
2. ✅ Click again → closes
3. ✅ Click again → opens
4. ✅ Click outside → closes (transient behavior)

**Log Window Reuse:**
1. ✅ Open log window
2. ✅ Close it
3. ✅ Open again → same window, preserves logs
4. ✅ Open again (while open) → brings to front

**Resize Behavior:**
1. ✅ Resize log window very small → minimum 500×300
2. ✅ Resize very large → content scales
3. ✅ Text always readable (no overflow)

---

## Performance Checks

### Startup Time
- ✅ App launches in < 1 second
- ✅ Menu bar icon appears immediately
- ✅ First popover open is instant

### Memory Usage
- ✅ Idle (stopped): < 20 MB
- ✅ Running agent: < 50 MB
- ✅ Log window open: < 60 MB

### CPU Usage
- ✅ Idle: 0-1%
- ✅ Agent running: varies (depends on co ai)
- ✅ Log tailing: < 1%

---

## Accessibility Checks

### Keyboard Navigation
- ✅ Tab through buttons in popover
- ✅ Enter/Space activates buttons
- ✅ ⌘Q quits from context menu

### VoiceOver (Optional)
- ✅ Status text is read correctly
- ✅ Buttons are labeled properly
- ✅ Window titles are announced

---

## Regression Tests

### Existing Features (Should Still Work)
- ✅ Agent start/stop/restart
- ✅ Log tailing (real-time updates)
- ✅ Update checking
- ✅ Bundled `co` binary execution
- ✅ Shell environment reading
- ✅ Process termination on quit

---

## Known Issues / Future Improvements

### Not Implemented (By Design)
- ⚠️ Activity stats not shown in UI (tracked in background only)
- ⚠️ Model info is hardcoded (not parsed from logs)
- ⚠️ Settings panel (future enhancement)
- ⚠️ Keyboard shortcuts (future enhancement)

### Should NOT Happen
- ❌ Popover shows old log view (means MainViewController not wired)
- ❌ "View Logs" button does nothing (callback not set)
- ❌ Restart button visible when stopped (progressive disclosure broken)
- ❌ Status icon never changes (onStateChange not working)
- ❌ Multiple log windows open (should reuse singleton)

---

## Quick Smoke Test (30 seconds)

```bash
# 1. Build and run
swift build && .build/debug/OOMenuBar

# 2. Check main popover
- Click menu bar icon
- Should see 💤 and "Agent is Stopped"
- Click "Start Agent"
- Should change to ⚡ and "Agent is Running"

# 3. Check log window
- Click "View Logs"
- Should open separate window with logs
- Close it, reopen → should work

# 4. Check context menu
- Right-click menu bar icon
- Should see status indicator and actions
- Click "Stop Agent"
- Should stop agent

✅ If all above work → implementation successful!
```

---

## Debugging Tips

### App Won't Build
```bash
# Clean and rebuild
rm -rf .build
swift build
```

### App Crashes on Start
```bash
# Run with debug output
.build/debug/OOMenuBar 2>&1 | tee debug.log
```

### Logs Not Appearing
```bash
# Check log file exists
ls -la ~/.co/logs/oo.log

# Manually add test log
echo "Test log entry" >> ~/.co/logs/oo.log
```

### Status Not Updating
```bash
# Check if agent process is actually running
ps aux | grep "co ai"

# Check onStateChange callback is firing (add print statements)
```

---

## Success Criteria

✅ **Core Functionality**
- Main popover shows clear status
- Log window opens separately
- Start/Stop/Restart all work
- Context menu has new items

✅ **Visual Design**
- Matches design mockups
- 8px grid system respected
- Colors match theme
- Animations are smooth

✅ **User Experience**
- Status is glanceable (<1s)
- Actions are obvious
- No technical jargon in main view
- Logs accessible but not intrusive

✅ **Code Quality**
- Builds without warnings
- No memory leaks
- Proper error handling
- Follows Swift best practices

---

## Sign-Off

After completing all tests above:

- [ ] Main popover works (stopped + running states)
- [ ] Log window works (open/close/clear/export)
- [ ] Context menu works (all actions)
- [ ] Status icon updates correctly
- [ ] No crashes or errors
- [ ] Performance is good
- [ ] Visual design matches spec

**Status**: READY FOR RELEASE 🚀
