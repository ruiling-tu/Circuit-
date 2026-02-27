import Foundation
import SwiftUI
import SwiftData
import Combine

struct ResetFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SelfNote.date, order: .reverse) private var notes: [SelfNote]
    @Query(sort: \Session.date, order: .reverse) private var sessions: [Session]
    @Query(sort: \FavoriteReframe.date, order: .reverse) private var favoriteReframes: [FavoriteReframe]

    @StateObject private var viewModel: ResetFlowViewModel
    @State private var showOldNote = false

    init(quickMode: Bool = false, preselectedState: FeelingStateOption? = nil) {
        _viewModel = StateObject(wrappedValue: ResetFlowViewModel(quickMode: quickMode))
        _preselectedState = State(initialValue: preselectedState)
    }

    @State private var preselectedState: FeelingStateOption?

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 12) {
                HStack {
                    if viewModel.canGoBack {
                        Button("Back") {
                            HapticsManager.shared.impact(.light)
                            viewModel.goBack()
                        }
                        .foregroundStyle(Color.black.opacity(0.6))
                    } else if viewModel.showRestart {
                        Button("Restart") {
                            HapticsManager.shared.impact(.light)
                            viewModel.restart()
                        }
                        .foregroundStyle(Color.black.opacity(0.6))
                    } else {
                        Button("Close") {
                            HapticsManager.shared.impact(.light)
                            dismiss()
                        }
                        .foregroundStyle(Color.black.opacity(0.6))
                    }

                    Spacer()

                    if shouldShowSkip {
                        Button("Skip") {
                            handleSkip()
                        }
                        .foregroundStyle(Color.black.opacity(0.6))
                    }
                }
                .padding([.horizontal, .top], 20)

                ProgressIndicator(step: viewModel.currentStepIndex, total: viewModel.totalSteps, remaining: viewModel.estimatedRemainingSeconds)
                    .padding(.horizontal, 24)

                stepView
                    .transition(.move(edge: .trailing).combined(with: .opacity))

                Spacer(minLength: 10)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: viewModel.step)
        .onAppear {
            viewModel.startTrackingIfNeeded()
            viewModel.configureInitialStep(showNoteIntro: shouldShowNoteIntro)
            if let pre = preselectedState, !shouldShowNoteIntro {
                viewModel.selectState(pre)
                preselectedState = nil
            }
        }
    }

    private var pinnedNote: SelfNote? {
        notes.first(where: { $0.isPinned })
    }

    private var latestNote: SelfNote? {
        notes.first
    }

    private var recentNote: SelfNote? {
        guard let note = latestNote else { return nil }
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return note.date >= sevenDaysAgo ? note : nil
    }

    private var noteForIntro: SelfNote? {
        pinnedNote ?? recentNote
    }

    private var shouldShowNoteIntro: Bool {
        noteForIntro != nil
    }

    private var shouldShowSkip: Bool {
        switch viewModel.step {
        case .distortion, .reframe, .reflect, .microAction, .selfNote, .quickLoop:
            return true
        default:
            return false
        }
    }

    private func handleSkip() {
        HapticsManager.shared.impact(.light)
        switch viewModel.step {
        case .distortion:
            viewModel.skipDistortion()
        case .reframe:
            viewModel.skipReframe()
        case .reflect:
            viewModel.skipReflection()
        case .microAction:
            viewModel.skipMicroAction()
        case .selfNote:
            viewModel.skipSelfNote()
        case .quickLoop:
            if let state = viewModel.selectedState, let distortion = state.distortions.first, let reframe = distortion.reframes.first {
                viewModel.completeQuickLoop(distortion: distortion, reframe: reframe)
            }
        default:
            break
        }
    }

    @ViewBuilder
    private var stepView: some View {
        switch viewModel.step {
        case .noteIntro:
            NoteIntroView(note: noteForIntro?.text ?? "") {
                HapticsManager.shared.impact(.light)
                viewModel.acknowledgeNote()
                if let pre = preselectedState {
                    viewModel.selectState(pre)
                    preselectedState = nil
                }
            }
        case .state:
            StateSelectionView(showOldNoteLink: noteForIntro == nil && latestNote != nil) {
                showOldNote = true
            } onSelect: { state in
                HapticsManager.shared.impact(.medium)
                viewModel.selectState(state)
            }
            .sheet(isPresented: $showOldNote) {
                if let note = latestNote {
                    NoteIntroView(note: note.text) {
                        showOldNote = false
                    }
                }
            }
        case .intensity:
            IntensitySelectionView(selected: viewModel.intensity) { value in
                HapticsManager.shared.impact(.light)
                viewModel.selectIntensity(value)
            }
        case .quickLoop:
            QuickLoopView(
                state: viewModel.selectedState,
                favorites: favoriteReframes,
                lastSuccessful: lastSuccessfulReframe,
                lastLoop: lastLoopForState(viewModel.selectedState?.id),
                onComplete: { distortion, reframe in
                    viewModel.completeQuickLoop(distortion: distortion, reframe: reframe)
                },
                onFavoriteToggle: toggleFavorite
            )
        case .distortion:
            DistortionSelectionView(state: viewModel.selectedState) { distortion in
                HapticsManager.shared.impact(.medium)
                viewModel.selectDistortion(distortion)
            }
        case .reframe:
            ReframeSelectionView(
                distortion: viewModel.selectedDistortion,
                favorites: favoriteReframes,
                onSelect: { reframe in
                    HapticsManager.shared.impact(.medium)
                    viewModel.selectReframe(reframe)
                },
                onFavoriteToggle: toggleFavorite
            )
        case .reflect:
            ReflectionCountdownView(reframe: viewModel.selectedReframe ?? "") {
                HapticsManager.shared.impact(.light)
                viewModel.completeReflection()
            }
        case .physio:
            let profile = BreathworkService.profile(for: viewModel.selectedState?.id, intensity: viewModel.intensity)
            PhysioResetView(profile: profile) {
                HapticsManager.shared.impact(.light)
                viewModel.completePhysio()
            }
        case .microAction:
            MicroActionView(selected: viewModel.selectedMicroAction) { action in
                HapticsManager.shared.impact(.medium)
                viewModel.selectMicroAction(action)
            }
        case .selfNote:
            SelfNoteView(text: $viewModel.selfNote, isPinned: $viewModel.selfNotePinned) {
                HapticsManager.shared.impact(.light)
                viewModel.saveSelfNoteAndContinue(context: modelContext, existingPinned: pinnedNote)
            } onSkip: {
                viewModel.skipSelfNote()
            }
        case .complete:
            CompletionView(stressAfter: $viewModel.stressAfter, helpedRating: $viewModel.helpedRating) {
                HapticsManager.shared.success()
                viewModel.saveSession(context: modelContext)
                viewModel.reset(showNoteIntro: shouldShowNoteIntro)
                dismiss()
            }
        }
    }

    private func lastLoopForState(_ stateId: String?) -> (distortion: String, reframe: String)? {
        guard let stateId else { return nil }
        if let session = sessions.first(where: { $0.stateId == stateId }) {
            return (session.distortion, session.reframe)
        }
        return nil
    }

    private var lastSuccessfulReframe: String? {
        sessions.first(where: { $0.helpedRating == 2 })?.reframe
    }

    private func toggleFavorite(distortionId: String, reframe: String) {
        if let existing = favoriteReframes.first(where: { $0.distortionId == distortionId && $0.text == reframe }) {
            modelContext.delete(existing)
        } else {
            modelContext.insert(FavoriteReframe(distortionId: distortionId, text: reframe))
        }
        try? modelContext.save()
    }
}

