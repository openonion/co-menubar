import Foundation

class StatsTracker {
    private var stats = AgentStats()
    private var timer: Timer?
    var onStatsUpdate: ((AgentStats) -> Void)?

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.updateStats()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func updateStats() {
        let logPath = NSHomeDirectory() + "/.co/logs/oo.log"

        guard FileManager.default.fileExists(atPath: logPath) else { return }
        guard let content = try? String(contentsOfFile: logPath) else { return }

        let lines = content.components(separatedBy: "\n")

        // Track request count (look for patterns like "Starting", "Processing", etc.)
        var requestCount = 0
        var lastActiveTime: Date?

        for line in lines {
            if line.contains("Starting") || line.contains("Processing") || line.contains("Completed") {
                requestCount += 1

                // Try to extract timestamp from log line (simplified)
                // Real implementation would parse actual log format
                lastActiveTime = Date()
            }
        }

        stats.requestCount = requestCount
        stats.lastActiveTime = lastActiveTime

        onStatsUpdate?(stats)
    }

    func markAgentStarted() {
        stats.startTime = Date()
        stats.requestCount = 0
        onStatsUpdate?(stats)
    }

    func markAgentStopped() {
        stats.startTime = nil
        onStatsUpdate?(stats)
    }
}
