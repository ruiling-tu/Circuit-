import Foundation

enum AnalyticsService {
    static func mostCommonState(from sessions: [Session]) -> String? {
        let counts = sessions.reduce(into: [String: Int]()) { result, session in
            result[session.state, default: 0] += 1
        }
        return counts.max(by: { $0.value < $1.value })?.key
    }

    static func weeklyCount(from sessions: [Session], calendar: Calendar = .current) -> Int {
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start else {
            return 0
        }
        return sessions.filter { $0.date >= weekStart }.count
    }

    static func streak(from sessions: [Session], calendar: Calendar = .current) -> Int {
        let uniqueDays = Set(sessions.map { calendar.startOfDay(for: $0.date) })
        guard !uniqueDays.isEmpty else { return 0 }

        var streak = 0
        var currentDay = calendar.startOfDay(for: Date())
        while uniqueDays.contains(currentDay) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDay) else {
                break
            }
            currentDay = previousDay
        }
        return streak
    }

    static func medianDuration(from sessions: [Session]) -> Double? {
        let durations = sessions.compactMap { $0.durationSeconds }.sorted()
        guard !durations.isEmpty else { return nil }
        let mid = durations.count / 2
        if durations.count.isMultiple(of: 2) {
            return (durations[mid - 1] + durations[mid]) / 2
        }
        return durations[mid]
    }

    static func percentileDuration(from sessions: [Session], percentile: Double) -> Double? {
        let durations = sessions.compactMap { $0.durationSeconds }.sorted()
        guard !durations.isEmpty else { return nil }
        let index = Int(round((percentile / 100.0) * Double(durations.count - 1)))
        return durations[max(0, min(index, durations.count - 1))]
    }

    static func topItems(from sessions: [Session], key: KeyPath<Session, String>, limit: Int = 3) -> [(String, Int)] {
        let counts = sessions.reduce(into: [String: Int]()) { result, session in
            result[session[keyPath: key], default: 0] += 1
        }
        return counts.sorted { $0.value > $1.value }.prefix(limit).map { ($0.key, $0.value) }
    }

    static func completionRate(started: Int, completed: Int) -> Double? {
        guard started > 0 else { return nil }
        return Double(completed) / Double(started)
    }

    static func topHelpfulReframe(from sessions: [Session]) -> (state: String, reframe: String, count: Int)? {
        let filtered = sessions.filter { $0.helpedRating == 2 }
        var counts: [String: Int] = [:]
        for session in filtered {
            let key = "\(session.state)|\(session.reframe)"
            counts[key, default: 0] += 1
        }
        guard let best = counts.max(by: { $0.value < $1.value }) else { return nil }
        let parts = best.key.split(separator: "|", maxSplits: 1).map(String.init)
        if parts.count == 2 {
            return (parts[0], parts[1], best.value)
        }
        return nil
    }
}
