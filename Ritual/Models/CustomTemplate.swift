import Foundation

struct CustomTemplate: Identifiable, Codable {
    let id: String
    let title: String
    let category: String
    let description: String
    let example: String
    let createdAt: Date

    init(id: String = UUID().uuidString, title: String, category: String, description: String, example: String, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.category = category
        self.description = description
        self.example = example
        self.createdAt = createdAt
    }

    var icon: String {
        IntentionCategory(rawValue: category)?.icon ?? "sparkle"
    }
}
