import Foundation
import SwiftData

@Model
final class SelfNote {
    @Attribute(.unique) var id: UUID
    var date: Date
    var text: String

    init(id: UUID = UUID(), date: Date = Date(), text: String) {
        self.id = id
        self.date = date
        self.text = text
    }
}
