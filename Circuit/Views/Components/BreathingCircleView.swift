import SwiftUI
import Combine

struct BreathingCircleView: View {
    let profile: BreathworkProfile
    let duration: Int
    var onComplete: () -> Void

    @State private var remaining: Int
    @State private var scale: CGFloat = 0.7
    @State private var isAnimating = false

    init(profile: BreathworkProfile, duration: Int = 45, onComplete: @escaping () -> Void) {
        self.profile = profile
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
                    .animation(.easeInOut(duration: inhaleExhaleDuration), value: scale)
            }
            .onAppear {
                startAnimation()
            }

            Text(profile.instruction)
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

    private var inhaleExhaleDuration: Double {
        max(2, profile.inhale + profile.exhale + profile.hold)
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
        DispatchQueue.main.asyncAfter(deadline: .now() + profile.inhale) {
            scale = 0.7
            HapticsManager.shared.impact(.light)
            let pause = profile.exhale + profile.hold
            DispatchQueue.main.asyncAfter(deadline: .now() + pause) {
                animatePulse()
            }
        }
    }
}
