import SwiftUI

struct NotificationSetupView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage("notifyMorning") private var notifyMorning: Bool = true
    @AppStorage("notifyMidday") private var notifyMidday: Bool = false
    @AppStorage("notifyEvening") private var notifyEvening: Bool = true
    @AppStorage("didSetNotificationWindows") private var didSetNotificationWindows: Bool = false

    @State private var scheduling = false

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 24) {
                Text("Pick your check-in windows")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.black.opacity(0.75))

                Text("Max 2 per day. We keep it light.")
                    .font(.subheadline)
                    .foregroundStyle(Color.black.opacity(0.6))

                VStack(spacing: 12) {
                    Toggle("Morning", isOn: $notifyMorning)
                    Toggle("Midday", isOn: $notifyMidday)
                    Toggle("Evening", isOn: $notifyEvening)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.white.opacity(0.85))
                )

                Button(scheduling ? "Scheduling..." : "Continue") {
                    Task {
                        scheduling = true
                        await NotificationScheduler.shared.requestAuthorization()
                        await NotificationScheduler.shared.scheduleNotifications(
                            morning: notifyMorning,
                            midday: notifyMidday,
                            evening: notifyEvening
                        )
                        didSetNotificationWindows = true
                        scheduling = false
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(scheduling)
            }
            .padding(24)
        }
    }
}
