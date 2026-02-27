import Foundation
import SwiftData

enum MicroActionSeeder {
    static func seedIfNeeded(context: ModelContext) {
        let fetch = FetchDescriptor<MicroAction>()
        guard (try? context.fetch(fetch))?.isEmpty ?? true else { return }

        let defaults = [
            "Send one message",
            "Write one sentence",
            "Stand and breathe for 30 sec",
            "Take a 5-min walk"
        ]

        for (index, title) in defaults.enumerated() {
            let action = MicroAction(title: title, isDefault: true, isEnabled: true, isFavorite: false, order: index)
            context.insert(action)
        }

        do {
            try context.save()
        } catch {
            context.rollback()
        }
    }
}
