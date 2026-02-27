import SwiftUI
import SwiftData
import UserNotifications

@main
struct CircuitApp: App {
    private let notificationDelegate = NotificationDelegate()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .onAppear {
                    UNUserNotificationCenter.current().delegate = notificationDelegate
                    Task {
                        await NotificationEngagementTracker.evaluateIgnoredNudges()
                    }
                }
        }
        .modelContainer(for: [Session.self, MicroAction.self, SelfNote.self])
    }
}
