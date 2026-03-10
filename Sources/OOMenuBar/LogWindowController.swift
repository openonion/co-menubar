import AppKit

/// Log Window Controller
///
/// Manages a separate, resizable window for displaying real-time agent logs with ANSI color support.
/// This window receives stdout/stderr from the `co ai` process and displays it with Rich formatting.
///
/// ## Features
/// - Real-time log streaming from agent process
/// - ANSI color support (parses escape codes)
/// - Clear, Export, Close actions
/// - Shows log file path in toolbar
/// - Resizable window (min 500×300, default 700×500)
///
/// ## Architecture
/// ```
/// Agent.process → stdout/stderr → Pipe
///                                   ↓
/// Agent.onOutput callback → AppDelegate
///                                   ↓
/// LogWindowController.appendOutput → ANSIParser
///                                   ↓
/// NSTextView (with colors!)
/// ```
///
/// ## Usage
/// ```swift
/// let logWindow = LogWindowController()
/// agent.onOutput = { text in
///     logWindow.appendOutput(text)
/// }
/// logWindow.showWindow(nil)
/// ```
///
/// ## Implementation Notes
/// - Does NOT tail log files (receives direct process output)
/// - Uses ANSIParser to convert ANSI codes to NSAttributedString
/// - Singleton pattern recommended (reuse same window)
/// - Auto-scrolls to bottom when new logs arrive
class LogWindowController: NSWindowController {
    /// Text view for displaying logs (monospace font, selectable, non-editable)
    private var textView: NSTextView!

    /// Scroll view containing the text view
    private var scrollView: NSScrollView!

    /// ANSI parser for converting terminal escape codes to attributed strings
    private var ansiParser: ANSIParser!

    // Colors (matching current theme)
    private let bgColor = NSColor(calibratedRed: 0.11, green: 0.11, blue: 0.12, alpha: 0.98)
    private let headerColor = NSColor(calibratedRed: 0.14, green: 0.14, blue: 0.15, alpha: 1)
    private let textColor = NSColor(calibratedRed: 0.83, green: 0.83, blue: 0.84, alpha: 1)
    private let buttonBg = NSColor(calibratedRed: 0.25, green: 0.25, blue: 0.26, alpha: 1)
    private let buttonBorder = NSColor(calibratedRed: 0.35, green: 0.35, blue: 0.36, alpha: 1)
    private let accentGreen = NSColor(calibratedRed: 0.31, green: 0.87, blue: 0.47, alpha: 1)

