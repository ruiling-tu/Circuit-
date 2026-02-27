import Foundation
import SwiftData

@Model
final class Session {
    @Attribute(.unique) var id: UUID
    var date: Date
    var state: String
    var distortion: String
    var reframe: String
    var microAction: String
    var stressBefore: Int?
    var stressAfter: Int?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        state: String,
        distortion: String,
        reframe: String,
        microAction: String,
        stressBefore: Int? = nil,
        stressAfter: Int? = nil
    ) {
        self.id = id
        self.date = date
        self.state = state
        self.distortion = distortion
        self.reframe = reframe
        self.microAction = microAction
        self.stressBefore = stressBefore
        self.stressAfter = stressAfter
    }
}
