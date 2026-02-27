import Foundation
import SwiftData

@Model
final class FavoriteReframe {
    @Attribute(.unique) var id: UUID
    var distortionId: String
    var text: String
    var date: Date

    init(id: UUID = UUID(), distortionId: String, text: String, date: Date = Date()) {
        self.id = id
        self.distortionId = distortionId
        self.text = text
        self.date = date
    }
}
