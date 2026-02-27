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

    var states: [FeelingStateOption] { ResetContent.states }

    func configureInitialStep(hasNote: Bool) {
        step = hasNote ? .noteIntro : .state
    }

    func acknowledgeNote() {
        step = .state
    }

    func selectState(_ state: FeelingStateOption) {
        selectedState = state
        step = .distortion
    }

    func selectDistortion(_ distortion: DistortionOption) {
        selectedDistortion = distortion
        step = .reframe
    }

    func selectReframe(_ reframe: String) {
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

    func saveSelfNoteAndContinue(context: ModelContext) {
        let trimmed = selfNote.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            let note = SelfNote(text: trimmed)
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
        guard let state = selectedState,
              let distortion = selectedDistortion,
              let reframe = selectedReframe,
              let microAction = selectedMicroAction else {
            return
        }

        let session = Session(
            state: state.title,
            distortion: distortion.title,
            reframe: reframe,
            microAction: microAction.title,
            stressBefore: nil,
            stressAfter: stressAfter
        )
        context.insert(session)
        do {
            try context.save()
        } catch {
            context.rollback()
        }

        NotificationEngagementTracker.recordResetCompleted()
    }

    func reset(hasNote: Bool) {
        step = hasNote ? .noteIntro : .state
        selectedState = nil
        selectedDistortion = nil
        selectedReframe = nil
        selectedMicroAction = nil
        stressAfter = nil
        selfNote = ""
    }
}

enum ResetStep: Int, CaseIterable {
    case noteIntro
    case state
    case distortion
    case reframe
    case reflect
    case physio
    case microAction
    case selfNote
    case complete
}
