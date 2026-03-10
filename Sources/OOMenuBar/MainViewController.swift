import AppKit

/// Main Status View Controller
///
/// Displays a clean, status-focused popover interface for the menu bar app.
/// Replaces the old log-viewer-first design with a user-friendly status view.
///
/// ## UI Layout (560×240px)
/// ```
/// ┌─────────────────────────────────────────────┐
/// │  ●  OpenOnion Agent           [View Logs]   │ ← Header (56px)
/// ├─────────────────────────────────────────────┤
/// │                                             │
/// │              ⚡ Agent is Running             │ ← Status emoji
/// │       Connected to co/gemini-2.5-pro        │ ← Model info
/// │                                             │
/// │         [Stop Agent]  [Restart]             │ ← Action buttons
/// │                                             │
/// └─────────────────────────────────────────────┘
/// ```
///
/// ## Features
/// - **Glanceable status**: Large emoji (⚡/💤) + clear text
/// - **Progressive disclosure**: Restart button only shown when running
/// - **Model information**: Shows which AI model is active
/// - **Quick actions**: Start/Stop/Restart buttons front and center
/// - **Clean design**: No logs (moved to separate window)
///
/// ## State Management
/// The view updates via `updateState(running:model:)` which:
/// - Changes emoji (⚡ running / 💤 stopped)
/// - Shows/hides model label
/// - Updates button labels (Start ↔ Stop)
/// - Shows/hides Restart button (progressive disclosure)
/// - Repositions buttons based on visibility
///
/// ## Callbacks
/// All user actions trigger callbacks (onStart, onStop, onRestart, onViewLogs)
/// which are handled by AppDelegate.
class MainViewController: NSViewController {
    // MARK: - UI Components

    /// Large emoji showing agent status (⚡ running / 💤 stopped)
    private var statusIcon: NSTextField!

    /// Status text ("Agent is Running" / "Agent is Stopped")
    private var statusLabel: NSTextField!

    /// Model information label (shown when running, e.g. "Connected to co/gemini-2.5-pro")
    private var modelLabel: NSTextField!

    /// Subtitle label (shown when stopped, e.g. "Ready to help with your AI tasks")
    private var subtitleLabel: NSTextField!

    /// Primary action button (Start Agent / Stop Agent)
    private var primaryButton: NSButton!

    /// Restart button (only visible when agent is running - progressive disclosure)
    private var restartButton: NSButton!

    /// View Logs button in header (opens separate log window)
    private var viewLogsButton: NSButton!

    /// Open Chat button (shown when chat URL is available)
    private var openChatButton: NSButton!

    /// Copy URL button (small button next to Open Chat)
    private var copyURLButton: NSButton!

    /// Loading spinner and label
    private var loadingSpinner: NSProgressIndicator!
    private var loadingLabel: NSTextField!

    // MARK: - State

    /// Current chat URL (nil if not available yet)
    private var chatURL: String?

    // MARK: - Callbacks

    /// Called when user clicks "Start Agent" button
    var onStart: (() -> Void)?

    /// Called when user clicks "Stop Agent" button
    var onStop: (() -> Void)?

    /// Called when user clicks "Restart" button
    var onRestart: (() -> Void)?

    /// Called when user clicks "View Logs" button
    var onViewLogs: (() -> Void)?

    /// Called when user clicks "Open Chat" button with URL
    var onOpenChat: ((String) -> Void)?

    // Layout constants (8px grid)
    private let W: CGFloat = 560
    private let H: CGFloat = 240
    private let headerH: CGFloat = 56
    private let padding: CGFloat = 16
    private let buttonGap: CGFloat = 16

    // Colors (matching current theme)
    private let bgColor = NSColor(calibratedRed: 0.11, green: 0.11, blue: 0.12, alpha: 0.98)
    private let headerColor = NSColor(calibratedRed: 0.14, green: 0.14, blue: 0.15, alpha: 1)
    private let textColor = NSColor(calibratedRed: 0.83, green: 0.83, blue: 0.84, alpha: 1)
    private let subtleTextColor = NSColor(calibratedRed: 0.6, green: 0.6, blue: 0.61, alpha: 1)
    private let accentGreen = NSColor(calibratedRed: 0.31, green: 0.87, blue: 0.47, alpha: 1)
    private let buttonBg = NSColor(calibratedRed: 0.25, green: 0.25, blue: 0.26, alpha: 1)
    private let buttonBorder = NSColor(calibratedRed: 0.35, green: 0.35, blue: 0.36, alpha: 1)
    private let buttonHoverBg = NSColor(calibratedRed: 0.30, green: 0.30, blue: 0.31, alpha: 1)
    private let separatorColor = NSColor(calibratedRed: 0.25, green: 0.25, blue: 0.26, alpha: 1)

