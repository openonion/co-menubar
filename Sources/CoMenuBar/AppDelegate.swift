import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var popoverController: PopoverController!

    private let agent = CoAgent()
    private var pendingUpdate: (version: String, url: URL)?

    // MARK: - Launch

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildStatusItem()
        buildPopover()
        wireAgent()
        checkForUpdate()
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
        popoverController = PopoverController()
        popoverController.onStart = { [weak self] in self?.startAgent() }
        popoverController.onStop = { [weak self] in self?.stopAgent() }
        popoverController.onSend = { [weak self] text in self?.agent.send(text) }

        popover = NSPopover()
        popover.contentViewController = popoverController
        popover.behavior = .transient
    }

    private func wireAgent() {
        agent.onOutput = { [weak self] text in
            self?.popoverController.appendOutput(text)
        }
        agent.onStateChange = { [weak self] in
            guard let self else { return }
            let running = self.agent.isRunning
            self.popoverController.updateState(running: running)
            self.updateStatusIcon(running: running)
        }
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
            popoverController.focusInput()
        }
    }

    // MARK: - Context Menu (right-click)

    private func showContextMenu() {
        let menu = NSMenu()

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
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    // MARK: - Agent

    private func startAgent() {
        agent.start()
        popoverController.updateState(running: true)
        updateStatusIcon(running: true)
    }

    private func stopAgent() {
        agent.stop()
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
        let attrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.white.withAlphaComponent(running ? 1.0 : 0.55),
            .font: NSFont.systemFont(ofSize: 14),
        ]
        statusItem.button?.attributedTitle = NSAttributedString(string: "⚡", attributes: attrs)
    }
}
