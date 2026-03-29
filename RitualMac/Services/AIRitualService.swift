import Foundation
import NaturalLanguage

/// AI-powered ritual suggestion service
/// Analyzes user patterns and suggests personalized rituals based on goals,
/// existing habits, and life circumstances.
@MainActor
final class AIRitualService {
    static let shared = AIRitualService()

    private let database = DatabaseService.shared

    private init() {}

    // MARK: - Difficulty

    enum Difficulty: String, Codable, CaseIterable {
        case easy = "Easy"
        case medium = "Medium"
        case challenging = "Challenging"

        var description: String { rawValue }
    }

    // MARK: - Ritual Suggestion

    struct RitualSuggestion: Identifiable, Codable, Equatable {
        let id: String
        let suggestedText: String
        let category: String
        let suggestedTime: Date
        let stackingHook: String?
        let reason: String
        let accepted: Bool?
        let difficulty: String
        let createdAt: Date

        init(
            id: String = UUID().uuidString,
            suggestedText: String,
            category: String,
            suggestedTime: Date = Date(),
            stackingHook: String? = nil,
            reason: String,
            accepted: Bool? = nil,
            difficulty: String = Difficulty.medium.rawValue,
            createdAt: Date = Date()
        ) {
            self.id = id
            self.suggestedText = suggestedText
            self.category = category
            self.suggestedTime = suggestedTime
            self.stackingHook = stackingHook
            self.reason = reason
            self.accepted = accepted
            self.difficulty = difficulty
            self.createdAt = createdAt
        }
    }

    // MARK: - Life Goal

    enum LifeGoal: String, CaseIterable {
        case mindfulness = "Mindfulness"
        case productivity = "Productivity"
        case health = "Health"
        case relationships = "Relationships"
        case creativity = "Creativity"
        case stressRelief = "Stress Relief"
        case sleep = "Better Sleep"
        case focus = "Focus"
    }

    // MARK: - Goal-Based Suggestions

    /// Suggest a new ritual based on a stated life goal
    /// Example: "You want more mindfulness — try this 5-min morning breathing ritual"
    func suggestRitual(for goal: LifeGoal) -> RitualSuggestion {
        switch goal {
        case .mindfulness:
            return RitualSuggestion(
                suggestedText: "Start each morning with 3 deep breaths before checking your phone",
                category: IntentionCategory.health.rawValue,
                suggestedTime: morningSuggestionTime(),
                reason: "You want more mindfulness — a morning breathing ritual helps set a calm tone for the day",
                difficulty: Difficulty.easy.rawValue
            )

        case .productivity:
            return RitualSuggestion(
                suggestedText: "Set your top 3 intentions for the day before starting work",
                category: IntentionCategory.work.rawValue,
                suggestedTime: morningSuggestionTime(),
                reason: "Clarifying priorities before diving in leads to more intentional action",
                difficulty: Difficulty.medium.rawValue
            )

        case .health:
            return RitualSuggestion(
                suggestedText: "Take a 5-minute walk after lunch to reset your body",
                category: IntentionCategory.health.rawValue,
                suggestedTime: afternoonSuggestionTime(),
                stackingHook: "After your lunch break",
                reason: "Movement after eating helps digestion and breaks screen fatigue",
                difficulty: Difficulty.easy.rawValue
            )

        case .relationships:
            return RitualSuggestion(
                suggestedText: "Reach out to one person you care about this week",
                category: IntentionCategory.relationships.rawValue,
                suggestedTime: eveningSuggestionTime(),
                reason: "Intentional connection strengthens relationships over time",
                difficulty: Difficulty.medium.rawValue
            )

        case .creativity:
            return RitualSuggestion(
                suggestedText: "Spend 10 minutes sketching or journaling before bed",
                category: IntentionCategory.growth.rawValue,
                suggestedTime: eveningSuggestionTime(),
                reason: "Unwinding creatively lets your subconscious process the day",
                difficulty: Difficulty.easy.rawValue
            )

        case .stressRelief:
            return RitualSuggestion(
                suggestedText: "Practice box breathing for 2 minutes when you feel tension rising",
                category: IntentionCategory.health.rawValue,
                suggestedTime: anyTimeSuggestion(),
                reason: "Box breathing is proven to activate your parasympathetic nervous system",
                difficulty: Difficulty.easy.rawValue
            )

        case .sleep:
            return RitualSuggestion(
                suggestedText: "Write 3 things you're grateful for before turning off the light",
                category: IntentionCategory.health.rawValue,
                suggestedTime: eveningSuggestionTime(),
                reason: "Gratitude practice before sleep improves sleep quality and mood",
                difficulty: Difficulty.easy.rawValue
            )

        case .focus:
            return RitualSuggestion(
                suggestedText: "Do one task at a time for 25 minutes, then take a 5-minute breath",
                category: IntentionCategory.work.rawValue,
                suggestedTime: morningSuggestionTime(),
                reason: "Single-tasking builds focus muscle better than multitasking",
                difficulty: Difficulty.challenging.rawValue
            )
        }
    }

