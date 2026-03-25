import Foundation

struct BreathingSession: Identifiable, Codable, Equatable {
    let id: String
    let pattern: BreathingPattern
    let durationSeconds: Int
    var completed: Bool
    let createdAt: Date

    init(id: String = UUID().uuidString, pattern: BreathingPattern, durationSeconds: Int, completed: Bool = false, createdAt: Date = Date()) {
        self.id = id
        self.pattern = pattern
        self.durationSeconds = durationSeconds
        self.completed = completed
        self.createdAt = createdAt
    }
}

enum BreathingPattern: String, Codable, CaseIterable {
    case box = "Box"
    case calm = "Calm"
    case energize = "Energize"

    var description: String {
        switch self {
        case .box: return "4-4-4-4"
        case .calm: return "4-7-8"
        case .energize: return "6-0-6-0"
        }
    }

    var phases: [(name: String, duration: Double)] {
        switch self {
        case .box:
            return [("Breathe In", 4), ("Hold", 4), ("Breathe Out", 4), ("Hold", 4)]
        case .calm:
            return [("Breathe In", 4), ("Hold", 7), ("Breathe Out", 8)]
        case .energize:
            return [("Breathe In", 6), ("Hold", 0), ("Breathe Out", 6)]
        }
    }
}

enum BreathingPhase: String {
    case inhale = "Breathe In"
    case holdIn = "Hold In"
    case exhale = "Breathe Out"
    case holdOut = "Hold Out"
    case paused = "Paused"
    case idle = "Ready"
}
