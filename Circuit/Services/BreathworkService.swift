import Foundation

struct BreathworkProfile: Hashable {
    let title: String
    let instruction: String
    let inhale: Double
    let exhale: Double
    let hold: Double
    let mode: PhysioMode
}

enum IntensityLevel: Int, CaseIterable {
    case low = 1
    case medium = 2
    case high = 3
}

enum BreathworkService {
    static func profile(for stateId: String?, intensity: Int?) -> BreathworkProfile {
        let level = IntensityLevel(rawValue: intensity ?? 2) ?? .medium
        let base = profileForState(stateId: stateId)

        let multiplier: Double
        switch level {
        case .low: multiplier = 0.85
        case .medium: multiplier = 1.0
        case .high: multiplier = 1.2
        }

        return BreathworkProfile(
            title: base.title,
            instruction: base.instructionForIntensity(level),
            inhale: max(2, base.inhale * multiplier),
            exhale: max(2, base.exhale * multiplier),
            hold: max(0, base.hold * multiplier),
            mode: base.mode
        )
    }

    private static func profileForState(stateId: String?) -> BaseProfile {
        switch stateId {
        case "anxious":
            return BaseProfile(title: "Lengthen the exhale", instruction: "Inhale steady • Long exhale", inhale: 4, exhale: 6, hold: 0, mode: .breathing)
        case "irritated", "pressure":
            return BaseProfile(title: "Box breathing", instruction: "Inhale • Hold • Exhale • Hold", inhale: 4, exhale: 4, hold: 4, mode: .boxBreathing)
        case "low":
            return BaseProfile(title: "Lift and energize", instruction: "Posture up • Inhale • Gentle hold", inhale: 4, exhale: 4, hold: 2, mode: .postureLift)
        case "overwhelmed":
            return BaseProfile(title: "Ground and slow", instruction: "Slow inhale • Longer exhale", inhale: 4, exhale: 7, hold: 0, mode: .grounding)
        case "scattered":
            return BaseProfile(title: "Orient and settle", instruction: "Look around • Then slow breath", inhale: 3, exhale: 5, hold: 0, mode: .orienting)
        default:
            return BaseProfile(title: "Steady breath", instruction: "Inhale • Exhale", inhale: 4, exhale: 6, hold: 0, mode: .breathing)
        }
    }
}

private struct BaseProfile {
    let title: String
    let instruction: String
    let inhale: Double
    let exhale: Double
    let hold: Double
    let mode: PhysioMode

    func instructionForIntensity(_ level: IntensityLevel) -> String {
        switch level {
        case .low:
            return "Gentle pace • \(instruction)"
        case .medium:
            return instruction
        case .high:
            return "Slower pace • \(instruction)"
        }
    }
}
