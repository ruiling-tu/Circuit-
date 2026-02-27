import SwiftUI
import SwiftData

struct ResetFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = ResetFlowViewModel()

    var body: some View {
        ZStack {
            AppBackground()

            VStack {
                HStack {
                    Button("Close") {
                        HapticsManager.shared.impact(.light)
                        dismiss()
                    }
                    .foregroundStyle(Color.black.opacity(0.6))

                    Spacer()
                }
                .padding([.horizontal, .top], 20)

                Spacer(minLength: 10)

                stepView
                    .transition(.move(edge: .trailing).combined(with: .opacity))

                Spacer(minLength: 20)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: viewModel.step)
    }

    @ViewBuilder
    private var stepView: some View {
        switch viewModel.step {
        case .state:
            StateSelectionView { state in
                HapticsManager.shared.impact(.medium)
                viewModel.selectState(state)
            }
        case .distortion:
            DistortionSelectionView(state: viewModel.selectedState) { distortion in
                HapticsManager.shared.impact(.medium)
                viewModel.selectDistortion(distortion)
            }
        case .reframe:
            ReframeSelectionView(distortion: viewModel.selectedDistortion) { reframe in
                HapticsManager.shared.impact(.medium)
                viewModel.selectReframe(reframe)
            }
        case .physio:
            PhysioResetView(mode: viewModel.selectedState?.physioMode ?? .breathing46) {
                HapticsManager.shared.impact(.light)
                viewModel.completePhysio()
            }
        case .microAction:
            MicroActionView(selected: viewModel.selectedMicroAction) { action in
                HapticsManager.shared.impact(.medium)
                viewModel.selectMicroAction(action)
            }
        case .complete:
            CompletionView(stressAfter: $viewModel.stressAfter) {
                HapticsManager.shared.success()
                viewModel.saveSession(context: modelContext)
                viewModel.reset()
                dismiss()
            }
        }
    }
}

private struct StateSelectionView: View {
    let onSelect: (FeelingStateOption) -> Void

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(spacing: 24) {
            Text("Right now I feel...")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.black.opacity(0.75))

            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(ResetContent.states) { state in
                    CardButton(title: state.title) {
                        onSelect(state)
                    }
                }
            }
        }
        .padding(.horizontal, 24)
    }
}

private struct DistortionSelectionView: View {
    let state: FeelingStateOption?
    let onSelect: (DistortionOption) -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("Notice the story")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.black.opacity(0.75))

            if let distortions = state?.distortions {
                VStack(spacing: 12) {
                    ForEach(distortions) { distortion in
                        CardButton(title: distortion.title) {
                            onSelect(distortion)
                        }
                    }
                }
            } else {
                Text("Pick a state to continue")
                    .foregroundStyle(Color.black.opacity(0.6))
            }
        }
        .padding(.horizontal, 24)
    }
}

private struct ReframeSelectionView: View {
    let distortion: DistortionOption?
    let onSelect: (String) -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("Choose a reframe")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.black.opacity(0.75))

            if let reframes = distortion?.reframes {
                VStack(spacing: 12) {
                    ForEach(reframes, id: \..self) { reframe in
                        CardButton(title: reframe) {
                            onSelect(reframe)
                        }
                    }
                }
            } else {
                Text("Pick a distortion to continue")
                    .foregroundStyle(Color.black.opacity(0.6))
            }
        }
        .padding(.horizontal, 24)
    }
}

private struct PhysioResetView: View {
    let mode: PhysioMode
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("Reset your body")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.black.opacity(0.75))

            BreathingCircleView(mode: mode, duration: 45) {
                onComplete()
            }
        }
        .padding(.horizontal, 24)
    }
}

private struct MicroActionView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MicroAction.order) private var actions: [MicroAction]

    let selected: MicroAction?
    let onSelect: (MicroAction) -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("Next small step")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.black.opacity(0.75))

            VStack(spacing: 12) {
                ForEach(actions.filter { $0.isEnabled }) { action in
                    CardButton(title: action.title) {
                        onSelect(action)
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .onAppear {
            MicroActionSeeder.seedIfNeeded(context: modelContext)
        }
    }
}

private struct CompletionView: View {
    @Binding var stressAfter: Int?
    var onDone: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("Reset Complete.")
                .font(.title.weight(.semibold))
                .foregroundStyle(Color.black.opacity(0.8))

            VStack(spacing: 12) {
                Text("How do you feel now?")
                    .font(.headline)
                    .foregroundStyle(Color.black.opacity(0.7))

                StressSliderView(value: $stressAfter)
            }

            Button("Done") {
                onDone()
            }
            .font(.headline)
            .padding(.horizontal, 32)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.85))
            )
        }
        .padding(.horizontal, 24)
    }
}

private struct StressSliderView: View {
    @Binding var value: Int?

    var body: some View {
        HStack(spacing: 10) {
            ForEach(1...5, id: \..self) { index in
                Circle()
                    .fill(index <= (value ?? 0) ? Color(red: 0.3, green: 0.75, blue: 0.75) : Color.white.opacity(0.7))
                    .frame(width: 16, height: 16)
                    .overlay(Circle().stroke(Color.black.opacity(0.1), lineWidth: 1))
                    .onTapGesture {
                        value = index
                    }
            }
        }
    }
}
