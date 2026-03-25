import Foundation

struct Intention: Identifiable, Codable, Equatable {
    let id: String
    var text: String
    let createdAt: Date
    var category: String?

    init(id: String = UUID().uuidString, text: String, createdAt: Date = Date(), category: String? = nil) {
        self.id = id
        self.text = text
        self.createdAt = createdAt
        self.category = category
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(createdAt)
    }
}

enum IntentionCategory: String, CaseIterable {
    case work = "Work"
    case relationships = "Relationships"
    case health = "Health"
    case growth = "Growth"
    case other = "Other"

    var icon: String {
        switch self {
        case .work: return "briefcase.fill"
        case .relationships: return "heart.fill"
        case .health: return "leaf.fill"
        case .growth: return "arrow.up.right"
        case .other: return "sparkle"
        }
    }
}
