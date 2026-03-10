import AppKit

// Modern log viewer with VS Code-inspired design
class PopoverController: NSViewController {
    private var textView: NSTextView!
    private var scrollView: NSScrollView!
    private var startStopButton: NSButton!
    private var statusDot: NSView!
    private let logTailer = LogTailer()

    var onStart: (() -> Void)?
    var onStop: (() -> Void)?

    // Modern color scheme
    private let bgColor = NSColor(calibratedRed: 0.11, green: 0.11, blue: 0.12, alpha: 0.98)
    private let headerColor = NSColor(calibratedRed: 0.14, green: 0.14, blue: 0.15, alpha: 1)
    private let textColor = NSColor(calibratedRed: 0.83, green: 0.83, blue: 0.84, alpha: 1)
    private let accentGreen = NSColor(calibratedRed: 0.31, green: 0.87, blue: 0.47, alpha: 1)
    private let accentRed = NSColor(calibratedRed: 0.96, green: 0.35, blue: 0.35, alpha: 1)
    private let buttonBg = NSColor(calibratedRed: 0.25, green: 0.25, blue: 0.26, alpha: 1)
    private let buttonBorder = NSColor(calibratedRed: 0.35, green: 0.35, blue: 0.36, alpha: 1)
    private let separatorColor = NSColor(calibratedRed: 0.25, green: 0.25, blue: 0.26, alpha: 1)

    private let W: CGFloat = 560
    private let H: CGFloat = 420
    private let headerH: CGFloat = 56  // 8px grid: 56 = 7 * 8

    // MARK: - View Loading

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: W, height: H))
        view.wantsLayer = true
        view.layer?.backgroundColor = bgColor.cgColor
        view.layer?.cornerRadius = 10
        view.layer?.masksToBounds = true
        preferredContentSize = NSSize(width: W, height: H)

        buildHeader()
        buildScrollView()
        startTailingLogs()

        // Add initial message
        appendOutput("Waiting for logs from co ai...\n")
    }

    private func buildHeader() {
        let header = NSView(frame: NSRect(x: 0, y: H - headerH, width: W, height: headerH))
        header.wantsLayer = true
        header.layer?.backgroundColor = headerColor.cgColor

        let padding: CGFloat = 16  // 8px grid

        // Status indicator (larger, more visible)
        statusDot = NSView(frame: NSRect(x: padding, y: (headerH - 10) / 2, width: 10, height: 10))
        statusDot.wantsLayer = true
        statusDot.layer?.backgroundColor = accentRed.cgColor
        statusDot.layer?.cornerRadius = 5
        header.addSubview(statusDot)

        // Title (larger, clearer hierarchy)
        let title = NSTextField(labelWithString: "OpenOnion Logs")
        title.frame = NSRect(x: padding + 10 + 12, y: (headerH - 22) / 2, width: 200, height: 22)
        title.font = NSFont.systemFont(ofSize: 16, weight: .semibold)
        title.textColor = textColor
        header.addSubview(title)

        // Button spacing: 8px grid
        let btnW: CGFloat = 80
        let btnH: CGFloat = 32
        let btnGap: CGFloat = 8

        // Start/Stop button (primary action, rightmost)
        startStopButton = createButton(title: "Start", x: W - padding - btnW, y: (headerH - btnH) / 2, width: btnW, height: btnH)
        startStopButton.target = self
        startStopButton.action = #selector(toggleAgent)
        header.addSubview(startStopButton)

        // Clear button (secondary, left of primary)
        let clearBtn = createButton(title: "Clear", x: W - padding - btnW * 2 - btnGap, y: (headerH - btnH) / 2, width: btnW, height: btnH)
        clearBtn.target = self
        clearBtn.action = #selector(clearOutput)
        header.addSubview(clearBtn)

        // Bottom separator line
        let separator = NSView(frame: NSRect(x: 0, y: 0, width: W, height: 1))
        separator.wantsLayer = true
        separator.layer?.backgroundColor = separatorColor.cgColor
        header.addSubview(separator)

        view.addSubview(header)
    }

    private func createButton(title: String, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) -> NSButton {
        let btn = NSButton(frame: NSRect(x: x, y: y, width: width, height: height))
        btn.title = title
        btn.bezelStyle = .rounded
        btn.isBordered = false
        btn.font = NSFont.systemFont(ofSize: 13, weight: .medium)

        // Custom appearance with border
        btn.wantsLayer = true
        btn.layer?.backgroundColor = buttonBg.cgColor
        btn.layer?.cornerRadius = 6
        btn.layer?.borderWidth = 1
        btn.layer?.borderColor = buttonBorder.cgColor

        // Set text color
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let attrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: textColor,
            .font: NSFont.systemFont(ofSize: 13, weight: .medium),
            .paragraphStyle: paragraphStyle
        ]
        btn.attributedTitle = NSAttributedString(string: title, attributes: attrs)

        return btn
    }

    private func buildScrollView() {
        let scrollH = H - headerH
        scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: W, height: scrollH))
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.backgroundColor = bgColor
        scrollView.drawsBackground = true
        scrollView.borderType = .noBorder

        let contentW = scrollView.contentSize.width
        textView = NSTextView(frame: NSRect(x: 0, y: 0, width: contentW, height: scrollView.contentSize.height))
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.infinity, height: CGFloat.infinity)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.containerSize = NSSize(width: contentW, height: CGFloat.infinity)
        textView.textContainer?.widthTracksTextView = true
        textView.textContainerInset = NSSize(width: 16, height: 12)

        textView.isEditable = false
        textView.isSelectable = true
        textView.backgroundColor = bgColor
        textView.font = NSFont(name: "SF Mono", size: 12) ?? NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.textColor = textColor
        textView.insertionPointColor = accentGreen

        scrollView.documentView = textView
        view.addSubview(scrollView)
    }

    private func startTailingLogs() {
        let logPath = NSHomeDirectory() + "/.co/logs/oo.log"
        logTailer.onNewLines = { [weak self] text in
            self?.appendOutput(text)
        }
        logTailer.start(path: logPath)
    }

    deinit {
        logTailer.stop()
    }

    // MARK: - Actions

    @objc private func toggleAgent() {
        if startStopButton.title == "Stop" {
            onStop?()
        } else {
            onStart?()
        }
    }

    @objc private func clearOutput() {
        textView.string = ""
        appendOutput("Logs cleared. Waiting for co ai...\n")
    }

    // MARK: - Public API

    func updateState(running: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let title = running ? "Stop" : "Start"
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            let attrs: [NSAttributedString.Key: Any] = [
                .foregroundColor: self.textColor,
                .font: NSFont.systemFont(ofSize: 13, weight: .medium),
                .paragraphStyle: paragraphStyle
            ]
            self.startStopButton.attributedTitle = NSAttributedString(string: title, attributes: attrs)

            // Animate status dot
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.3
                self.statusDot.layer?.backgroundColor = running ? self.accentGreen.cgColor : self.accentRed.cgColor
            }
        }
    }

    func appendOutput(_ text: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let attrs: [NSAttributedString.Key: Any] = [
                .foregroundColor: self.textColor,
                .font: NSFont(name: "SF Mono", size: 12) ?? NSFont.monospacedSystemFont(ofSize: 12, weight: .regular),
            ]

            let attrString = NSAttributedString(string: text, attributes: attrs)
            self.textView.textStorage?.append(attrString)
            self.textView.scrollToEndOfDocument(nil)
        }
    }
}
