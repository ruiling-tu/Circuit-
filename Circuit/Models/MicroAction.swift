import Foundation
import SwiftData

@Model
final class MicroAction {
    @Attribute(.unique) var id: UUID
    var title: String
    var isDefault: Bool
    var isEnabled: Bool
    var order: Int

    init(
        id: UUID = UUID(),
        title: String,
        isDefault: Bool = false,
        isEnabled: Bool = true,
        order: Int = 0
    ) {
        self.id = id
        self.title = title
        self.isDefault = isDefault
        self.isEnabled = isEnabled
        self.order = order
    }
}
