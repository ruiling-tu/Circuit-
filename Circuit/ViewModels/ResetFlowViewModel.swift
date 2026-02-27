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

    var states: [FeelingStateOption] { ResetContent.states }

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
        step = .physio
    }

    func completePhysio() {
        step = .microAction
    }

    func selectMicroAction(_ action: MicroAction) {
        selectedMicroAction = action
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

    func reset() {
        step = .state
        selectedState = nil
        selectedDistortion = nil
        selectedReframe = nil
        selectedMicroAction = nil
        stressAfter = nil
    }
}

enum ResetStep: Int, CaseIterable {
    case state
    case distortion
    case reframe
    case physio
    case microAction
    case complete
}
