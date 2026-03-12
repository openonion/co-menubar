import AppKit

/// Main Status View Controller - Polished Native macOS Style
///
/// Displays an elegant, WiFi/iStat-inspired menu bar popover interface.
/// All actions are visible in the main view (no right-click required).
///
/// ## UI Layout (280×420px - taller, narrower)
/// ```
/// ┌─────────────────────────────────┐
/// │                                 │
/// │     ⚡ Agent is Running          │ ← Large, centered
/// │     co/gemini-2.5-pro           │ ← Subtitle
/// │                                 │
/// │  ╭───────────────────────────╮  │
/// │  │ Uptime     2h 34m         │  │ ← Stats card
/// │  │ Requests   47 completed   │  │
/// │  ╰───────────────────────────╯  │
/// │                                 │
/// │  🌐  Open Chat            →     │ ← Menu items
/// │  📋  View Logs            →     │
/// │  ⚙️   Settings            →     │
/// │                                 │
/// │  ───────────────────────────    │
/// │                                 │
/// │  ⏸   Stop Agent                 │ ← Controls
/// │  🔄  Restart Agent              │
/// │                                 │
/// │  ───────────────────────────    │
/// │  Quit OpenOnion          ⌘Q     │
/// └─────────────────────────────────┘
/// ```
///
/// ## Design Principles
/// - **Native macOS style**: Follows WiFi/Bluetooth/iStat Menus patterns
/// - **All actions visible**: No important features hidden in right-click
/// - **Clean typography**: Font weights and sizes create hierarchy
/// - **Hover effects**: Subtle background on menu items
/// - **Proper spacing**: Generous padding, breathing room
/// - **Progressive disclosure**: Stats card only shown when running
class MainViewController: NSViewController {

    // MARK: - UI Components

    /// Large centered status text (e.g., "⚡ Agent is Running")
    private var statusLabel: NSTextField!

    /// Subtitle with model name (e.g., "co/gemini-2.5-pro")
    private var modelLabel: NSTextField!

    /// Stats card background
    private var statsCard: NSBox!

    /// Uptime label
    private var uptimeLabel: NSTextField!

    /// Requests count label
    private var requestsLabel: NSTextField!

    /// Menu items (with hover effects)
    private var openChatItem: HoverButton!
    private var viewLogsItem: HoverButton!
    private var settingsItem: HoverButton!

    /// Control buttons
    private var stopButton: HoverButton!
    private var restartButton: HoverButton!

    /// Quit button at bottom
    private var quitButton: NSButton!

    /// Loading indicator
    private var loadingSpinner: NSProgressIndicator!
    private var loadingLabel: NSTextField!

    // MARK: - State

    private var isRunning = false
    private var chatURL: String?
    private var uptime: String?
    private var requestCount: Int = 0

    // MARK: - Callbacks

    var onStart: (() -> Void)?
    var onStop: (() -> Void)?
    var onRestart: (() -> Void)?
    var onViewLogs: (() -> Void)?
    var onOpenChat: ((String) -> Void)?
    var onSettings: (() -> Void)?
    var onQuit: (() -> Void)?

    // MARK: - Layout Constants

    private let W: CGFloat = 280
    private let H: CGFloat = 420
    private let padding: CGFloat = 20
    private let itemHeight: CGFloat = 32
    private let spacing: CGFloat = 12

    // MARK: - Colors (Redesigned)

    private let bgColor = NSColor(calibratedRed: 0.09, green: 0.09, blue: 0.11, alpha: 0.98)
    private let cardBgColor = NSColor(calibratedRed: 0.13, green: 0.13, blue: 0.16, alpha: 1.0)
    private let textColor = NSColor.white
    private let subtleTextColor = NSColor(calibratedRed: 0.70, green: 0.70, blue: 0.75, alpha: 1.0)
    private let separatorColor = NSColor(calibratedRed: 0.22, green: 0.22, blue: 0.25, alpha: 1.0)
    private let hoverColor = NSColor(calibratedRed: 0.18, green: 0.18, blue: 0.22, alpha: 1.0)

