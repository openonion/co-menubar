import AppKit

/// Settings Window Controller
///
/// Provides a tabbed interface for configuring the OO MenuBar app.
///
/// ## Tabs
/// 1. **General**: Default model, .co folder location, auto-start
/// 2. **Keys & Auth**: View/edit .env file, agent private key
/// 3. **Advanced**: Logs path, custom co binary, debug mode
///
/// ## Design
/// - Native macOS preferences window style
/// - Tab view for organized settings
/// - Form-style layout with labels and controls
/// - Save/Cancel buttons
class SettingsWindowController: NSWindowController {

    private var tabView: NSTabView!
    private var saveButton: NSButton!
    private var cancelButton: NSButton!

    // General tab controls
    private var modelPopup: NSPopUpButton!
    private var coFolderField: NSTextField!
    private var browseFolderButton: NSButton!
    private var autoStartCheckbox: NSButton!
    private var showStatsCheckbox: NSButton!

    // Keys & Auth tab controls
    private var envTextView: NSTextView!
    private var agentKeyField: NSTextField!
    private var regenerateKeyButton: NSButton!

    // Advanced tab controls
    private var logsPathField: NSTextField!
    private var browseLogsButton: NSButton!
    private var customBinaryField: NSTextField!
    private var browseBinaryButton: NSButton!
    private var debugModeCheckbox: NSButton!

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Settings"
        window.center()

