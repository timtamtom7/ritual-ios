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
    case coherent = "Coherent"
    case extendedExhale = "Extended Exhale"
    case sleep = "Sleep"
    case custom = "Custom"

    var description: String {
        switch self {
        case .box: return "4-4-4-4"
        case .calm: return "4-7-8"
        case .energize: return "6-0-6-0"
        case .coherent: return "5-5"
        case .extendedExhale: return "4-8"
        case .sleep: return "4-7-8"
        case .custom: return "Personal"
        }
    }

    var phases: [(name: String, duration: Double)] {
        switch self {
        case .box:
            return [("Breathe In", 4), ("Hold", 4), ("Breathe Out", 4), ("Hold", 4)]
        case .calm:
            return [("Breathe In", 4), ("Hold", 7), ("Breathe Out", 8)]
        case .energize:
            return [("Breathe In", 6), ("Breathe Out", 6)]
        case .coherent:
            return [("Breathe In", 5), ("Breathe Out", 5)]
        case .extendedExhale:
            return [("Breathe In", 4), ("Breathe Out", 8)]
        case .sleep:
            return [("Breathe In", 4), ("Hold", 7), ("Breathe Out", 8)]
        case .custom:
            return [("Breathe In", 4), ("Hold", 4), ("Breathe Out", 4), ("Hold", 4)]
        }
    }

    var suggestedTime: String {
        switch self {
        case .box: return "Anytime"
        case .calm: return "Morning"
        case .energize: return "Morning"
        case .coherent: return "Anytime"
        case .extendedExhale: return "Evening"
        case .sleep: return "Evening"
        case .custom: return "Personal"
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