    // Status colors
    private let runningColor = NSColor(calibratedRed: 0.30, green: 0.85, blue: 0.45, alpha: 1.0)  // Green
    private let stoppedColor = NSColor(calibratedRed: 0.60, green: 0.60, blue: 0.65, alpha: 1.0)  // Gray
    private let accentColor = NSColor(calibratedRed: 0.40, green: 0.60, blue: 1.0, alpha: 1.0)   // Blue

    // MARK: - Lifecycle

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: W, height: H))
        view.wantsLayer = true
        view.layer?.backgroundColor = bgColor.cgColor
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        buildUI()
    }

    // MARK: - Build UI

    private func buildUI() {
        var y: CGFloat = H - padding

        // Status label (larger, more prominent)
        y -= 45
        statusLabel = createLabel(
            text: "💤 Agent is Stopped",
            fontSize: 20,
            weight: .bold,
            color: textColor,
            alignment: .center
        )
        statusLabel.frame = NSRect(x: padding, y: y, width: W - padding * 2, height: 32)
        view.addSubview(statusLabel)

        // Model label (centered subtitle, slightly larger)
        y -= 24
        modelLabel = createLabel(
            text: "Ready to help with AI tasks",
            fontSize: 13,
            weight: .regular,
            color: subtleTextColor,
            alignment: .center
        )
        modelLabel.frame = NSRect(x: padding, y: y, width: W - padding * 2, height: 20)
        view.addSubview(modelLabel)

        // Stats card (improved styling)
        y -= spacing + 60
        statsCard = NSBox()
        statsCard.boxType = .custom
        statsCard.isTransparent = false
        statsCard.fillColor = cardBgColor
        statsCard.cornerRadius = 10
        statsCard.frame = NSRect(x: padding, y: y, width: W - padding * 2, height: 60)
        statsCard.isHidden = true // Hidden when stopped
        view.addSubview(statsCard)

        // Uptime label (inside card, better hierarchy)
        uptimeLabel = createLabel(text: "Uptime     --", fontSize: 13, weight: .medium, color: textColor)
        uptimeLabel.frame = NSRect(x: 16, y: 30, width: statsCard.frame.width - 32, height: 18)
        statsCard.addSubview(uptimeLabel)

        // Requests label (inside card, better hierarchy)
        requestsLabel = createLabel(text: "Requests   0 completed", fontSize: 13, weight: .medium, color: textColor)
        requestsLabel.frame = NSRect(x: 16, y: 10, width: statsCard.frame.width - 32, height: 18)
        statsCard.addSubview(requestsLabel)

        // Menu items section
        y -= spacing * 2

        // Open Chat item (with accent color)
        y -= itemHeight
        openChatItem = HoverButton(
            title: "Open Chat in Browser",
            fontSize: 13,
            hoverColor: accentColor.withAlphaComponent(0.15),
            textColor: accentColor
        )
        openChatItem.frame = NSRect(x: padding, y: y, width: W - padding * 2, height: itemHeight)
        openChatItem.target = self
        openChatItem.action = #selector(openChatAction)
        openChatItem.isHidden = true // Hidden until chat URL available
        view.addSubview(openChatItem)

        // View Logs item
        y -= itemHeight + 4
        viewLogsItem = HoverButton(
            title: "View Logs",
            fontSize: 13,
            hoverColor: hoverColor,
            textColor: textColor
        )
        viewLogsItem.frame = NSRect(x: padding, y: y, width: W - padding * 2, height: itemHeight)
        viewLogsItem.target = self
        viewLogsItem.action = #selector(viewLogsAction)
        view.addSubview(viewLogsItem)

        // Settings item
        y -= itemHeight + 4
        settingsItem = HoverButton(
            title: "Settings",
            fontSize: 13,
            hoverColor: hoverColor,
            textColor: textColor
        )
        settingsItem.frame = NSRect(x: padding, y: y, width: W - padding * 2, height: itemHeight)
        settingsItem.target = self
        settingsItem.action = #selector(settingsAction)
        view.addSubview(settingsItem)

        // Separator
        y -= spacing
        let separator1 = createSeparator(y: y)
        view.addSubview(separator1)

        // Control buttons section
        y -= spacing

        // Stop/Start button
        y -= itemHeight
        stopButton = HoverButton(
            title: "Start Agent",
            fontSize: 13,
            hoverColor: hoverColor,
            textColor: textColor
        )
        stopButton.frame = NSRect(x: padding, y: y, width: W - padding * 2, height: itemHeight)
        stopButton.target = self
        stopButton.action = #selector(toggleAgentAction)
        view.addSubview(stopButton)

        // Restart button
        y -= itemHeight + 4
        restartButton = HoverButton(
            title: "Restart Agent",
            fontSize: 13,
            hoverColor: hoverColor,
            textColor: textColor
        )
        restartButton.frame = NSRect(x: padding, y: y, width: W - padding * 2, height: itemHeight)
        restartButton.target = self
        restartButton.action = #selector(restartAction)
        restartButton.isHidden = true // Hidden when stopped
        view.addSubview(restartButton)

        // Separator
        y -= spacing
        let separator2 = createSeparator(y: y)
        view.addSubview(separator2)

        // Quit button at bottom
        y -= spacing + itemHeight
        quitButton = NSButton(frame: NSRect(x: padding, y: y, width: W - padding * 2, height: itemHeight))
        quitButton.title = "Quit OpenOnion"
        quitButton.bezelStyle = .rounded
        quitButton.isBordered = false
        quitButton.font = NSFont.systemFont(ofSize: 13, weight: .regular)
        quitButton.contentTintColor = subtleTextColor
        quitButton.alignment = .center
        quitButton.target = self
        quitButton.action = #selector(quitAction)
        quitButton.keyEquivalent = "q"
        quitButton.keyEquivalentModifierMask = .command
        view.addSubview(quitButton)

        // Loading indicator (centered, initially hidden)
        loadingSpinner = NSProgressIndicator()
        loadingSpinner.style = .spinning
        loadingSpinner.controlSize = .regular
        loadingSpinner.isHidden = true
        loadingSpinner.frame = NSRect(x: W / 2 - 16, y: H / 2 + 20, width: 32, height: 32)
        view.addSubview(loadingSpinner)

        loadingLabel = createLabel(
            text: "Starting agent...",
            fontSize: 13,
            weight: .regular,
            color: subtleTextColor,
            alignment: .center
        )
        loadingLabel.frame = NSRect(x: padding, y: H / 2 - 10, width: W - padding * 2, height: 18)
        loadingLabel.isHidden = true
        view.addSubview(loadingLabel)
    }

    // MARK: - Helper Functions

    private func createLabel(
        text: String,
        fontSize: CGFloat,
        weight: NSFont.Weight,
        color: NSColor,
        alignment: NSTextAlignment = .left
    ) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = NSFont.systemFont(ofSize: fontSize, weight: weight)
        label.textColor = color
        label.alignment = alignment
        label.isBezeled = false
        label.drawsBackground = false
        label.isEditable = false
        label.isSelectable = false
        return label
    }

    private func createSeparator(y: CGFloat) -> NSBox {
        let separator = NSBox()
        separator.boxType = .separator
        separator.frame = NSRect(x: padding, y: y, width: W - padding * 2, height: 1)
        return separator
    }

    // MARK: - Actions

    @objc private func toggleAgentAction() {
        if isRunning {
            showLoading(message: "Stopping agent...")
            onStop?()
        } else {
            showLoading(message: "Starting agent...")
            onStart?()
        }
    }

    @objc private func restartAction() {
        showLoading(message: "Restarting agent...")
        onRestart?()
    }

    @objc private func viewLogsAction() {
        onViewLogs?()
    }

    @objc private func openChatAction() {
        if let url = chatURL {
            onOpenChat?(url)
        }
    }

    @objc private func settingsAction() {
        onSettings?()
    }

    @objc private func quitAction() {
        onQuit?()
    }

    // MARK: - State Updates

    func updateState(running: Bool, model: String?) {
        isRunning = running

        if running {
            statusLabel.stringValue = "Agent is Running"
            statusLabel.textColor = runningColor  // Green
            modelLabel.stringValue = model ?? "co/gemini-2.5-pro"
            modelLabel.textColor = subtleTextColor
            stopButton.setTitle("Stop Agent")
            stopButton.contentTintColor = subtleTextColor
            restartButton.isHidden = false
            statsCard.isHidden = false
            statsCard.borderColor = runningColor.withAlphaComponent(0.3)
            statsCard.borderWidth = 1
        } else {
            statusLabel.stringValue = "Agent is Stopped"
            statusLabel.textColor = stoppedColor  // Gray
            modelLabel.stringValue = "Ready to help with AI tasks"
            modelLabel.textColor = subtleTextColor
            stopButton.setTitle("Start Agent")
            stopButton.contentTintColor = accentColor
            restartButton.isHidden = true
            statsCard.isHidden = true
        }

        hideLoading()
    }

    func updateChatURL(_ url: String?) {
        chatURL = url
        if isViewLoaded {
            openChatItem.isHidden = (url == nil)
        }
    }

    func updateModel(_ model: String) {
        if isViewLoaded && isRunning {
            modelLabel.stringValue = model
        }
    }

    func updateStats(uptime: String?, requests: Int) {
        self.uptime = uptime
        self.requestCount = requests

        if let uptime = uptime {
            uptimeLabel.stringValue = "Uptime     \(uptime)"
        } else {
            uptimeLabel.stringValue = "Uptime     --"
        }

        requestsLabel.stringValue = "Requests   \(requests) completed"
    }

    // MARK: - Loading State

    private func showLoading(message: String) {
        loadingSpinner.isHidden = false
        loadingSpinner.startAnimation(nil)
        loadingLabel.stringValue = message
        loadingLabel.isHidden = false

        // Disable buttons during loading
        stopButton.isEnabled = false
        restartButton.isEnabled = false
    }

    private func hideLoading() {
        loadingSpinner.isHidden = true
        loadingSpinner.stopAnimation(nil)
        loadingLabel.isHidden = true

        // Re-enable buttons
        stopButton.isEnabled = true
        restartButton.isEnabled = true
    }
}