    // MARK: - Pattern-Based Suggestions

    /// Analyze existing rituals and suggest new ones based on detected gaps
    func suggestBasedOnPatterns() -> [RitualSuggestion] {
        var suggestions: [RitualSuggestion] = []

        let intentions = database.getIntentions()
        let checkIns = database.getAllCheckIns()
        let calendar = Calendar.current

        // Analyze evening check-in completion
        let eveningIntentions = intentions.filter { calendar.component(.hour, from: $0.createdAt) >= 17 }
        let eveningCheckIns = checkIns.filter { calendar.component(.hour, from: $0.createdAt) >= 17 }

        if !eveningIntentions.isEmpty && eveningCheckIns.count < eveningIntentions.count / 2 {
            suggestions.append(RitualSuggestion(
                suggestedText: "Try a shorter evening wind-down ritual — just 3 breaths before bed",
                category: IntentionCategory.health.rawValue,
                suggestedTime: eveningSuggestionTime(),
                reason: "You often miss evening rituals — a shorter wind-down may fit better",
                difficulty: Difficulty.easy.rawValue
            ))
        }

        // Analyze by day of week
        let weekdayCounts = Dictionary(grouping: intentions) {
            calendar.component(.weekday, from: $0.createdAt)
        }
        let mondayCount = weekdayCounts[2]?.count ?? 0
        let fridayCount = weekdayCounts[6]?.count ?? 0

        if mondayCount < 2 {
            suggestions.append(RitualSuggestion(
                suggestedText: "Set a gentle Monday morning intention to ease into the week",
                category: IntentionCategory.growth.rawValue,
                suggestedTime: morningSuggestionTime(),
                reason: "Monday mornings seem challenging — a brief 5-min morning intention helps",
                difficulty: Difficulty.easy.rawValue
            ))
        }

        // Analyze category distribution
        let grouped = database.getIntentionsGroupedByCategory()
        let categories = Array(grouped.keys)

        if !categories.contains(IntentionCategory.relationships.rawValue) {
            suggestions.append(RitualSuggestion(
                suggestedText: "Set an intention around connection or a relationship that matters",
                category: IntentionCategory.relationships.rawValue,
                suggestedTime: morningSuggestionTime(),
                reason: "You haven't set any relationship intentions yet — connection matters",
                difficulty: Difficulty.medium.rawValue
            ))
        }

        // Check success rates by category
        let successRates = Dictionary(uniqueKeysWithValues: IntentionCategory.allCases.map { cat in
            (cat.rawValue, database.getSuccessRate(forCategory: cat.rawValue))
        })

        if let lowest = successRates.min(by: { $0.value < $1.value }), lowest.value < 40, lowest.value > 0 {
            suggestions.append(RitualSuggestion(
                suggestedText: "For your \(lowest.key.lowercased()) intentions, try breaking them into smaller steps",
                category: lowest.key,
                suggestedTime: morningSuggestionTime(),
                reason: "Your \(lowest.key.lowercased()) intentions have a lower success rate — smaller steps may help",
                difficulty: Difficulty.medium.rawValue
            ))
        }

        return suggestions
    }

