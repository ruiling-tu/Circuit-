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
}