// MARK: - HoverButton (Custom Button with Hover Effect)

/// A custom button that shows a subtle background on hover (like native macOS menus)
class HoverButton: NSButton {

    private var hoverColor: NSColor
    private var defaultTextColor: NSColor
    private var trackingArea: NSTrackingArea?
    private var isHovered = false

    init(title: String, fontSize: CGFloat, hoverColor: NSColor, textColor: NSColor) {
        self.hoverColor = hoverColor
        self.defaultTextColor = textColor
        super.init(frame: .zero)

        self.title = title
        self.font = NSFont.systemFont(ofSize: fontSize, weight: .regular)
        self.contentTintColor = textColor
        self.alignment = .left
        self.isBordered = false
        self.bezelStyle = .rounded
        self.wantsLayer = true
        self.layer?.cornerRadius = 6
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    func setTitle(_ newTitle: String) {
        self.title = newTitle
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        if let area = trackingArea {
            removeTrackingArea(area)
        }

        trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeInKeyWindow],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea!)
    }

    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        isHovered = true
        layer?.backgroundColor = hoverColor.cgColor
    }

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        isHovered = false
        layer?.backgroundColor = .clear
    }

    override func mouseDown(with event: NSEvent) {
        // Slightly darker on click
        layer?.backgroundColor = hoverColor.blended(withFraction: 0.3, of: .black)?.cgColor
        super.mouseDown(with: event)
    }

    override func mouseUp(with event: NSEvent) {
        // Return to hover state if still hovering
        layer?.backgroundColor = isHovered ? hoverColor.cgColor : .clear
        super.mouseUp(with: event)
    }
}
