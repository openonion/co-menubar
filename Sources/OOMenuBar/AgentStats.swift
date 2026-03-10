import Foundation

struct AgentStats {
    var requestCount: Int = 0
    var lastActiveTime: Date?
    var startTime: Date?

    var uptime: String? {
        guard let start = startTime else { return nil }
        let interval = Date().timeIntervalSince(start)
        let hours = Int(interval / 3600)
        let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)
        return "\(hours)h \(minutes)m"
    }

    var lastActiveDescription: String? {
        guard let lastActive = lastActiveTime else { return nil }
        let interval = Date().timeIntervalSince(lastActive)
        if interval < 60 { return "Just now" }
        if interval < 3600 { return "\(Int(interval / 60)) minutes ago" }
        return "\(Int(interval / 3600)) hours ago"
    }
}
