import SwiftUI

struct RootTabView: View {
    @AppStorage("didSetNotificationWindows") private var didSetNotificationWindows: Bool = false
    @State private var showSetup = false

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "circle.grid.cross")
                }

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .onAppear {
            showSetup = !didSetNotificationWindows
        }
        .onChange(of: didSetNotificationWindows) { _, newValue in
            showSetup = !newValue
        }
        .sheet(isPresented: $showSetup) {
            NotificationSetupView()
        }
    }
}