        self.init(window: window)
        setupUI()
        loadSettings()
    }

    private func setupUI() {
        guard let window = window else { return }

        let contentView = NSView(frame: window.contentView!.bounds)
        window.contentView = contentView

        // Tab view
        tabView = NSTabView(frame: NSRect(x: 0, y: 50, width: 500, height: 350))
        contentView.addSubview(tabView)

        // Add tabs
        setupGeneralTab()
        setupKeysAuthTab()
        setupAdvancedTab()

        // Bottom buttons
        cancelButton = NSButton(frame: NSRect(x: 320, y: 15, width: 80, height: 25))
        cancelButton.title = "Cancel"
        cancelButton.bezelStyle = .rounded
        cancelButton.target = self
        cancelButton.action = #selector(cancelAction)
        cancelButton.keyEquivalent = "\u{1B}" // Escape key
        contentView.addSubview(cancelButton)

        saveButton = NSButton(frame: NSRect(x: 410, y: 15, width: 80, height: 25))
        saveButton.title = "Save"
        saveButton.bezelStyle = .rounded
        saveButton.keyEquivalent = "\r" // Return key
        saveButton.target = self
        saveButton.action = #selector(saveAction)
        contentView.addSubview(saveButton)
    }

    // MARK: - Tab Setup

    private func setupGeneralTab() {
        let tab = NSTabViewItem(identifier: "general")
        tab.label = "General"

        let view = NSView(frame: NSRect(x: 0, y: 0, width: 500, height: 350))

        var y: CGFloat = 300

        // Default Model
        let modelLabel = createLabel(text: "Default Model:", fontSize: 13)
        modelLabel.frame = NSRect(x: 20, y: y, width: 120, height: 20)
        view.addSubview(modelLabel)

        modelPopup = NSPopUpButton(frame: NSRect(x: 150, y: y - 2, width: 320, height: 25))
        modelPopup.addItems(withTitles: [
            "co/gemini-2.5-pro",
            "co/gemini-2.5-flash",
            "co/gpt-4o",
            "co/claude-sonnet-4.5"
        ])
        view.addSubview(modelPopup)

        y -= 40

        // .co Folder Location
        let folderLabel = createLabel(text: ".co Folder:", fontSize: 13)
        folderLabel.frame = NSRect(x: 20, y: y, width: 120, height: 20)
        view.addSubview(folderLabel)

        coFolderField = NSTextField(frame: NSRect(x: 150, y: y - 2, width: 240, height: 25))
        coFolderField.placeholderString = "~/.co"
        view.addSubview(coFolderField)

        browseFolderButton = NSButton(frame: NSRect(x: 400, y: y - 2, width: 70, height: 25))
        browseFolderButton.title = "Browse"
        browseFolderButton.bezelStyle = .rounded
        browseFolderButton.target = self
        browseFolderButton.action = #selector(browseFolderAction)
        view.addSubview(browseFolderButton)

        y -= 40

        // Checkboxes
        autoStartCheckbox = NSButton(checkboxWithTitle: "Start agent on login", target: self, action: nil)
        autoStartCheckbox.frame = NSRect(x: 20, y: y, width: 300, height: 20)
        view.addSubview(autoStartCheckbox)

        y -= 30

        showStatsCheckbox = NSButton(checkboxWithTitle: "Show stats in popover", target: self, action: nil)
        showStatsCheckbox.frame = NSRect(x: 20, y: y, width: 300, height: 20)
        showStatsCheckbox.state = .on // Default on
        view.addSubview(showStatsCheckbox)

        tab.view = view
        tabView.addTabViewItem(tab)
    }

    private func setupKeysAuthTab() {
        let tab = NSTabViewItem(identifier: "keys")
        tab.label = "Keys & Auth"

        let view = NSView(frame: NSRect(x: 0, y: 0, width: 500, height: 350))

        var y: CGFloat = 300

        // .env File Editor
        let envLabel = createLabel(text: ".env File:", fontSize: 13, weight: .semibold)
        envLabel.frame = NSRect(x: 20, y: y, width: 460, height: 20)
        view.addSubview(envLabel)

        y -= 25

        let envHint = createLabel(text: "Edit your .env file (API keys, agent address, etc.)", fontSize: 11, weight: .regular)
        envHint.textColor = .secondaryLabelColor
        envHint.frame = NSRect(x: 20, y: y, width: 460, height: 16)
        view.addSubview(envHint)

        y -= 120

        let scrollView = NSScrollView(frame: NSRect(x: 20, y: y, width: 460, height: 110))
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .bezelBorder
        scrollView.autohidesScrollers = true

        envTextView = NSTextView(frame: scrollView.contentView.bounds)
        envTextView.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        envTextView.isAutomaticQuoteSubstitutionEnabled = false
        envTextView.isAutomaticDashSubstitutionEnabled = false
        scrollView.documentView = envTextView

        view.addSubview(scrollView)

        y -= 40

        // Agent Private Key
        let keyLabel = createLabel(text: "Agent Private Key:", fontSize: 13, weight: .semibold)
        keyLabel.frame = NSRect(x: 20, y: y, width: 460, height: 20)
        view.addSubview(keyLabel)

        y -= 30

        agentKeyField = NSTextField(frame: NSRect(x: 20, y: y, width: 380, height: 25))
        agentKeyField.isEditable = false
        agentKeyField.placeholderString = "Loading..."
        view.addSubview(agentKeyField)

        regenerateKeyButton = NSButton(frame: NSRect(x: 410, y: y, width: 70, height: 25))
        regenerateKeyButton.title = "Copy"
        regenerateKeyButton.bezelStyle = .rounded
        regenerateKeyButton.target = self
        regenerateKeyButton.action = #selector(copyKeyAction)
        view.addSubview(regenerateKeyButton)

        tab.view = view
        tabView.addTabViewItem(tab)
    }

    private func setupAdvancedTab() {
        let tab = NSTabViewItem(identifier: "advanced")
        tab.label = "Advanced"

        let view = NSView(frame: NSRect(x: 0, y: 0, width: 500, height: 350))

        var y: CGFloat = 300

        // Logs Path
        let logsLabel = createLabel(text: "Logs Path:", fontSize: 13)
        logsLabel.frame = NSRect(x: 20, y: y, width: 120, height: 20)
        view.addSubview(logsLabel)

        logsPathField = NSTextField(frame: NSRect(x: 150, y: y - 2, width: 240, height: 25))
        logsPathField.placeholderString = "~/.co/logs/"
        view.addSubview(logsPathField)

        browseLogsButton = NSButton(frame: NSRect(x: 400, y: y - 2, width: 70, height: 25))
        browseLogsButton.title = "Browse"
        browseLogsButton.bezelStyle = .rounded
        browseLogsButton.target = self
        browseLogsButton.action = #selector(browseLogsAction)
        view.addSubview(browseLogsButton)

        y -= 40

        // Custom co Binary Path
        let binaryLabel = createLabel(text: "Custom co Binary:", fontSize: 13)
        binaryLabel.frame = NSRect(x: 20, y: y, width: 120, height: 20)
        view.addSubview(binaryLabel)

        customBinaryField = NSTextField(frame: NSRect(x: 150, y: y - 2, width: 240, height: 25))
        customBinaryField.placeholderString = "Use bundled co binary"
        view.addSubview(customBinaryField)

        browseBinaryButton = NSButton(frame: NSRect(x: 400, y: y - 2, width: 70, height: 25))
        browseBinaryButton.title = "Browse"
        browseBinaryButton.bezelStyle = .rounded
        browseBinaryButton.target = self
        browseBinaryButton.action = #selector(browseBinaryAction)
        view.addSubview(browseBinaryButton)

        y -= 40

        // Debug Mode
        debugModeCheckbox = NSButton(checkboxWithTitle: "Enable debug mode (verbose logging)", target: self, action: nil)
        debugModeCheckbox.frame = NSRect(x: 20, y: y, width: 300, height: 20)
        view.addSubview(debugModeCheckbox)

        tab.view = view
        tabView.addTabViewItem(tab)
    }

    // MARK: - Helpers

    private func createLabel(text: String, fontSize: CGFloat, weight: NSFont.Weight = .regular) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = NSFont.systemFont(ofSize: fontSize, weight: weight)
        label.alignment = .left
        return label
    }

    // MARK: - Load/Save Settings

    private func loadSettings() {
        // Load from UserDefaults
        let defaults = UserDefaults.standard

        // General
        if let model = defaults.string(forKey: "defaultModel") {
            modelPopup.selectItem(withTitle: model)
        }

        coFolderField.stringValue = defaults.string(forKey: "coFolder") ?? NSHomeDirectory() + "/.co"
        autoStartCheckbox.state = defaults.bool(forKey: "autoStart") ? .on : .off
        showStatsCheckbox.state = defaults.bool(forKey: "showStats") ? .on : .off

        // Keys & Auth
        loadEnvFile()
        loadAgentKey()

        // Advanced
        logsPathField.stringValue = defaults.string(forKey: "logsPath") ?? NSHomeDirectory() + "/.co/logs/"
        customBinaryField.stringValue = defaults.string(forKey: "customBinary") ?? ""
        debugModeCheckbox.state = defaults.bool(forKey: "debugMode") ? .on : .off
    }

    private func loadEnvFile() {
        let envPath = NSHomeDirectory() + "/.co/.env"
        if let content = try? String(contentsOfFile: envPath, encoding: .utf8) {
            envTextView.string = content
        } else {
            envTextView.string = "# .env file not found\n# Create ~/.co/.env to configure API keys\n\nOPENAI_API_KEY=sk-...\nANTHROPIC_API_KEY=sk-ant-...\nAGENT_ADDRESS=0x..."
        }
    }

    private func loadAgentKey() {
        let keyPath = NSHomeDirectory() + "/.co/keys/agent.key"
        if let key = try? String(contentsOfFile: keyPath, encoding: .utf8) {
            agentKeyField.stringValue = key.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            agentKeyField.stringValue = "No agent key found"
        }
    }

    // MARK: - Actions

    @objc private func browseFolderAction() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: NSHomeDirectory())

        if panel.runModal() == .OK, let url = panel.url {
            coFolderField.stringValue = url.path
        }
    }

    @objc private func browseLogsAction() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            logsPathField.stringValue = url.path
        }
    }

    @objc private func browseBinaryAction() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.executable]

        if panel.runModal() == .OK, let url = panel.url {
            customBinaryField.stringValue = url.path
        }
    }

    @objc private func copyKeyAction() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(agentKeyField.stringValue, forType: .string)

        // Briefly change button title to "Copied!"
        regenerateKeyButton.title = "Copied!"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.regenerateKeyButton.title = "Copy"
        }
    }

    @objc private func saveAction() {
        let defaults = UserDefaults.standard

        // Save General settings
        defaults.set(modelPopup.titleOfSelectedItem, forKey: "defaultModel")
        defaults.set(coFolderField.stringValue, forKey: "coFolder")
        defaults.set(autoStartCheckbox.state == .on, forKey: "autoStart")
        defaults.set(showStatsCheckbox.state == .on, forKey: "showStats")

        // Save .env file
        let envPath = NSHomeDirectory() + "/.co/.env"
        try? envTextView.string.write(toFile: envPath, atomically: true, encoding: .utf8)

        // Save Advanced settings
        defaults.set(logsPathField.stringValue, forKey: "logsPath")
        defaults.set(customBinaryField.stringValue, forKey: "customBinary")
        defaults.set(debugModeCheckbox.state == .on, forKey: "debugMode")

        close()
    }

    @objc private func cancelAction() {
        close()
    }
}