    /// Initialize log window with default size and configuration
    ///
    /// Creates a standard macOS window with:
    /// - Title: "⚡ OpenOnion Logs"
    /// - Size: 700×500 (resizable, min 500×300)
    /// - Style: Titled, closable, resizable, miniaturizable
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 500),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "⚡ OpenOnion Logs"
        window.minSize = NSSize(width: 500, height: 300)

        self.init(window: window)
        setupUI()
    }

    private func setupUI() {
        guard let window = window else { return }

        let contentView = NSView(frame: window.contentView!.bounds)
        contentView.autoresizingMask = [.width, .height]
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = bgColor.cgColor

        buildToolbar(in: contentView)
        buildScrollView(in: contentView)

        window.contentView = contentView

        // Initialize ANSI parser
        let monoFont = NSFont(name: "SF Mono", size: 12) ?? NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        ansiParser = ANSIParser(defaultTextColor: textColor, defaultFont: monoFont)

        // Add initial message
        appendOutput("Waiting for logs from co ai...\n")
    }

    private func buildToolbar(in container: NSView) {
        let toolbarH: CGFloat = 44
        let toolbar = NSView(frame: NSRect(x: 0, y: container.bounds.height - toolbarH, width: container.bounds.width, height: toolbarH))
        toolbar.autoresizingMask = [.width, .minYMargin]
        toolbar.wantsLayer = true
        toolbar.layer?.backgroundColor = headerColor.cgColor

        let padding: CGFloat = 12
        let btnW: CGFloat = 70
        let btnH: CGFloat = 28
        let btnGap: CGFloat = 8

        // Clear button (left side)
        let clearBtn = createButton(title: "Clear", x: padding, y: (toolbarH - btnH) / 2, width: btnW, height: btnH)
        clearBtn.target = self
        clearBtn.action = #selector(clearLogs)
        toolbar.addSubview(clearBtn)

        // Export button (next to clear)
        let exportBtn = createButton(title: "Export", x: padding + btnW + btnGap, y: (toolbarH - btnH) / 2, width: btnW, height: btnH)
        exportBtn.target = self
        exportBtn.action = #selector(exportLogs)
        toolbar.addSubview(exportBtn)

        // Log path label (center) - shows where logs are stored
        let logPath = NSHomeDirectory() + "/.co/logs/oo.log"
        let logPathLabel = NSTextField(labelWithString: "📁 \(logPath)")
        logPathLabel.font = NSFont.systemFont(ofSize: 10, weight: .regular)
        logPathLabel.textColor = NSColor(calibratedRed: 0.5, green: 0.5, blue: 0.51, alpha: 1)
        logPathLabel.alignment = .center
        let labelW: CGFloat = 400
        logPathLabel.frame = NSRect(x: (toolbar.bounds.width - labelW) / 2, y: (toolbarH - 16) / 2, width: labelW, height: 16)
        logPathLabel.autoresizingMask = [.minXMargin, .maxXMargin]
        logPathLabel.lineBreakMode = .byTruncatingMiddle
        toolbar.addSubview(logPathLabel)

        // Close button (right side)
        let closeBtn = createButton(title: "Close", x: toolbar.bounds.width - padding - btnW, y: (toolbarH - btnH) / 2, width: btnW, height: btnH)
        closeBtn.autoresizingMask = [.minXMargin]
        closeBtn.target = self
        closeBtn.action = #selector(closeWindow)
        toolbar.addSubview(closeBtn)

        container.addSubview(toolbar)
    }

    private func buildScrollView(in container: NSView) {
        let toolbarH: CGFloat = 44
        let scrollH = container.bounds.height - toolbarH

        scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: container.bounds.width, height: scrollH))
        scrollView.autoresizingMask = [.width, .height]
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
        container.addSubview(scrollView)
    }

    private func createButton(title: String, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) -> NSButton {
        let btn = NSButton(frame: NSRect(x: x, y: y, width: width, height: height))
        btn.title = title
        btn.bezelStyle = .rounded
        btn.isBordered = false
        btn.font = NSFont.systemFont(ofSize: 12, weight: .medium)

        btn.wantsLayer = true
        btn.layer?.backgroundColor = buttonBg.cgColor
        btn.layer?.cornerRadius = 5
        btn.layer?.borderWidth = 1
        btn.layer?.borderColor = buttonBorder.cgColor

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let attrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: textColor,
            .font: NSFont.systemFont(ofSize: 12, weight: .medium),
            .paragraphStyle: paragraphStyle
        ]
        btn.attributedTitle = NSAttributedString(string: title, attributes: attrs)

        return btn
    }


    // MARK: - Actions

    /// Clear button action - removes all logs and shows cleared message
    @objc private func clearLogs() {
        clear()
        appendOutput("Logs cleared. Waiting for output from co ai...\n")
    }

    /// Export button action - opens save panel to export logs as text file
    @objc private func exportLogs() {
        let savePanel = NSSavePanel()
        savePanel.title = "Export Logs"
        savePanel.nameFieldStringValue = "oo-logs.txt"
        savePanel.canCreateDirectories = true

        savePanel.begin { [weak self] response in
            guard response == .OK, let url = savePanel.url, let self = self else { return }
            do {
                try self.textView.string.write(to: url, atomically: true, encoding: .utf8)
            } catch {
                let alert = NSAlert()
                alert.messageText = "Export Failed"
                alert.informativeText = error.localizedDescription
                alert.alertStyle = .warning
                alert.runModal()
            }
        }
    }

    /// Close button action - closes the log window
    @objc private func closeWindow() {
        window?.close()
    }

    // MARK: - Public API

    /// Append new output to the log view with ANSI color parsing
    ///
    /// This is the main entry point for new log data. Text with ANSI escape codes
    /// is parsed and displayed with colors, bold, etc.
    ///
    /// - Parameter text: Raw text from agent output (may contain ANSI codes)
    ///
    /// ## Example
    /// ```swift
    /// logWindow.appendOutput("\u{1B}[32mSuccess!\u{1B}[0m\n")
    /// // Displays "Success!" in green
    /// ```
    func appendOutput(_ text: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Parse ANSI codes and convert to attributed string with colors
            let attrString = self.ansiParser.parse(text)
            self.textView.textStorage?.append(attrString)
            self.textView.scrollToEndOfDocument(nil)
        }
    }

    /// Clear all logs from the text view
    func clear() {
        DispatchQueue.main.async { [weak self] in
            self?.textView.string = ""
        }
    }
}