    // MARK: - Seasonal/Lifecycle Suggestions

    /// Surface seasonal or lifecycle-based suggestions
    func suggestSeasonalRitual() -> RitualSuggestion? {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: Date())

        switch month {
        case 1...2:
            // Post-holiday, winter slump
            return RitualSuggestion(
                suggestedText: "Set a small daily intention to maintain momentum through winter",
                category: IntentionCategory.growth.rawValue,
                suggestedTime: morningSuggestionTime(),
                reason: "Winter months can feel heavy — a daily micro-ritual keeps spirits up",
                difficulty: Difficulty.easy.rawValue
            )
        case 3...4:
            // Spring, renewal
            return RitualSuggestion(
                suggestedText: "Try a spring cleaning ritual — set an intention to release what no longer serves you",
                category: IntentionCategory.growth.rawValue,
                suggestedTime: morningSuggestionTime(),
                reason: "Spring is a natural time for renewal and fresh starts",
                difficulty: Difficulty.easy.rawValue
            )
        case 6...8:
            // Summer, slower pace
            return RitualSuggestion(
                suggestedText: "Take advantage of lighter schedules — try a weekly reflection ritual",
                category: IntentionCategory.growth.rawValue,
                suggestedTime: eveningSuggestionTime(),
                reason: "Summer offers space for deeper reflection practices",
                difficulty: Difficulty.medium.rawValue
            )
        case 9...10:
            // Back to routine
            return RitualSuggestion(
                suggestedText: "Set an intention to establish one new routine this season",
                category: IntentionCategory.growth.rawValue,
                suggestedTime: morningSuggestionTime(),
                reason: "September energy is perfect for building new habits",
                difficulty: Difficulty.medium.rawValue
            )
        case 11:
            // Pre-holiday, gratitude
            return RitualSuggestion(
                suggestedText: "Begin a gratitude practice — note one thing each morning",
                category: IntentionCategory.health.rawValue,
                suggestedTime: morningSuggestionTime(),
                reason: "November is a perfect time to cultivate gratitude before the holidays",
                difficulty: Difficulty.easy.rawValue
            )
        case 12:
            // Holiday, connection
            return RitualSuggestion(
                suggestedText: "Set an intention for meaningful connection during the holiday season",
                category: IntentionCategory.relationships.rawValue,
                suggestedTime: morningSuggestionTime(),
                reason: "The holidays are about people — focus on presence over perfection",
                difficulty: Difficulty.medium.rawValue
            )
        default:
            return nil
        }
    }

    // MARK: - Goal from Intention Text

    /// Infer a likely goal from an intention text using keyword analysis
    func inferGoal(from intentionText: String) -> LifeGoal? {
        let text = intentionText.lowercased()

        let keywords: [LifeGoal: [String]] = [
            .mindfulness: ["calm", "peace", "present", "mindful", "breathe", "settle", "ground"],
            .productivity: ["finish", "complete", "productive", " accomplish", "task", "deadline"],
            .health: ["exercise", "walk", "run", "gym", "healthy", "eat", "sleep", "rest"],
            .relationships: ["call", "connect", "spend time", "family", "friend", "listen", "talk"],
            .creativity: ["write", "draw", "create", "art", "music", "creative", "paint"],
            .stressRelief: ["relax", "unwind", "destress", "let go", "release", "ease"],
            .sleep: ["sleep", "bed", "rest", "tired", "exhausted"],
            .focus: ["focus", " concentrate", "single", "one thing", "deep work", "attention"]
        ]

        for (goal, words) in keywords {
            for word in words {
                if text.contains(word) {
                    return goal
                }
            }
        }

        return nil
    }

    // MARK: - Helper Methods

    private func morningSuggestionTime() -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = 7
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }

    private func afternoonSuggestionTime() -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = 12
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }

    private func eveningSuggestionTime() -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = 20
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }

    private func anyTimeSuggestion() -> Date {
        Date()
    }

    // MARK: - Natural Language Analysis

    /// Use NaturalLanguage framework to analyze intention text and suggest category
    func analyzeIntentionCategory(from text: String) -> String {
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text

        var nounCount = 0
        var verbCount = 0
        var adjectiveCount = 0

        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass) { tag, _ in
            switch tag {
            case .noun: nounCount += 1
            case .verb: verbCount += 1
            case .adjective: adjectiveCount += 1
            default: break
            }
            return true
        }

        // Keyword-based category detection
        let lowercased = text.lowercased()

        if lowercased.contains("work") || lowercased.contains("meeting") || lowercased.contains("project") || lowercased.contains("deadline") || lowercased.contains("task") {
            return IntentionCategory.work.rawValue
        }
        if lowercased.contains("health") || lowercased.contains("exercise") || lowercased.contains("walk") || lowercased.contains("sleep") || lowercased.contains("eat") {
            return IntentionCategory.health.rawValue
        }
        if lowercased.contains("family") || lowercased.contains("friend") || lowercased.contains("call") || lowercased.contains("wife") || lowercased.contains("husband") || lowercased.contains("partner") || lowercased.contains("mom") || lowercased.contains("dad") {
            return IntentionCategory.relationships.rawValue
        }
        if lowercased.contains("learn") || lowercased.contains("grow") || lowercased.contains("read") || lowercased.contains("practice") || lowercased.contains("develop") {
            return IntentionCategory.growth.rawValue
        }

        // Fallback based on noun/verb ratio
        if verbCount > nounCount {
            return IntentionCategory.growth.rawValue
        }

        return IntentionCategory.other.rawValue
    }

    // MARK: - Suggestion History

    private let suggestionHistoryKey = "ai_ritual_suggestion_history"

    func getSuggestionHistory() -> [RitualSuggestion] {
        guard let data = UserDefaults.standard.data(forKey: suggestionHistoryKey),
              let history = try? JSONDecoder().decode([RitualSuggestion].self, from: data) else {
            return []
        }
        return history
    }

    func recordSuggestion(_ suggestion: RitualSuggestion, accepted: Bool?) {
        var history = getSuggestionHistory()
        var updated = suggestion
        // Create a copy with accepted status
        let recorded = RitualSuggestion(
            id: suggestion.id,
            suggestedText: suggestion.suggestedText,
            category: suggestion.category,
            suggestedTime: suggestion.suggestedTime,
            stackingHook: suggestion.stackingHook,
            reason: suggestion.reason,
            accepted: accepted,
            difficulty: suggestion.difficulty,
            createdAt: suggestion.createdAt
        )
        history.append(recorded)

        // Keep last 50 suggestions
        if history.count > 50 {
            history = Array(history.suffix(50))
        }

        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: suggestionHistoryKey)
        }
    }

    func getAcceptanceRate() -> Double {
        let history = getSuggestionHistory()
        let accepted = history.filter { $0.accepted == true }.count
        let total = history.filter { $0.accepted != nil }.count
        guard total > 0 else { return 0 }
        return Double(accepted) / Double(total) * 100
    }

    // MARK: - All Suggestions

    /// Get a comprehensive set of suggestions for the user
    func getAllSuggestions() -> [RitualSuggestion] {
        var all: [RitualSuggestion] = []

        // Add seasonal suggestion
        if let seasonal = suggestSeasonalRitual() {
            all.append(seasonal)
        }

        // Add pattern-based suggestions
        all.append(contentsOf: suggestBasedOnPatterns())

        // Add goal-based suggestions for each goal
        for goal in LifeGoal.allCases {
            all.append(suggestRitual(for: goal))
        }

        // Remove duplicates by suggestedText
        var seen = Set<String>()
        return all.filter { suggestion in
            guard !seen.contains(suggestion.suggestedText) else { return false }
            seen.insert(suggestion.suggestedText)
            return true
        }
    }
}
