import Foundation

/// ConnectOnion Agent Process Manager
///
/// Manages the lifecycle of the `co ai` subprocess and captures its output with ANSI colors.
/// This class handles starting, stopping, and restarting the agent, as well as streaming
/// stdout/stderr output to the UI for display.
///
/// ## Output Capture
/// Unlike the previous implementation that relied on log file tailing, this version
/// captures stdout/stderr directly via Pipes. This allows us to:
/// - Get ANSI color codes before they're stripped
/// - Stream output in real-time
/// - Display Rich formatting exactly as in terminal
///
/// ## Process Management
/// - Uses bundled `co` binary (from .app/Contents/Resources/co)
/// - Falls back to system `co` if bundle not found
/// - Loads shell environment for API keys
/// - Terminates cleanly on stop/quit
///
/// ## Callbacks
/// - `onStateChange`: Called when agent starts/stops
/// - `onOutput`: Called with each chunk of stdout/stderr (with ANSI codes)
///
/// ## Usage
/// ```swift
/// let agent = CoAgent()
/// agent.onOutput = { text in
///     logWindow.appendOutput(text)  // Text includes ANSI codes
/// }
/// agent.start()
/// ```
class CoAgent {
    /// The running process instance (nil when stopped)
    private var process: Process?

    /// Pipe for capturing stdout
    private var outputPipe: Pipe?

    /// Pipe for capturing stderr
    private var errorPipe: Pipe?

    // MARK: - Callbacks

    /// Called when agent state changes (starts or stops)
    var onStateChange: (() -> Void)?

    /// Called with each chunk of output from stdout/stderr (includes ANSI codes)
    var onOutput: ((String) -> Void)?

    /// Called when chat URL is detected in output
    var onChatURL: ((String) -> Void)?

    /// Called when an error occurs starting the agent
    var onError: ((String) -> Void)?

    // MARK: - Public Properties

    /// Current AI model being used (default: co/gemini-2.5-pro)
    var currentModel: String = "co/gemini-2.5-pro"

    /// Current chat URL (e.g., "https://chat.openonion.ai/0xcd92510...")
    var chatURL: String?

    /// Whether the agent process is currently running
    var isRunning: Bool {
        process?.isRunning ?? false
    }

    /// Start the agent process
    ///
    /// Spawns `co ai` subprocess and sets up output capture via pipes.
    /// Output is streamed in real-time through the `onOutput` callback.
    ///
    /// ## Process Flow
    /// 1. Create Process with bundled `co` binary
    /// 2. Set up Pipes for stdout/stderr capture
    /// 3. Set readability handlers to stream output
    /// 4. Start process
    /// 5. Call onStateChange callback
    ///
    /// ## ANSI Color Preservation
    /// By capturing stdout/stderr directly (not redirecting to file),
    /// we preserve ANSI escape codes that Rich library uses for colors.
    func start() {
        guard !isRunning else { return }

        let (execURL, args) = CoAgent.coCommand(command: "ai", extraArgs: [])
        let p = Process()
        p.executableURL = execURL
        p.arguments = args
        p.environment = CoAgent.shellEnvironment()
        p.currentDirectoryURL = URL(fileURLWithPath: NSHomeDirectory())

        // Capture output with pipes to get ANSI colors
        let outPipe = Pipe()
        let errPipe = Pipe()
        p.standardOutput = outPipe
        p.standardError = errPipe
        p.standardInput = nil

        outputPipe = outPipe
        errorPipe = errPipe

        // Read output asynchronously
        outPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if data.count > 0, let text = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    self?.onOutput?(text)
                    self?.extractChatURL(from: text)
                }
            }
        }

        errPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if data.count > 0, let text = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    self?.onOutput?(text)
                    self?.extractChatURL(from: text)
                }
            }
        }

        p.terminationHandler = { [weak self] _ in
            DispatchQueue.main.async {
                self?.outputPipe?.fileHandleForReading.readabilityHandler = nil
                self?.errorPipe?.fileHandleForReading.readabilityHandler = nil
                self?.outputPipe = nil
                self?.errorPipe = nil
                self?.process = nil
                self?.onStateChange?()
            }
        }

        do {
            try p.run()
            process = p
            onStateChange?()
        } catch {
            print("Failed to start co ai: \(error)")
            onError?(error.localizedDescription)
        }
    }

    /// Stop the agent process
    ///
    /// Cleans up pipe handlers and terminates the process.
    func stop() {
        outputPipe?.fileHandleForReading.readabilityHandler = nil
        errorPipe?.fileHandleForReading.readabilityHandler = nil
        outputPipe = nil
        errorPipe = nil
        chatURL = nil
        process?.terminate()
    }

    // MARK: - Chat URL Extraction

    /// Extract chat URL from agent output
    ///
    /// Looks for patterns like "chat.openonion.ai/0xcd92510..." in the output
    /// and stores the full URL for the "Open Chat" button.
    private func extractChatURL(from text: String) {
        // Remove ANSI codes first for easier parsing
        let cleanText = text.replacingOccurrences(of: "\\u{1B}\\[[0-9;]*m", with: "", options: .regularExpression)

        // Look for chat.openonion.ai URLs
        let pattern = "chat\\.openonion\\.ai[/\\S]+"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return }

        let nsText = cleanText as NSString
        let matches = regex.matches(in: cleanText, options: [], range: NSRange(location: 0, length: nsText.length))

        if let match = matches.first {
            let urlPath = nsText.substring(with: match.range).trimmingCharacters(in: .whitespaces)
            let fullURL = urlPath.hasPrefix("http") ? urlPath : "https://\(urlPath)"

            if chatURL != fullURL {
                chatURL = fullURL
                onChatURL?(fullURL)
            }
        }
    }

    /// Restart the agent process
    ///
    /// Stops the current process and starts a new one after a short delay.
    func restart() {
        stop()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.start()
        }
    }

    // MARK: - Bundled binary

    private static func coCommand(command: String, extraArgs: [String] = []) -> (URL, [String]) {
        if let resources = Bundle.main.resourceURL {
            let bundled = resources.appendingPathComponent("co")
            if FileManager.default.isExecutableFile(atPath: bundled.path) {
                return (bundled, [command] + extraArgs)
            }
        }
        return (URL(fileURLWithPath: "/usr/bin/env"), ["co", command] + extraArgs)
    }

    // MARK: - Shell environment

    // Reads the user's login shell environment so API keys are available
    // when the app is launched from Finder (which has a minimal environment).
    private static var cachedShellEnv: [String: String]?

    static func shellEnvironment() -> [String: String] {
        if let cached = cachedShellEnv { return cached }

        let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
        let p = Process()
        p.executableURL = URL(fileURLWithPath: shell)
        p.arguments = ["-l", "-c", "env"]
        let outPipe = Pipe()
        p.standardOutput = outPipe
        p.standardError = Pipe()

        do {
            try p.run()
            p.waitUntilExit()
        } catch {
            return ProcessInfo.processInfo.environment
        }

        let output = String(data: outPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        var env = ProcessInfo.processInfo.environment
        for line in output.components(separatedBy: "\n") {
            guard let eq = line.firstIndex(of: "=") else { continue }
            let key = String(line[..<eq])
            let value = String(line[line.index(after: eq)...])
            if !key.isEmpty { env[key] = value }
        }

        cachedShellEnv = env
        return env
    }
}
