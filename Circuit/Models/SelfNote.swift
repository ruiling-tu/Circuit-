import Foundation
import SwiftData

@Model
final class SelfNote {
    @Attribute(.unique) var id: UUID
    var date: Date
    var text: String
    var isPinned: Bool

    init(id: UUID = UUID(), date: Date = Date(), text: String, isPinned: Bool = false) {
        self.id = id
        self.date = date
        self.text = text
        self.isPinned = isPinned
    }
}
