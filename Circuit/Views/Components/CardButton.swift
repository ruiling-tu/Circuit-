import SwiftUI

struct CardButton: View {
    let title: String
    var subtitle: String? = nil
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.black.opacity(0.82))
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(Color.black.opacity(0.6))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white.opacity(0.8))
                    .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 6)
            )
        }
        .buttonStyle(.plain)
    }
}