private struct ProgressIndicator: View {
    let step: Int
    let total: Int
    let remaining: Int

    var body: some View {
        HStack {
            Text("Step \(min(step, total)) of \(total)")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.black.opacity(0.6))

            Spacer()

            Text("~\(remaining)s left")
                .font(.footnote)
                .foregroundStyle(Color.black.opacity(0.5))
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
    let showOldNoteLink: Bool
    let onShowNote: () -> Void
    let onSelect: (FeelingStateOption) -> Void

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(spacing: 16) {
            Text("Right now I feel...")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.black.opacity(0.75))

            if showOldNoteLink {
                Button("Last time…") {
                    onShowNote()
                }
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.black.opacity(0.55))
            }

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

private struct IntensitySelectionView: View {
    let selected: Int
    let onSelect: (Int) -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("How intense is it?")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.black.opacity(0.75))

            HStack(spacing: 12) {
                ForEach(1...3, id: \..self) { value in
                    Button {
                        onSelect(value)
                    } label: {
                        VStack(spacing: 6) {
                            Text("\(value)")
                                .font(.headline)
                                .foregroundStyle(Color.black.opacity(0.8))
                            Text(label(for: value))
                                .font(.caption)
                                .foregroundStyle(Color.black.opacity(0.6))
                        }
                        .frame(width: 90, height: 80)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(value == selected ? Color.white.opacity(0.95) : Color.white.opacity(0.75))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 24)
    }

    private func label(for value: Int) -> String {
        switch value {
        case 1: return "Low"
        case 2: return "Medium"
        default: return "High"
        }
    }
}

private struct QuickLoopView: View {
    let state: FeelingStateOption?
    let favorites: [FavoriteReframe]
    let lastSuccessful: String?
    let lastLoop: (distortion: String, reframe: String)?
    let onComplete: (DistortionOption, String) -> Void
    let onFavoriteToggle: (String, String) -> Void

    @State private var selectedDistortion: DistortionOption?

