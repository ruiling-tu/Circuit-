import SwiftUI

struct AppBackground: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.78, green: 0.95, blue: 0.92),
                Color(red: 0.73, green: 0.88, blue: 0.98)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}
