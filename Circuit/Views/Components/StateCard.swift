import SwiftUI

struct StateCard: View {
    let title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.black.opacity(0.8))

                Capsule()
                    .fill(Color.white.opacity(0.7))
                    .frame(width: 36, height: 6)
                    .overlay(Capsule().stroke(Color.black.opacity(0.06), lineWidth: 1))
            }
            .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.9),
                                Color.white.opacity(0.7)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color.black.opacity(0.06), radius: 14, x: 0, y: 8)
            )
        }
        .buttonStyle(.plain)
    }
}
