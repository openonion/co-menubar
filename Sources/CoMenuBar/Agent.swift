import Foundation

class CoAgent {
    private var process: Process?
    private var inputPipe: Pipe?

    var onOutput: ((String) -> Void)?
    var onStateChange: (() -> Void)?

    var isRunning: Bool {
        process?.isRunning ?? false
    }

    // Auto-runs `co init -y` if not initialized, `co auth` if not authenticated, then `co ai`.
    func start() {
        guard !isRunning else { return }

        if !CoAgent.isInitialized() {
            onOutput?("[First time setup — running `co init`...]\n\n")
            launch(command: "init", args: ["-y"]) { [weak self] in
                if CoAgent.isAuthenticated() {
                    self?.onOutput?("\n[Setup complete. Starting co ai...]\n\n")
                    self?.launch(command: "ai")
                } else {
                    self?.onOutput?("\n[Setup incomplete. Click Start to try again.]\n")
                    self?.onStateChange?()
                }
            }
        } else if !CoAgent.isAuthenticated() {
            onOutput?("[No API key found — running `co auth` first...]\n\n")
            launch(command: "auth") { [weak self] in
                if CoAgent.isAuthenticated() {
                    self?.onOutput?("\n[Authenticated. Starting co ai...]\n\n")
                    self?.launch(command: "ai")
                } else {
                    self?.onOutput?("\n[Auth cancelled or failed. Click Start to try again.]\n")
                    self?.onStateChange?()
                }
            }
        } else {
            launch(command: "ai")
        }
    }

    func stop() {
        process?.terminate()
    }

    func send(_ text: String) {
        guard let data = (text + "\n").data(using: .utf8) else { return }
        inputPipe?.fileHandleForWriting.write(data)
    }

    // MARK: - Process

    private func launch(command: String, args extraArgs: [String] = [], onExit: (() -> Void)? = nil) {
        let (execURL, args) = CoAgent.coCommand(command: command, extraArgs: extraArgs)
        let p = Process()
        p.executableURL = execURL
        p.arguments = args
        p.environment = CoAgent.shellEnvironment()

        let outPipe = Pipe()
        let inPipe = Pipe()
        p.standardOutput = outPipe
        p.standardError = outPipe
        p.standardInput = inPipe
        inputPipe = inPipe

        outPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            if let text = String(data: data, encoding: .utf8) {
                self?.onOutput?(text)
            }
        }

        p.terminationHandler = { [weak self] _ in
            DispatchQueue.main.async {
                self?.process = nil
                self?.inputPipe = nil
                if let onExit {
                    onExit()
                } else {
                    self?.onOutput?("\n[co ai exited]\n")
                    self?.onStateChange?()
                }
            }
        }

        p.launch()
        process = p
        onStateChange?()
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

    // MARK: - Initialization check

    // Returns true if ~/.co directory exists (indicates `co init` was run)
    static func isInitialized() -> Bool {
        let coDir = NSHomeDirectory() + "/.co"
        var isDir: ObjCBool = false
        return FileManager.default.fileExists(atPath: coDir, isDirectory: &isDir) && isDir.boolValue
    }

    // MARK: - Auth check

    // Returns true if OPENONION_API_KEY is present in shell env or ~/.co/keys.env
    static func isAuthenticated() -> Bool {
        if shellEnvironment()["OPENONION_API_KEY"] != nil { return true }

        let keysEnvPath = NSHomeDirectory() + "/.co/keys.env"
        guard
            let data = FileManager.default.contents(atPath: keysEnvPath),
            let content = String(data: data, encoding: .utf8)
        else { return false }

        return content.contains("OPENONION_API_KEY=")
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
        p.launch()
        p.waitUntilExit()

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
