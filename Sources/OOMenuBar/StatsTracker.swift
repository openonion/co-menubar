import Foundation

class StatsTracker {
    private var stats = AgentStats()
    private var timer: Timer?
    var onStatsUpdate: ((String?, Int) -> Void)?

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateStats()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func updateStats() {
        // Update uptime if agent is running
        if let startTime = stats.startTime {
            let uptime = formatUptime(Date().timeIntervalSince(startTime))
            onStatsUpdate?(uptime, stats.requestCount)
        }
    }

    func markAgentStarted() {
        stats.startTime = Date()
        stats.requestCount = 0
        updateStats()
    }

    func markAgentStopped() {
        stats.startTime = nil
        onStatsUpdate?(nil, 0)
    }

    func incrementRequestCount() {
        stats.requestCount += 1
        updateStats()
    }

    private func formatUptime(_ interval: TimeInterval) -> String {
        let hours = Int(interval / 3600)
        let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "< 1m"
        }
    }
}
