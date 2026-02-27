import SwiftUI
import SwiftData
import Combine

struct ResetFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SelfNote.date, order: .reverse) private var notes: [SelfNote]
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
        .onAppear {
            viewModel.configureInitialStep(hasNote: latestNote != nil)
        }
        .onChange(of: latestNote?.id) { _, newValue in
            if newValue == nil {
                viewModel.configureInitialStep(hasNote: false)
            }
        }
    }

    private var latestNote: SelfNote? {
        notes.first
    }

    @ViewBuilder
    private var stepView: some View {
        switch viewModel.step {
        case .noteIntro:
            NoteIntroView(note: latestNote?.text ?? "") {
                HapticsManager.shared.impact(.light)
                viewModel.acknowledgeNote()
            }
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
        case .reflect:
            ReflectionCountdownView(reframe: viewModel.selectedReframe ?? "") {
                HapticsManager.shared.impact(.light)
                viewModel.completeReflection()
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
        case .selfNote:
            SelfNoteView(text: $viewModel.selfNote) {
                HapticsManager.shared.impact(.light)
                viewModel.saveSelfNoteAndContinue(context: modelContext)
            } onSkip: {
                viewModel.skipSelfNote()
            }
        case .complete:
            CompletionView(stressAfter: $viewModel.stressAfter) {
                HapticsManager.shared.success()
                viewModel.saveSession(context: modelContext)
                viewModel.reset(hasNote: latestNote != nil)
                dismiss()
            }
        }
    }
}

private struct NoteIntroView: View {
    let note: String
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("The last time you said to yourself:")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.black.opacity(0.7))

            Text("\"\(note)\"")
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.black.opacity(0.85))
                .padding(.horizontal, 8)

            Text("That matters.")
                .font(.headline)
                .foregroundStyle(Color.black.opacity(0.6))

            Button("Continue") {
                onContinue()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal, 24)
    }
}

private struct StateSelectionView: View {
    let onSelect: (FeelingStateOption) -> Void

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(spacing: 20) {
            Text("Right now I feel...")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.black.opacity(0.75))

            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(ResetContent.states) { state in
                    StateCard(title: state.title) {
                        onSelect(state)
                    }
                }
            }
        }
        .padding(.horizontal, 24)
    }
}

private struct StateCard: View {
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

private struct ReflectionCountdownView: View {
    let reframe: String
    var onComplete: () -> Void

    @State private var remaining: Int = 21

    var body: some View {
        VStack(spacing: 20) {
            Text("Hold this thought")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.black.opacity(0.75))

            Text(reframe)
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.black.opacity(0.8))

            Text("\(remaining)s")
                .font(.headline)
                .foregroundStyle(Color.black.opacity(0.6))

            Text("We’ll guide your breath next")
                .font(.subheadline)
                .foregroundStyle(Color.black.opacity(0.55))
        }
        .padding(.horizontal, 24)
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

private struct SelfNoteView: View {
    @Binding var text: String
    var onSave: () -> Void
    var onSkip: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Leave a note for future you")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.black.opacity(0.75))

            TextEditor(text: $text)
                .frame(height: 140)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.white.opacity(0.9))
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 6)
                )

            HStack(spacing: 12) {
                Button("Skip") {
                    onSkip()
                }
                .buttonStyle(.bordered)

                Button("Save") {
                    onSave()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(.horizontal, 24)
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