    var body: some View {
        VStack(spacing: 20) {
            Text("What’s the loop?")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.black.opacity(0.75))

            if let lastLoop, let state, let distortion = state.distortions.first(where: { $0.title == lastLoop.distortion }) {
                Button("Use last loop") {
                    onComplete(distortion, lastLoop.reframe)
                }
                .buttonStyle(.bordered)
            }

            if let distortions = state?.distortions {
                VStack(spacing: 12) {
                    ForEach(distortions) { distortion in
                        CardButton(title: distortion.title) {
                            selectedDistortion = distortion
                        }
                    }
                }
            }

            if let distortion = selectedDistortion {
                VStack(spacing: 12) {
                    ForEach(suggestions(for: distortion), id: \..self) { reframe in
                        HStack {
                            Button(reframe) {
                                onComplete(distortion, reframe)
                            }
                            .buttonStyle(.borderedProminent)

                            Button {
                                onFavoriteToggle(distortion.id, reframe)
                            } label: {
                                Image(systemName: isFavorite(distortionId: distortion.id, reframe: reframe) ? "star.fill" : "star")
                            }
                        }
                    }

                    if let last = lastSuccessful {
                        Button("Use last successful reframe") {
                            onComplete(distortion, last)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
        .padding(.horizontal, 24)
    }

    private func suggestions(for distortion: DistortionOption) -> [String] {
        let favorite = favorites.filter { $0.distortionId == distortion.id }.map { $0.text }
        let base = distortion.reframes
        let merged = Array((favorite + base).prefix(2))
        return merged.isEmpty ? base.prefix(2).map { $0 } : merged
    }

    private func isFavorite(distortionId: String, reframe: String) -> Bool {
        favorites.contains { $0.distortionId == distortionId && $0.text == reframe }
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
    let favorites: [FavoriteReframe]
    let onSelect: (String) -> Void
    let onFavoriteToggle: (String, String) -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("Choose a reframe")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.black.opacity(0.75))

            if let distortion {
                let suggestions = orderedReframes(for: distortion)
                VStack(spacing: 12) {
                    ForEach(suggestions, id: \..self) { reframe in
                        HStack {
                            CardButton(title: reframe) {
                                onSelect(reframe)
                            }

                            Button {
                                onFavoriteToggle(distortion.id, reframe)
                            } label: {
                                Image(systemName: isFavorite(distortionId: distortion.id, reframe: reframe) ? "star.fill" : "star")
                            }
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

    private func orderedReframes(for distortion: DistortionOption) -> [String] {
        let favorite = favorites.filter { $0.distortionId == distortion.id }.map { $0.text }
        let merged = favorite + distortion.reframes
        return Array(NSOrderedSet(array: merged)) as? [String] ?? distortion.reframes
    }

    private func isFavorite(distortionId: String, reframe: String) -> Bool {
        favorites.contains { $0.distortionId == distortionId && $0.text == reframe }
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
    let profile: BreathworkProfile
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text(profile.title)
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.black.opacity(0.75))

            BreathingCircleView(profile: profile, duration: 45) {
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
                ForEach(orderedActions) { action in
                    HStack {
                        CardButton(title: action.title) {
                            onSelect(action)
                        }
                        Button {
                            action.isFavorite.toggle()
                            try? modelContext.save()
                        } label: {
                            Image(systemName: action.isFavorite ? "star.fill" : "star")
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .onAppear {
            MicroActionSeeder.seedIfNeeded(context: modelContext)
        }
    }

    private var orderedActions: [MicroAction] {
        let favorites = actions.filter { $0.isFavorite && $0.isEnabled }
        let rest = actions.filter { !$0.isFavorite && $0.isEnabled }
        return favorites + rest
    }
}

private struct SelfNoteView: View {
    @Binding var text: String
    @Binding var isPinned: Bool
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

            Toggle("Pin this message", isOn: $isPinned)
                .toggleStyle(.switch)

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
    @Binding var helpedRating: Int?
    var onDone: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Reset Complete.")
                .font(.title.weight(.semibold))
                .foregroundStyle(Color.black.opacity(0.8))

            VStack(spacing: 12) {
                Text("How do you feel now?")
                    .font(.headline)
                    .foregroundStyle(Color.black.opacity(0.7))

                StressSliderView(value: $stressAfter)
            }

            VStack(spacing: 10) {
                Text("Did this help?")
                    .font(.headline)
                    .foregroundStyle(Color.black.opacity(0.7))

                HStack(spacing: 10) {
                    HelpedButton(title: "Yes", selected: helpedRating == 2) {
                        helpedRating = 2
                    }
                    HelpedButton(title: "Somewhat", selected: helpedRating == 1) {
                        helpedRating = 1
                    }
                    HelpedButton(title: "No", selected: helpedRating == 0) {
                        helpedRating = 0
                    }
                }
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

private struct HelpedButton: View {
    let title: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(title) {
            action()
        }
        .buttonStyle(.bordered)
        .tint(selected ? Color(red: 0.3, green: 0.75, blue: 0.75) : .gray)
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
