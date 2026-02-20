import AppKit

// Terminal-style popover: dark output view + input field at bottom.
// Fixed size: 440 x 360.
class PopoverController: NSViewController {
    private var textView: NSTextView!
    private var scrollView: NSScrollView!
    private var inputField: NSTextField!
    private var startStopButton: NSButton!
    private var statusDot: NSTextField!

    var onStart: (() -> Void)?
    var onStop: (() -> Void)?
    var onSend: ((String) -> Void)?

    private let bg = NSColor(calibratedRed: 0.08, green: 0.08, blue: 0.10, alpha: 1)
    private let headerBg = NSColor(calibratedRed: 0.12, green: 0.12, blue: 0.15, alpha: 1)
    private let inputBg = NSColor(calibratedRed: 0.10, green: 0.10, blue: 0.12, alpha: 1)
    private let green = NSColor(calibratedRed: 0.50, green: 1.00, blue: 0.60, alpha: 1)
    private let dimGreen = NSColor(calibratedRed: 0.80, green: 1.00, blue: 0.85, alpha: 1)

    private let W: CGFloat = 440
    private let H: CGFloat = 360
    private let headerH: CGFloat = 40
    private let inputH: CGFloat = 44

    // MARK: - View Loading

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: W, height: H))
        view.wantsLayer = true
        view.layer?.backgroundColor = bg.cgColor
        preferredContentSize = NSSize(width: W, height: H)

        buildHeader()
        buildScrollView()
        buildInputRow()
    }

    private func buildHeader() {
        let header = NSView(frame: NSRect(x: 0, y: H - headerH, width: W, height: headerH))
        header.wantsLayer = true
        header.layer?.backgroundColor = headerBg.cgColor

        statusDot = NSTextField(labelWithString: "●")
        statusDot.frame = NSRect(x: 12, y: 13, width: 12, height: 14)
        statusDot.font = NSFont.systemFont(ofSize: 10)
        statusDot.textColor = .gray
        header.addSubview(statusDot)

        let title = NSTextField(labelWithString: "co ai")
        title.frame = NSRect(x: 28, y: 11, width: 80, height: 18)
        title.font = NSFont.boldSystemFont(ofSize: 13)
        title.textColor = .white
        header.addSubview(title)

        let clearBtn = NSButton(frame: NSRect(x: W - 115, y: 9, width: 50, height: 22))
        clearBtn.title = "Clear"
        clearBtn.bezelStyle = .rounded
        clearBtn.controlSize = .small
        clearBtn.target = self
        clearBtn.action = #selector(clearOutput)
        header.addSubview(clearBtn)

        startStopButton = NSButton(frame: NSRect(x: W - 60, y: 9, width: 48, height: 22))
        startStopButton.title = "Start"
        startStopButton.bezelStyle = .rounded
        startStopButton.controlSize = .small
        startStopButton.target = self
        startStopButton.action = #selector(toggleAgent)
        header.addSubview(startStopButton)

        view.addSubview(header)
    }

    private func buildScrollView() {
        let scrollH = H - headerH - inputH
        scrollView = NSScrollView(frame: NSRect(x: 0, y: inputH, width: W, height: scrollH))
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.backgroundColor = bg
        scrollView.drawsBackground = true

        let contentW = scrollView.contentSize.width
        textView = NSTextView(frame: NSRect(x: 0, y: 0, width: contentW, height: scrollView.contentSize.height))
        textView.minSize = NSSize(width: 0, height: scrollView.contentSize.height)
        textView.maxSize = NSSize(width: CGFloat.infinity, height: CGFloat.infinity)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.containerSize = NSSize(width: contentW, height: CGFloat.infinity)
        textView.textContainer?.widthTracksTextView = true
        textView.textContainerInset = NSSize(width: 10, height: 10)

        textView.isEditable = false
        textView.isSelectable = true
        textView.backgroundColor = bg
        textView.font = NSFont.monospacedSystemFont(ofSize: 11.5, weight: .regular)
        textView.textColor = dimGreen

        scrollView.documentView = textView
        view.addSubview(scrollView)
    }

    private func buildInputRow() {
        let row = NSView(frame: NSRect(x: 0, y: 0, width: W, height: inputH))
        row.wantsLayer = true
        row.layer?.backgroundColor = inputBg.cgColor

        // 1px separator at top
        let sep = NSView(frame: NSRect(x: 0, y: inputH - 1, width: W, height: 1))
        sep.wantsLayer = true
        sep.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.08).cgColor
        row.addSubview(sep)

        // Input container (rounded dark pill)
        let containerX: CGFloat = 10
        let containerW: CGFloat = W - 10 - 36 - 8
        let container = NSView(frame: NSRect(x: containerX, y: 9, width: containerW, height: 26))
        container.wantsLayer = true
        container.layer?.cornerRadius = 6
        container.layer?.backgroundColor = NSColor(calibratedRed: 0.18, green: 0.18, blue: 0.20, alpha: 1).cgColor
        row.addSubview(container)

        inputField = NSTextField(frame: NSRect(x: 6, y: 3, width: containerW - 12, height: 20))
        inputField.placeholderString = "Message co ai..."
        inputField.backgroundColor = .clear
        inputField.textColor = .white
        inputField.font = NSFont.monospacedSystemFont(ofSize: 11.5, weight: .regular)
        inputField.focusRingType = .none
        inputField.isBordered = false
        inputField.isBezeled = false
        inputField.isEditable = false
        inputField.target = self
        inputField.action = #selector(sendInput)
        container.addSubview(inputField)

        // Send button
        let sendBtn = NSButton(frame: NSRect(x: W - 10 - 28, y: 8, width: 28, height: 28))
        if let img = NSImage(systemSymbolName: "arrow.up.circle.fill", accessibilityDescription: "Send") {
            sendBtn.image = img
        } else {
            sendBtn.title = "↑"
        }
        sendBtn.bezelStyle = .inline
        sendBtn.isBordered = false
        sendBtn.contentTintColor = green
        sendBtn.target = self
        sendBtn.action = #selector(sendInput)
        row.addSubview(sendBtn)

        view.addSubview(row)
    }

    // MARK: - Actions

    @objc private func toggleAgent() {
        if startStopButton.title == "Stop" {
            onStop?()
        } else {
            onStart?()
        }
    }

    @objc private func sendInput() {
        let text = inputField.stringValue.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        inputField.stringValue = ""
        onSend?(text)
    }

    @objc private func clearOutput() {
        textView.string = ""
    }

    // MARK: - Public API

    func updateState(running: Bool) {
        startStopButton.title = running ? "Stop" : "Start"
        statusDot.textColor = running ? green : .gray
        inputField.isEditable = running
    }

    func appendOutput(_ text: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let attrs: [NSAttributedString.Key: Any] = [
                .foregroundColor: self.dimGreen,
                .font: NSFont.monospacedSystemFont(ofSize: 11.5, weight: .regular),
            ]
            self.textView.textStorage?.append(NSAttributedString(string: text, attributes: attrs))
            self.textView.scrollToEndOfDocument(nil)
        }
    }

    func focusInput() {
        view.window?.makeFirstResponder(inputField)
    }
}