    // MARK: - View Lifecycle

    /// Load and configure the view with all UI components
    ///
    /// Creates a 560×240px view with:
    /// - Header (56px) with status dot, title, and View Logs button
    /// - Status area with emoji, text, and model/subtitle labels
    /// - Action buttons (Start/Stop/Restart)
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: W, height: H))
        view.wantsLayer = true
        view.layer?.backgroundColor = bgColor.cgColor
        view.layer?.cornerRadius = 10
        view.layer?.masksToBounds = true
        preferredContentSize = NSSize(width: W, height: H)

        buildHeader()
        buildStatusArea()
        buildActionButtons()
        buildLoadingSpinner()

        // Start with stopped state
        updateState(running: false, model: nil)

        // Show Open Chat button if URL was already set before view loaded
        if chatURL != nil {
            openChatButton.isHidden = false
        }
    }

    // MARK: - UI Building

    private func buildHeader() {
        let header = NSView(frame: NSRect(x: 0, y: H - headerH, width: W, height: headerH))
        header.wantsLayer = true
        header.layer?.backgroundColor = headerColor.cgColor

        // Status dot
        let statusDot = NSView(frame: NSRect(x: padding, y: (headerH - 10) / 2, width: 10, height: 10))
        statusDot.wantsLayer = true
        statusDot.layer?.backgroundColor = accentGreen.cgColor
        statusDot.layer?.cornerRadius = 5
        header.addSubview(statusDot)

        // Title
        let title = NSTextField(labelWithString: "OpenOnion Agent")
        title.frame = NSRect(x: padding + 10 + 12, y: (headerH - 22) / 2, width: 200, height: 22)
        title.font = NSFont.systemFont(ofSize: 16, weight: .semibold)
        title.textColor = textColor
        header.addSubview(title)

        // View Logs button
        let btnW: CGFloat = 90
        let btnH: CGFloat = 32
        viewLogsButton = createButton(
            title: "View Logs",
            x: W - padding - btnW,
            y: (headerH - btnH) / 2,
            width: btnW,
            height: btnH
        )
        viewLogsButton.target = self
        viewLogsButton.action = #selector(handleViewLogs)
        header.addSubview(viewLogsButton)

        // Bottom separator
        let separator = NSView(frame: NSRect(x: 0, y: 0, width: W, height: 1))
        separator.wantsLayer = true
        separator.layer?.backgroundColor = separatorColor.cgColor
        header.addSubview(separator)

        view.addSubview(header)
    }

    private func buildStatusArea() {
        let contentH = H - headerH

        // Status icon (large emoji)
        statusIcon = NSTextField(labelWithString: "💤")
        statusIcon.frame = NSRect(x: (W - 60) / 2, y: contentH / 2 + 20, width: 60, height: 60)
        statusIcon.font = NSFont.systemFont(ofSize: 48)
        statusIcon.alignment = .center
        view.addSubview(statusIcon)

        // Status label
        statusLabel = NSTextField(labelWithString: "Agent is Stopped")
        statusLabel.frame = NSRect(x: padding, y: contentH / 2 - 20, width: W - padding * 2, height: 28)
        statusLabel.font = NSFont.systemFont(ofSize: 22, weight: .bold)
        statusLabel.textColor = textColor
        statusLabel.alignment = .center
        view.addSubview(statusLabel)

        // Model label (shown when running)
        modelLabel = NSTextField(labelWithString: "")
        modelLabel.frame = NSRect(x: padding, y: contentH / 2 - 50, width: W - padding * 2, height: 20)
        modelLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        modelLabel.textColor = subtleTextColor
        modelLabel.alignment = .center
        modelLabel.isHidden = true
        view.addSubview(modelLabel)

        // Subtitle label (shown when stopped)
        subtitleLabel = NSTextField(labelWithString: "Ready to help with your AI tasks")
        subtitleLabel.frame = NSRect(x: padding, y: contentH / 2 - 50, width: W - padding * 2, height: 20)
        subtitleLabel.font = NSFont.systemFont(ofSize: 12, weight: .regular)
        subtitleLabel.textColor = subtleTextColor
        subtitleLabel.alignment = .center
        view.addSubview(subtitleLabel)
    }

    private func buildActionButtons() {
        let contentH = H - headerH
        let btnW: CGFloat = 120
        let btnH: CGFloat = 36
        let btnY = contentH / 2 - 90

        // Primary button (Start/Stop)
        primaryButton = createButton(
            title: "Start Agent",
            x: (W - btnW) / 2,
            y: btnY,
            width: btnW,
            height: btnH
        )
        primaryButton.target = self
        primaryButton.action = #selector(handlePrimaryAction)
        view.addSubview(primaryButton)

        // Restart button (only visible when running)
        restartButton = createButton(
            title: "Restart",
            x: (W - btnW) / 2 + btnW + buttonGap,
            y: btnY,
            width: btnW,
            height: btnH
        )
        restartButton.target = self
        restartButton.action = #selector(handleRestart)
        restartButton.isHidden = true
        view.addSubview(restartButton)

        // Open Chat button (only visible when chat URL is available)
        openChatButton = createButton(
            title: "Open Chat",
            x: (W - btnW) / 2 - 16,
            y: btnY - btnH - buttonGap,
            width: btnW,
            height: btnH
        )
        openChatButton.target = self
        openChatButton.action = #selector(handleOpenChat)
        openChatButton.isHidden = true
        view.addSubview(openChatButton)

        // Copy URL button (small button next to Open Chat)
        let copyBtnW: CGFloat = 28
        copyURLButton = createButton(
            title: "📋",
            x: (W - btnW) / 2 + btnW - 16 + 8,
            y: btnY - btnH - buttonGap,
            width: copyBtnW,
            height: btnH
        )
        copyURLButton.target = self
        copyURLButton.action = #selector(handleCopyURL)
        copyURLButton.isHidden = true
        view.addSubview(copyURLButton)
    }

    private func buildLoadingSpinner() {
        let contentH = H - headerH

        // Spinner
        loadingSpinner = NSProgressIndicator()
        loadingSpinner.style = .spinning
        loadingSpinner.controlSize = .small
        loadingSpinner.frame = NSRect(x: (W - 16) / 2, y: contentH / 2 + 60, width: 16, height: 16)
        loadingSpinner.isHidden = true
        view.addSubview(loadingSpinner)

        // Loading label
        loadingLabel = NSTextField(labelWithString: "")
        loadingLabel.frame = NSRect(x: padding, y: contentH / 2 + 35, width: W - padding * 2, height: 20)
        loadingLabel.font = NSFont.systemFont(ofSize: 12, weight: .regular)
        loadingLabel.textColor = subtleTextColor
        loadingLabel.alignment = .center
        loadingLabel.isHidden = true
        view.addSubview(loadingLabel)
    }

    private func createButton(title: String, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) -> NSButton {
        let btn = HoverButton(frame: NSRect(x: x, y: y, width: width, height: height))
        btn.title = title
        btn.bezelStyle = .rounded
        btn.isBordered = false
        btn.font = NSFont.systemFont(ofSize: 13, weight: .medium)

        btn.wantsLayer = true
        btn.layer?.backgroundColor = buttonBg.cgColor
        btn.layer?.cornerRadius = 6
        btn.layer?.borderWidth = 1
        btn.layer?.borderColor = buttonBorder.cgColor

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let attrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: textColor,
            .font: NSFont.systemFont(ofSize: 13, weight: .medium),
            .paragraphStyle: paragraphStyle
        ]
        btn.attributedTitle = NSAttributedString(string: title, attributes: attrs)

        // Set hover colors
        btn.normalColor = buttonBg
        btn.hoverColor = buttonHoverBg

        return btn
    }

    // MARK: - Actions

    @objc private func handlePrimaryAction() {
        if primaryButton.title == "Stop Agent" {
            showLoading("Stopping agent...")
            onStop?()
        } else {
            showLoading("Starting agent...")
            onStart?()
        }
    }

    @objc private func handleRestart() {
        onRestart?()
    }

    @objc private func handleViewLogs() {
        onViewLogs?()
    }

    @objc private func handleOpenChat() {
        if let url = chatURL {
            onOpenChat?(url)
        }
    }

    @objc private func handleCopyURL() {
        if let url = chatURL {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(url, forType: .string)

            // Brief visual feedback
            let originalTitle = copyURLButton.attributedTitle
            let attrs: [NSAttributedString.Key: Any] = [
                .foregroundColor: accentGreen,
                .font: NSFont.systemFont(ofSize: 13, weight: .medium),
            ]
            copyURLButton.attributedTitle = NSAttributedString(string: "✓", attributes: attrs)

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.copyURLButton.attributedTitle = originalTitle
            }
        }
    }

    // MARK: - Public API

    /// Update the view based on agent running state
    ///
    /// This is the main entry point for state changes. Updates all UI elements
    /// to reflect the current agent status.
    ///
    /// - Parameters:
    ///   - running: Whether the agent is currently running
    ///   - model: Model name if running (e.g. "co/gemini-2.5-pro"), nil if stopped
    ///
    /// ## Running State
    /// - Emoji: ⚡ (lightning bolt)
    /// - Status: "Agent is Running"
    /// - Model: Shows "Connected to {model}"
    /// - Buttons: [Stop Agent] [Restart] (both visible)
    ///
    /// ## Stopped State
    /// - Emoji: 💤 (sleeping)
    /// - Status: "Agent is Stopped"
    /// - Subtitle: "Ready to help with your AI tasks"
    /// - Buttons: [Start Agent] (centered, Restart hidden)
    func updateState(running: Bool, model: String?) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Hide loading spinner when state changes
            self.hideLoading()

            if running {
                // Running state
                self.statusIcon.stringValue = "⚡"
                self.statusLabel.stringValue = "Agent is Running"

                if let model = model {
                    self.modelLabel.stringValue = "Connected to \(model)"
                    self.modelLabel.isHidden = false
                } else {
                    self.modelLabel.isHidden = true
                }

                self.subtitleLabel.isHidden = true

                // Update primary button
                let attrs: [NSAttributedString.Key: Any] = [
                    .foregroundColor: self.textColor,
                    .font: NSFont.systemFont(ofSize: 13, weight: .medium),
                ]
                self.primaryButton.attributedTitle = NSAttributedString(string: "Stop Agent", attributes: attrs)

                // Show restart button (reposition primary button)
                let btnW: CGFloat = 120
                let totalW = btnW * 2 + self.buttonGap

                self.primaryButton.frame.origin.x = (self.W - totalW) / 2
                self.restartButton.frame.origin.x = (self.W - totalW) / 2 + btnW + self.buttonGap
                self.restartButton.isHidden = false

                // Show Open Chat button and copy button if URL is available
                if self.chatURL != nil {
                    self.openChatButton.isHidden = false
                    self.copyURLButton.isHidden = false
                }

            } else {
                // Stopped state
                self.statusIcon.stringValue = "💤"
                self.statusLabel.stringValue = "Agent is Stopped"
                self.modelLabel.isHidden = true
                self.subtitleLabel.isHidden = false

                // Update primary button
                let attrs: [NSAttributedString.Key: Any] = [
                    .foregroundColor: self.textColor,
                    .font: NSFont.systemFont(ofSize: 13, weight: .medium),
                ]
                self.primaryButton.attributedTitle = NSAttributedString(string: "Start Agent", attributes: attrs)

                // Hide restart button (center primary button)
                let btnW: CGFloat = 120
                self.primaryButton.frame.origin.x = (self.W - btnW) / 2
                self.restartButton.isHidden = true

                // Hide Open Chat button and copy button when stopped
                self.openChatButton.isHidden = true
                self.copyURLButton.isHidden = true
            }
        }
    }

    /// Show loading spinner with message
    func showLoading(_ message: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.loadingLabel.stringValue = message
            self.loadingLabel.isHidden = false
            self.loadingSpinner.isHidden = false
            self.loadingSpinner.startAnimation(nil)
        }
    }

    /// Hide loading spinner
    func hideLoading() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.loadingSpinner.stopAnimation(nil)
            self.loadingSpinner.isHidden = true
            self.loadingLabel.isHidden = true
        }
    }

    /// Update chat URL and show/hide Open Chat button
    ///
    /// - Parameter url: Chat URL (e.g., "https://chat.openonion.ai/0xcd92510...")
    func updateChatURL(_ url: String?) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.chatURL = url

            // Only update buttons if view is loaded (buttons exist)
            if self.isViewLoaded {
                self.openChatButton?.isHidden = (url == nil)
                self.copyURLButton?.isHidden = (url == nil)
            }
        }
    }
}

// MARK: - HoverButton

/// Custom button with hover state support
class HoverButton: NSButton {
    var normalColor: NSColor?
    var hoverColor: NSColor?
    private var trackingArea: NSTrackingArea?

    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        if let existing = trackingArea {
            removeTrackingArea(existing)
        }

        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeAlways]
        trackingArea = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        addTrackingArea(trackingArea!)
    }

    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        if let hoverColor = hoverColor {
            layer?.backgroundColor = hoverColor.cgColor
        }
    }

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        if let normalColor = normalColor {
            layer?.backgroundColor = normalColor.cgColor
        }
    }
}
