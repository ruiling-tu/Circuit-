import SwiftUI

struct BeginResetButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.45, green: 0.9, blue: 0.8),
                                Color(red: 0.45, green: 0.75, blue: 0.95)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 200, height: 200)
                    .shadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 8)

                Text("Begin\nReset")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white)
                    .multilineTextAlignment(.center)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Begin Reset")
    }
}
