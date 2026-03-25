import Foundation

struct CheckIn: Identifiable, Codable, Equatable {
    let id: String
    let intentionId: String
    var acted: Bool
    var reflection: String?
    let createdAt: Date

    init(id: String = UUID().uuidString, intentionId: String, acted: Bool, reflection: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.intentionId = intentionId
        self.acted = acted
        self.reflection = reflection
        self.createdAt = createdAt
    }
}
