import SwiftUI
import Combine

struct BreathingCircleView: View {
    let mode: PhysioMode
    let duration: Int
    var onComplete: () -> Void

    @State private var remaining: Int
    @State private var scale: CGFloat = 0.7
    @State private var isAnimating = false

    init(mode: PhysioMode, duration: Int = 45, onComplete: @escaping () -> Void) {
        self.mode = mode
        self.duration = duration
        self.onComplete = onComplete
        _remaining = State(initialValue: duration)
    }

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.5), lineWidth: 2)
                    .frame(width: 220, height: 220)

                Circle()
                    .fill(Color.white.opacity(0.65))
                    .frame(width: 200, height: 200)
                    .scaleEffect(scale)
                    .animation(.easeInOut(duration: animationDuration), value: scale)
            }
            .onAppear {
                startAnimation()
            }

            Text(instructionText)
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.black.opacity(0.75))

            Text("\(remaining)s")
                .font(.headline)
                .foregroundStyle(Color.black.opacity(0.6))
        }
        .onReceive(timer) { _ in
            guard remaining > 0 else { return }
            remaining -= 1
            if remaining == 0 {
                onComplete()
            }
        }
    }

    private var timer: Publishers.Autoconnect<Timer.TimerPublisher> {
        Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    }

    private var animationDuration: Double {
        switch mode {
        case .breathing46: return 5
        case .physiologicalSigh: return 6
        case .grounding54321: return 8
        case .postureLift: return 6
        }
    }

    private var instructionText: String {
        switch mode {
        case .breathing46:
            return "Inhale 4 • Exhale 6"
        case .physiologicalSigh:
            return "Two short inhales • Long exhale"
        case .grounding54321:
            return "5-4-3-2-1 grounding"
        case .postureLift:
            return "Lift posture • Inhale • Hold"
        }
    }

    private func startAnimation() {
        guard !isAnimating else { return }
        isAnimating = true
        animatePulse()
    }

    private func animatePulse() {
        guard remaining > 0 else { return }
        scale = 1.05
        HapticsManager.shared.impact(.light)
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
            scale = 0.7
            HapticsManager.shared.impact(.light)
            DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
                animatePulse()
            }
        }
    }
}
