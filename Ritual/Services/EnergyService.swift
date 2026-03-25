import Foundation
import Combine

enum EnergyLevel: String, CaseIterable {
    case low = "Low"
    case moderate = "Moderate"
    case high = "High"

    var description: String {
        switch self {
        case .low: return "Gentle, restorative energy"
        case .moderate: return "Balanced, steady energy"
        case .high: return "Vital, expansive energy"
        }
    }

    var icon: String {
        switch self {
        case .low: return "moon.fill"
        case .moderate: return "leaf.fill"
        case .high: return "bolt.fill"
        }
    }

    var preferredBreathingPatterns: [BreathingPattern] {
        switch self {
        case .low:
            return [.sleep, .extendedExhale, .calm]
        case .moderate:
            return [.box, .coherent, .calm]
        case .high:
            return [.energize, .box, .coherent]
        }
    }

    static func from(hour: Int) -> EnergyLevel {
        // Approximate circadian energy curve
        // 6am-10am: rising energy
        // 10am-2pm: peak
        // 2pm-5pm: declining
        // 5pm-8pm: second wind
        // 8pm-10pm: declining
        // 10pm-6am: low/rest

        switch hour {
        case 6, 7, 8, 9:
            return .moderate // morning ramp-up
        case 10, 11, 12, 13:
            return .high // late morning peak
        case 14, 15, 16:
            return .moderate // afternoon dip
        case 17, 18, 19:
            return .moderate // second wind
        case 20, 21:
            return .low // evening wind-down
        default: // 22-5
            return .low // rest period
        }
    }
}

@MainActor
final class EnergyService: ObservableObject {
    static let shared = EnergyService()

    @Published private(set) var currentEnergyLevel: EnergyLevel = .moderate
    @Published private(set) var suggestedPattern: BreathingPattern = .box
    @Published private(set) var suggestedDuration: Int = 3
    @Published private(set) var adaptiveHint: String = ""

    private let seasonService = SeasonService.shared
    private var cancellables = Set<AnyCancellable>()

    private init() {
        update()
    }

    func update() {
        let hour = Calendar.current.component(.hour, from: Date())
        currentEnergyLevel = EnergyLevel.from(hour: hour)
        updateSuggestion()
        updateHint()
    }

    private func updateSuggestion() {
        // Combine time-of-day energy with seasonal preference
        let season = seasonService.currentSeason
        let seasonPattern = season.breathingPatternSuggestion

        // If season suggests a pattern that matches current energy, prefer it
        if currentEnergyLevel.preferredBreathingPatterns.contains(seasonPattern) {
            suggestedPattern = seasonPattern
        } else {
            suggestedPattern = currentEnergyLevel.preferredBreathingPatterns.first ?? .box
        }

        // Duration adapts: low energy = shorter sessions, high energy = longer
        switch currentEnergyLevel {
        case .low:
            suggestedDuration = 3
        case .moderate:
            suggestedDuration = 5
        case .high:
            suggestedDuration = 5
        }
    }

    private func updateHint() {
        let hour = Calendar.current.component(.hour, from: Date())
        let season = seasonService.currentSeason

        switch currentEnergyLevel {
        case .low:
            adaptiveHint = lowEnergyHint(hour: hour, season: season)
        case .moderate:
            adaptiveHint = moderateEnergyHint(hour: hour, season: season)
        case .high:
            adaptiveHint = highEnergyHint(hour: hour, season: season)
        }
    }

    private func lowEnergyHint(hour: Int, season: RitualSeason) -> String {
        let hints = [
            "Your body is naturally winding down. A gentle breath resets the nervous system.",
            "Rest is not the absence of practice — it's part of the ritual.",
            "\(season.rawValue) energy invites softness. Let your breath be unhurried.",
            "Three minutes of extended exhale breathing can shift everything.",
            "When energy is low, even a single conscious breath is enough."
        ]
        return hints[hour % hints.count]
    }

    private func moderateEnergyHint(hour: Int, season: RitualSeason) -> String {
        let hints = [
            "Balanced energy is the perfect ground for intention.",
            "\(season.rawValue) invites you to breathe with the rhythm of the season.",
            "Coherent breathing (5-5) is especially effective at this hour.",
            "Your nervous system is settled enough to go deeper.",
            "A five-minute session now will ripple through the rest of your day."
        ]
        return hints[hour % hints.count]
    }

    private func highEnergyHint(hour: Int, season: RitualSeason) -> String {
        let hints = [
            "Your energy is primed. Use it — box breathing sharpens focus.",
            "Peak energy hours are ideal for longer, more energizing patterns.",
            "Breathe fully and let the energy move through you.",
            "This is a high-capacity moment. The intention you set now carries momentum.",
            "Energize breathing synchronizes body and mind for action."
        ]
        return hints[hour % hints.count]
    }

    /// Returns a breathing pattern that adapts to both time of day and seasonal energy
    func adaptivePattern(for customSuggestion: BreathingPattern? = nil) -> BreathingPattern {
        // Allow override from explicit user selection
        if let suggestion = customSuggestion {
            return suggestion
        }
        return suggestedPattern
    }

    /// Analyzes the user's historical success rates by time-of-day and suggests optimal breathing
    func personalizedPatternSuggestion(from database: DatabaseService) -> BreathingPattern? {
        let sessions = database.getBreathingSessions()
        guard sessions.count >= 3 else { return nil }

        let calendar = Calendar.current

        // Group sessions by pattern and calculate completion rate
        var patternStats: [BreathingPattern: (completed: Int, total: Int)] = [:]
        for session in sessions {
            var stats = patternStats[session.pattern] ?? (0, 0)
            stats.total += 1
            if session.completed { stats.completed += 1 }
            patternStats[session.pattern] = stats
        }

        // Find pattern with best completion rate (at least 3 attempts)
        guard let best = patternStats.first(where: { $0.value.total >= 3 }) else {
            return nil
        }

        let completionRates = patternStats.mapValues { stats in
            Double(stats.completed) / Double(stats.total)
        }

        guard let (pattern, rate) = completionRates.max(by: { $0.value < $1.value }), rate > 0.6 else {
            return nil
        }

        // Only suggest if pattern is appropriate for current energy
        if currentEnergyLevel.preferredBreathingPatterns.contains(pattern) {
            return pattern
        }
        return nil
    }
}
