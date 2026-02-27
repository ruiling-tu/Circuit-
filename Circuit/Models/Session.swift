import Foundation
import SwiftData

@Model
final class Session {
    @Attribute(.unique) var id: UUID
    var date: Date
    var state: String
    var stateId: String?
    var distortion: String
    var distortionId: String?
    var reframe: String
    var microAction: String
    var stressBefore: Int?
    var stressAfter: Int?
    var durationSeconds: Double?
    var intensity: Int?
    var helpedRating: Int?
    var quickMode: Bool

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        state: String,
        stateId: String? = nil,
        distortion: String,
        distortionId: String? = nil,
        reframe: String,
        microAction: String,
        stressBefore: Int? = nil,
        stressAfter: Int? = nil,
        durationSeconds: Double? = nil,
        intensity: Int? = nil,
        helpedRating: Int? = nil,
        quickMode: Bool = false
    ) {
        self.id = id
        self.date = date
        self.state = state
        self.stateId = stateId
        self.distortion = distortion
        self.distortionId = distortionId
        self.reframe = reframe
        self.microAction = microAction
        self.stressBefore = stressBefore
        self.stressAfter = stressAfter
        self.durationSeconds = durationSeconds
        self.intensity = intensity
        self.helpedRating = helpedRating
        self.quickMode = quickMode
    }
}
