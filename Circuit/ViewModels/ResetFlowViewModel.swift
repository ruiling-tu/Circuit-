import Foundation
import SwiftData
import Combine

@MainActor
final class ResetFlowViewModel: ObservableObject {
    @Published var step: ResetStep = .state
    @Published var selectedState: FeelingStateOption?
    @Published var selectedDistortion: DistortionOption?
    @Published var selectedReframe: String?
    @Published var selectedMicroAction: MicroAction?
    @Published var stressAfter: Int?
    @Published var selfNote: String = ""
    @Published var selfNotePinned: Bool = false
    @Published var intensity: Int = 2
    @Published var helpedRating: Int?

    let quickMode: Bool
    private(set) var hasNoteIntro: Bool = false

    private var startedAt: Date?
    private var hasTrackedStart = false

    var states: [FeelingStateOption] { ResetContent.states }

    init(quickMode: Bool = false) {
        self.quickMode = quickMode
    }

    func configureInitialStep(showNoteIntro: Bool) {
        hasNoteIntro = showNoteIntro
        step = showNoteIntro ? .noteIntro : .state
    }

    func startTrackingIfNeeded() {
        guard !hasTrackedStart else { return }
        hasTrackedStart = true
        startedAt = Date()
        let started = UserDefaults.standard.integer(forKey: "resetsStarted") + 1
        UserDefaults.standard.set(started, forKey: "resetsStarted")
    }

    var totalSteps: Int { 9 }

    var currentStepIndex: Int {
        switch step {
        case .noteIntro: return 1
        case .state: return hasNoteIntro ? 2 : 1
        case .intensity: return hasNoteIntro ? 3 : 2
        case .quickLoop: return hasNoteIntro ? 4 : 3
        case .distortion: return hasNoteIntro ? 4 : 3
        case .reframe: return hasNoteIntro ? 5 : 4
        case .reflect: return hasNoteIntro ? 6 : 5
        case .physio: return hasNoteIntro ? 7 : 6
        case .microAction: return hasNoteIntro ? 8 : 7
        case .selfNote: return hasNoteIntro ? 9 : 8
        case .complete: return 9
        }
    }

    var estimatedRemainingSeconds: Int {
        let base: [ResetStep: Int] = [
            .noteIntro: 5,
            .state: 6,
            .intensity: 4,
            .distortion: 8,
            .reframe: 8,
            .quickLoop: 10,
            .reflect: 21,
            .physio: 45,
            .microAction: 8,
            .selfNote: 10,
            .complete: 0
        ]

        let sequence: [ResetStep]
        if quickMode {
            sequence = [.noteIntro, .state, .intensity, .quickLoop, .reflect, .physio, .microAction, .selfNote, .complete]
        } else {
            sequence = [.noteIntro, .state, .intensity, .distortion, .reframe, .reflect, .physio, .microAction, .selfNote, .complete]
        }

        guard let index = sequence.firstIndex(of: step) else { return 0 }
        return sequence[index...].reduce(0) { $0 + (base[$1] ?? 0) }
    }

    var canGoBack: Bool {
        switch step {
        case .intensity, .distortion, .reframe:
            return true
        default:
            return false
        }
    }

    var showRestart: Bool {
        switch step {
        case .physio, .microAction, .selfNote, .complete:
            return true
        default:
            return false
        }
    }

    func goBack() {
        switch step {
        case .intensity:
            step = .state
        case .distortion:
            step = .intensity
        case .reframe:
            step = .distortion
        default:
            break
        }
    }

    func restart() {
        selectedState = nil
        selectedDistortion = nil
        selectedReframe = nil
        selectedMicroAction = nil
        stressAfter = nil
        selfNote = ""
        helpedRating = nil
        step = .state
    }

    func acknowledgeNote() {
        step = .state
    }

    func selectState(_ state: FeelingStateOption) {
        selectedState = state
        step = .intensity
    }

    func selectIntensity(_ value: Int) {
        intensity = value
        step = quickMode ? .quickLoop : .distortion
    }

    func selectDistortion(_ distortion: DistortionOption) {
        selectedDistortion = distortion
        step = .reframe
    }

    func selectReframe(_ reframe: String) {
        selectedReframe = reframe
        step = .reflect
    }

    func completeQuickLoop(distortion: DistortionOption, reframe: String) {
        selectedDistortion = distortion
        selectedReframe = reframe
        step = .reflect
    }

    func completeReflection() {
        step = .physio
    }

    func completePhysio() {
        step = .microAction
    }

    func selectMicroAction(_ action: MicroAction) {
        selectedMicroAction = action
        step = .selfNote
    }

    func skipDistortion() {
        if let state = selectedState, let first = state.distortions.first {
            selectedDistortion = first
        }
        step = .reframe
    }

    func skipReframe() {
        if selectedDistortion == nil, let state = selectedState, let first = state.distortions.first {
            selectedDistortion = first
        }
        if let distortion = selectedDistortion, let reframe = distortion.reframes.first {
            selectedReframe = reframe
        }
        step = .reflect
    }

    func skipReflection() {
        step = .physio
    }

    func skipMicroAction() {
        step = .selfNote
    }

    func saveSelfNoteAndContinue(context: ModelContext, existingPinned: SelfNote?) {
        let trimmed = selfNote.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            if selfNotePinned, let pinned = existingPinned {
                pinned.isPinned = false
            }
            let note = SelfNote(text: trimmed, isPinned: selfNotePinned)
            context.insert(note)
            do {
                try context.save()
            } catch {
                context.rollback()
            }
        }
        step = .complete
    }

    func skipSelfNote() {
        step = .complete
    }

    func saveSession(context: ModelContext) {
        guard let state = selectedState else { return }
        let distortion = selectedDistortion?.title ?? "Skipped"
        let reframe = selectedReframe ?? "Skipped"
        let microAction = selectedMicroAction?.title ?? "Skipped"

        let duration = startedAt.map { Date().timeIntervalSince($0) }

        let session = Session(
            state: state.title,
            stateId: state.id,
            distortion: distortion,
            distortionId: selectedDistortion?.id,
            reframe: reframe,
            microAction: microAction,
            stressBefore: nil,
            stressAfter: stressAfter,
            durationSeconds: duration,
            intensity: intensity,
            helpedRating: helpedRating,
            quickMode: quickMode
        )
        context.insert(session)
        do {
            try context.save()
        } catch {
            context.rollback()
        }

        let completed = UserDefaults.standard.integer(forKey: "resetsCompleted") + 1
        UserDefaults.standard.set(completed, forKey: "resetsCompleted")

        NotificationEngagementTracker.recordResetCompleted()
    }

    func reset(showNoteIntro: Bool) {
        configureInitialStep(showNoteIntro: showNoteIntro)
        selectedState = nil
        selectedDistortion = nil
        selectedReframe = nil
        selectedMicroAction = nil
        stressAfter = nil
        selfNote = ""
        selfNotePinned = false
        helpedRating = nil
    }
}

enum ResetStep: Int, CaseIterable {
    case noteIntro
    case state
    case intensity
    case quickLoop
    case distortion
    case reframe
    case reflect
    case physio
    case microAction
    case selfNote
    case complete
}
