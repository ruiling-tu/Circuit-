import Foundation
import UserNotifications

struct NotificationWindow: Hashable {
    let name: String
    let startHour: Int
    let endHour: Int
}

final class NotificationScheduler {
    static let shared = NotificationScheduler()

    private init() {}

    private let messages = [
        "Quick reset before your day accelerates?",
        "Take 90 seconds to break the loop.",
        "Close the mental tab?",
        "Pause for a 60–90 second reset.",
        "One quick reset can change the next hour."
    ]

    func requestAuthorization() async {
        do {
            _ = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return
        }
    }

    func scheduleNotifications(morning: Bool, midday: Bool, evening: Bool) async {
        let center = UNUserNotificationCenter.current()
        await center.removeAllPendingNotificationRequests()

        var windows: [NotificationWindow] = []
        if morning { windows.append(NotificationWindow(name: "morning", startHour: 8, endHour: 10)) }
        if midday { windows.append(NotificationWindow(name: "midday", startHour: 12, endHour: 14)) }
        if evening { windows.append(NotificationWindow(name: "evening", startHour: 18, endHour: 20)) }

        guard !windows.isEmpty else {
            UserDefaults.standard.set(0, forKey: "nextNotificationDate")
            return
        }

        let baseMax = min(2, windows.count)
        let multiplier = UserDefaults.standard.double(forKey: "notificationFrequencyMultiplier")
        let adjustedMax = max(1, Int(round(Double(baseMax) * (multiplier == 0 ? 1.0 : multiplier))))

        var scheduledDates: [Date] = []
        let calendar = Calendar.current
        for dayOffset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: calendar.startOfDay(for: Date())) else {
                continue
            }

            let dayWindows = windows.shuffled().prefix(adjustedMax)
            var dayDates: [Date] = []

            for window in dayWindows {
                let start = calendar.date(bySettingHour: window.startHour, minute: 0, second: 0, of: day) ?? day
                let end = calendar.date(bySettingHour: window.endHour, minute: 0, second: 0, of: day) ?? day
                let windowLength = max(1, Int(end.timeIntervalSince(start) / 60))
                let randomMinute = Int.random(in: 0..<windowLength)
                guard let proposed = calendar.date(byAdding: .minute, value: randomMinute, to: start) else {
                    continue
                }

                let isTooClose = dayDates.contains { abs($0.timeIntervalSince(proposed)) < 4 * 3600 }
                if isTooClose {
                    continue
                }
                dayDates.append(proposed)
            }

            for date in dayDates {
                let content = UNMutableNotificationContent()
                content.title = "Circuit"
                content.body = messages.randomElement() ?? messages[0]
                content.sound = .default

                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date),
                    repeats: false
                )

                let id = "circuit.nudge.\(dayOffset).\(UUID().uuidString)"
                let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                do {
                    try await center.add(request)
                    scheduledDates.append(date)
                } catch {
                    continue
                }
            }
        }

        let nextDate = scheduledDates.sorted().first
        UserDefaults.standard.set(nextDate?.timeIntervalSince1970 ?? 0, forKey: "nextNotificationDate")
    }
}

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "lastNotificationResponseDate")
    }
}

enum NotificationEngagementTracker {
    static func evaluateIgnoredNudges() async {
        let nextTime = UserDefaults.standard.double(forKey: "nextNotificationDate")
        guard nextTime > 0 else { return }

        let nextDate = Date(timeIntervalSince1970: nextTime)
        let lastResetTime = UserDefaults.standard.double(forKey: "lastResetDate")
        let lastResetDate = lastResetTime == 0 ? nil : Date(timeIntervalSince1970: lastResetTime)

        if Date() > nextDate.addingTimeInterval(3600) {
            if lastResetDate == nil || lastResetDate! < nextDate {
                let ignored = UserDefaults.standard.integer(forKey: "consecutiveIgnoredNotifications") + 1
                if ignored >= 3 {
                    UserDefaults.standard.set(0.5, forKey: "notificationFrequencyMultiplier")
                    UserDefaults.standard.set(0, forKey: "consecutiveIgnoredNotifications")
                } else {
                    UserDefaults.standard.set(ignored, forKey: "consecutiveIgnoredNotifications")
                }
            }
        }
    }

    static func recordResetCompleted() {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "lastResetDate")
        UserDefaults.standard.set(0, forKey: "consecutiveIgnoredNotifications")
        let lastResponseTime = UserDefaults.standard.double(forKey: "lastNotificationResponseDate")
        if lastResponseTime > 0 {
            let lastResponse = Date(timeIntervalSince1970: lastResponseTime)
            if Date().timeIntervalSince(lastResponse) < 6 * 3600 {
                UserDefaults.standard.set(1.0, forKey: "notificationFrequencyMultiplier")
            }
        }
    }
}
