import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var mainViewController: MainViewController!
    private var logWindowController: LogWindowController?
    private var settingsWindowController: SettingsWindowController?

    private let agent = CoAgent()
    private let statsTracker = StatsTracker()
    private var pendingUpdate: (version: String, url: URL)?

    // MARK: - Launch

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildStatusItem()
        buildPopover()
        wireAgent()
        statsTracker.start()
        checkForUpdate()
        loadChatURL()

        // Auto-start agent on launch
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.startAgent()
        }
    }

    private func buildStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateStatusIcon(running: false)

        if let btn = statusItem.button {
            btn.target = self
            btn.action = #selector(handleStatusItemClick(_:))
            btn.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    private func buildPopover() {
        mainViewController = MainViewController()
        mainViewController.onStart = { [weak self] in self?.startAgent() }
        mainViewController.onStop = { [weak self] in self?.stopAgent() }
        mainViewController.onRestart = { [weak self] in self?.restartAgent() }
        mainViewController.onViewLogs = { [weak self] in self?.showLogWindow() }
        mainViewController.onOpenChat = { [weak self] url in self?.openChatURL(url) }
        mainViewController.onSettings = { [weak self] in self?.showSettings() }
        mainViewController.onQuit = { [weak self] in NSApp.terminate(self) }

        popover = NSPopover()
        popover.contentViewController = mainViewController
        popover.behavior = .transient
    }

    private func wireAgent() {
        agent.onStateChange = { [weak self] in
            self?.updateViewState()
            self?.updateChatURL()  // Update chat URL when agent starts/stops
        }

        agent.onOutput = { [weak self] text in
            self?.logWindowController?.appendOutput(text)
        }

        agent.onChatURL = { [weak self] url in
            self?.mainViewController.updateChatURL(url)
        }

        agent.onError = { [weak self] message in
            self?.showError(message)
        }

        statsTracker.onStatsUpdate = { [weak self] uptime, requests in
            guard let self = self else { return }
            _ = self.mainViewController.view  // Ensure view is loaded
            self.mainViewController.updateStats(uptime: uptime, requests: requests)
        }
    }

    private func updateViewState() {
        // Ensure view is loaded before updating state
        _ = mainViewController.view

        let model = agent.isRunning ? agent.currentModel : nil
        mainViewController.updateState(running: agent.isRunning, model: model)
        updateStatusIcon(running: agent.isRunning)

        if agent.isRunning {
            statsTracker.markAgentStarted()
        } else {
            statsTracker.markAgentStopped()
        }
    }

    private func updateChatURL() {
        guard agent.isRunning else {
            mainViewController.updateChatURL(nil)
            return
        }

        // Get agent info (address, model, etc.) from /info endpoint
        let url = URL(string: "http://localhost:8000/info")!
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let address = json["address"] as? String else {
                return
            }

            let chatURL = "https://chat.openonion.ai/\(address)"
            let model = json["model"] as? String

            DispatchQueue.main.async {
                self?.mainViewController.updateChatURL(chatURL)
                // Update model from /info endpoint
                if let model = model {
                    self?.mainViewController.updateModel(model)
                }
            }
        }
        task.resume()
    }

    private func showLogWindow() {
        if logWindowController == nil {
            logWindowController = LogWindowController()
        }
        logWindowController?.showWindow(nil)
        logWindowController?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func showSettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController()
        }
        settingsWindowController?.showWindow(nil)
        settingsWindowController?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Status Item Click

    @objc private func handleStatusItemClick(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent!
        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            togglePopover(sender)
        }
    }

    private func togglePopover(_ sender: NSStatusBarButton) {
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    // MARK: - Context Menu (right-click)

    private func showContextMenu() {
        let menu = NSMenu()

        // Status indicator
        let statusItem = NSMenuItem(title: agent.isRunning ? "✓ Agent is Running" : "○ Agent is Stopped", action: nil, keyEquivalent: "")
        statusItem.isEnabled = false
        menu.addItem(statusItem)

        menu.addItem(.separator())

        // Control actions
        if agent.isRunning {
            let stop = NSMenuItem(title: "Stop Agent", action: #selector(stopAgentFromMenu), keyEquivalent: "")
            stop.target = self
            menu.addItem(stop)

            let restart = NSMenuItem(title: "Restart Agent", action: #selector(restartAgent), keyEquivalent: "")
            restart.target = self
            menu.addItem(restart)
        } else {
            let start = NSMenuItem(title: "Start Agent", action: #selector(startAgentFromMenu), keyEquivalent: "")
            start.target = self
            menu.addItem(start)
        }

        menu.addItem(.separator())

        // View Logs
        let logsItem = NSMenuItem(title: "View Logs...", action: #selector(showLogWindowFromMenu), keyEquivalent: "")
        logsItem.target = self
        menu.addItem(logsItem)

        // Open Chat (only if URL is available)
        if agent.chatURL != nil {
            let chatItem = NSMenuItem(title: "Open Chat →", action: #selector(openChatFromMenu), keyEquivalent: "")
            chatItem.target = self
            menu.addItem(chatItem)
        }

        menu.addItem(.separator())

        // Updates
        if let (version, _) = pendingUpdate {
            let item = NSMenuItem(title: "Update to \(version) →", action: #selector(openReleasePage), keyEquivalent: "")
            item.target = self
            menu.addItem(item)
        } else {
            let item = NSMenuItem(title: "Check for Updates", action: #selector(checkForUpdateManually), keyEquivalent: "")
            item.target = self
            menu.addItem(item)
        }

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit OpenOnion", action: #selector(quitApp), keyEquivalent: "q"))

        self.statusItem.menu = menu
        self.statusItem.button?.performClick(nil)
        self.statusItem.menu = nil
    }

    // MARK: - Agent

    private func startAgent() {
        agent.start()
    }

    private func stopAgent() {
        agent.stop()
    }

    @objc private func startAgentFromMenu() {
        startAgent()
    }

    @objc private func stopAgentFromMenu() {
        stopAgent()
    }

    @objc private func quitApp() {
        stopAgent()
        NSApp.terminate(nil)
    }

    @objc private func restartAgent() {
        agent.restart()
    }

    @objc private func showLogWindowFromMenu() {
        showLogWindow()
    }

    @objc private func openChatFromMenu() {
        if let url = agent.chatURL {
            openChatURL(url)
        }
    }

    private func openChatURL(_ urlString: String) {
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }

    /// Load chat URL from keys.env on startup
    ///
    /// Reads AGENT_ADDRESS from ~/.co/keys.env and constructs the chat URL.
    /// This makes the "Open Chat" button available immediately, without waiting
    /// for the agent to output the URL.
    private func loadChatURL() {
        if let chatURL = KeysEnvReader.readChatURL() {
            agent.chatURL = chatURL
            mainViewController.updateChatURL(chatURL)
        }
    }

    // MARK: - Updates

    private func checkForUpdate() {
        Updater.checkForUpdate { [weak self] version, url in
            guard let version, let url else { return }
            DispatchQueue.main.async {
                self?.pendingUpdate = (version, url)
            }
        }
    }

    @objc private func checkForUpdateManually() {
        pendingUpdate = nil
        checkForUpdate()
    }

    @objc private func openReleasePage() {
        if let (_, url) = pendingUpdate {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Status Icon

    private func updateStatusIcon(running: Bool) {
        guard let button = statusItem.button else { return }

        // Try to load the OpenOnion logo icon
        if let iconImage = NSImage(named: "menubar-icon") ?? loadMenuBarIcon() {
            // Make it a template image so macOS handles dark/light mode
            iconImage.isTemplate = true
            iconImage.size = NSSize(width: 18, height: 18)

            // Set the image
            button.image = iconImage
            button.imagePosition = .imageOnly

            // Adjust opacity based on running state
            button.alphaValue = running ? 1.0 : 0.5
        } else {
            // Fallback to emoji if icon not found
            let attrs: [NSAttributedString.Key: Any] = [
                .foregroundColor: NSColor.white.withAlphaComponent(running ? 1.0 : 0.5),
                .font: NSFont.systemFont(ofSize: 14),
            ]
            button.attributedTitle = NSAttributedString(string: "⚡", attributes: attrs)
        }
    }

    private func loadMenuBarIcon() -> NSImage? {
        // Try to load from bundle resources
        if let resourcePath = Bundle.main.resourcePath {
            let iconPath = resourcePath + "/menubar-icon.png"
            if let image = NSImage(contentsOfFile: iconPath) {
                return image
            }
        }

        // Try from source directory (for debug builds)
        let sourcePath = #file.replacingOccurrences(of: "AppDelegate.swift", with: "menubar-icon.png")
        if let image = NSImage(contentsOfFile: sourcePath) {
            return image
        }

        return nil
    }

    // MARK: - Error Handling

    private func showError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "Agent Error"
        alert.informativeText = message
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
