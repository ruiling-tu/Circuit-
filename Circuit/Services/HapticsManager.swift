import UIKit

final class HapticsManager {
    static let shared = HapticsManager()

    private init() {}

    var isEnabled: Bool {
        if UserDefaults.standard.object(forKey: "hapticsEnabled") == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: "hapticsEnabled")
    }

    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    func success() {
        guard isEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }
}
