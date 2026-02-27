import SwiftUI

struct HomeView: View {
    @State private var showReset = false

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 24) {
                Spacer()

                BeginResetButton {
                    HapticsManager.shared.impact(.medium)
                    withAnimation(.easeInOut(duration: 0.4)) {
                        showReset = true
                    }
                }

                Text("~90 seconds")
                    .font(.headline)
                    .foregroundStyle(Color.black.opacity(0.55))

                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .fullScreenCover(isPresented: $showReset) {
            ResetFlowView()
        }
    }
}
