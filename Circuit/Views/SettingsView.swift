import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MicroAction.order) private var actions: [MicroAction]

    @AppStorage("notifyMorning") private var notifyMorning: Bool = true
    @AppStorage("notifyMidday") private var notifyMidday: Bool = false
    @AppStorage("notifyEvening") private var notifyEvening: Bool = true
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true

    @State private var newActionTitle = ""
    @State private var showResetConfirm = false
    @State private var scheduling = false

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Settings")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Color.black.opacity(0.75))

                    settingsSection(title: "Notifications") {
                        Toggle("Morning", isOn: $notifyMorning)
                        Toggle("Midday", isOn: $notifyMidday)
                        Toggle("Evening", isOn: $notifyEvening)

                        Button(scheduling ? "Scheduling..." : "Schedule Nudges") {
                            Task {
                                scheduling = true
                                await NotificationScheduler.shared.requestAuthorization()
                                await NotificationScheduler.shared.scheduleNotifications(
                                    morning: notifyMorning,
                                    midday: notifyMidday,
                                    evening: notifyEvening
                                )
                                scheduling = false
                            }
                        }
                        .disabled(scheduling)
                        .buttonStyle(.borderedProminent)
                    }

                    settingsSection(title: "Haptics") {
                        Toggle("Enable haptics", isOn: $hapticsEnabled)
                    }

                    settingsSection(title: "Micro-Actions") {
                        VStack(spacing: 12) {
                            ForEach(actions) { action in
                                HStack {
                                    Toggle(action.title, isOn: binding(for: action))
                                    Spacer()
                                    Button {
                                        modelContext.delete(action)
                                        saveContext()
                                    } label: {
                                        Image(systemName: "trash")
                                    }
                                }
                            }
                        }

                        HStack {
                            TextField("Add custom favorite", text: $newActionTitle)
                                .textFieldStyle(.roundedBorder)
                            Button("Add") {
                                addAction()
                            }
                            .disabled(newActionTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }

                    settingsSection(title: "Reset") {
                        Button("Reset streak (clears history)") {
                            showResetConfirm = true
                        }
                        .foregroundStyle(Color.red)
                    }

                    settingsSection(title: "Privacy") {
                        Text("All data stays on your device. No cloud, no accounts, no analytics sent.")
                            .font(.footnote)
                            .foregroundStyle(Color.black.opacity(0.6))
                    }
                }
                .padding(24)
            }
        }
        .alert("Reset streak and history?", isPresented: $showResetConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                deleteAllSessions()
            }
        } message: {
            Text("This removes all past resets and clears your streak.")
        }
        .onAppear {
            MicroActionSeeder.seedIfNeeded(context: modelContext)
        }
    }

    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.black.opacity(0.7))

            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.85))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 6)
        )
    }

    private func binding(for action: MicroAction) -> Binding<Bool> {
        Binding(
            get: { action.isEnabled },
            set: { newValue in
                action.isEnabled = newValue
                saveContext()
            }
        )
    }

    private func addAction() {
        let trimmed = newActionTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let nextOrder = (actions.map { $0.order }.max() ?? 0) + 1
        let action = MicroAction(title: trimmed, isDefault: false, isEnabled: true, order: nextOrder)
        modelContext.insert(action)
        saveContext()
        newActionTitle = ""
    }

    private func deleteAllSessions() {
        let fetch = FetchDescriptor<Session>()
        if let all = try? modelContext.fetch(fetch) {
            all.forEach { modelContext.delete($0) }
            saveContext()
        }
    }

    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
        }
    }
}
