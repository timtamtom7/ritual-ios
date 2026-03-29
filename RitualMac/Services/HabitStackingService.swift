import Foundation

/// Habit Stacking Engine
/// Detects existing habits and suggests new rituals that attach to them.
/// "You already do X every morning. Try adding Y right after."
@MainActor
final class HabitStackingService {
    static let shared = HabitStackingService()

    private let database = DatabaseService.shared

    private init() {}

    // MARK: - Habit Chain

    struct HabitChain: Identifiable, Codable {
        let id: String
        let existingHabit: String
        let existingHabitTime: String
        let newRitual: String
        let stackingPhrase: String
        let category: String
        let strength: Double // 0.0 - 1.0, how well the stack works

        init(
            id: String = UUID().uuidString,
            existingHabit: String,
            existingHabitTime: String,
            newRitual: String,
            stackingPhrase: String,
            category: String,
            strength: Double = 0.5
        ) {
            self.id = id
            self.existingHabit = existingHabit
            self.existingHabitTime = existingHabitTime
            self.newRitual = newRitual
            self.stackingPhrase = stackingPhrase
            self.category = category
            self.strength = strength
        }
    }

    // MARK: - Detected Habit

    struct DetectedHabit: Identifiable {
        let id = UUID()
        let triggerPhrase: String
        let intentionText: String
        let timeOfDay: TimeOfDay
        let frequency: Int
        let category: String

        enum TimeOfDay: String {
            case morning = "Morning"
            case afternoon = "Afternoon"
            case evening = "Evening"
            case anytime = "Anytime"
        }
    }

    // MARK: - Habit Detection

    /// Detect existing habits from user's intention history
    func detectExistingHabits() -> [DetectedHabit] {
        let intentions = database.getIntentions()
        let calendar = Calendar.current
        var habits: [DetectedHabit] = []

        // Group intentions by time of day
        var morningIntentions: [Intention] = []
        var afternoonIntentions: [Intention] = []
        var eveningIntentions: [Intention] = []

        for intention in intentions {
            let hour = calendar.component(.hour, from: intention.createdAt)
            if hour >= 5 && hour < 12 {
                morningIntentions.append(intention)
            } else if hour >= 12 && hour < 17 {
                afternoonIntentions.append(intention)
            } else {
                eveningIntentions.append(intention)
            }
        }

        // Detect morning coffee/breakfast habit
        let morningKeywords = ["coffee", "tea", "breakfast", "morning", "wake up", "start"]
        for keyword in morningKeywords {
            let matching = morningIntentions.filter { $0.text.lowercased().contains(keyword) }
            if matching.count >= 2 {
                habits.append(DetectedHabit(
                    triggerPhrase: "In the morning",
                    intentionText: matching.first?.text ?? "",
                    timeOfDay: .morning,
                    frequency: matching.count,
                    category: "Morning Routine"
                ))
                break
            }
        }

        // Detect work habits
        let workKeywords = ["work", "meeting", "project", "email", "deadline", "focus", "start working"]
        let workMatching = intentions.filter { intention in
            workKeywords.contains { intention.text.lowercased().contains($0) }
        }
        if workMatching.count >= 3 {
            habits.append(DetectedHabit(
                triggerPhrase: "When starting work",
                intentionText: workMatching.first?.text ?? "",
                timeOfDay: .morning,
                frequency: workMatching.count,
                category: "Work"
            ))
        }

        // Detect exercise habits
        let exerciseKeywords = ["walk", "run", "gym", "exercise", "workout", "yoga", "stretch"]
        for keyword in exerciseKeywords {
            let matching = intentions.filter { $0.text.lowercased().contains(keyword) }
            if matching.count >= 2 {
                habits.append(DetectedHabit(
                    triggerPhrase: "During exercise",
                    intentionText: matching.first?.text ?? "",
                    timeOfDay: .afternoon,
                    frequency: matching.count,
                    category: "Health"
                ))
                break
            }
        }

        // Detect evening wind-down habits
        let eveningKeywords = ["evening", "night", "before bed", "dinner", "walk", "relax"]
        for keyword in eveningKeywords {
            let matching = eveningIntentions.filter { $0.text.lowercased().contains(keyword) }
            if matching.count >= 2 {
                habits.append(DetectedHabit(
                    triggerPhrase: "In the evening",
                    intentionText: matching.first?.text ?? "",
                    timeOfDay: .evening,
                    frequency: matching.count,
                    category: "Evening Routine"
                ))
                break
            }
        }

        // If no specific habits detected, create generic ones
        if habits.isEmpty && !intentions.isEmpty {
            // Morning habit based on most common morning intention
            if !morningIntentions.isEmpty {
                let mostCommon = morningIntentions.first?.text ?? "your morning routine"
                habits.append(DetectedHabit(
                    triggerPhrase: "Every morning",
                    intentionText: mostCommon,
                    timeOfDay: .morning,
                    frequency: morningIntentions.count,
                    category: "Morning Routine"
                ))
            }

            // Evening habit
            if !eveningIntentions.isEmpty {
                let mostCommon = eveningIntentions.first?.text ?? "your evening routine"
                habits.append(DetectedHabit(
                    triggerPhrase: "In the evening",
                    intentionText: mostCommon,
                    timeOfDay: .evening,
                    frequency: eveningIntentions.count,
                    category: "Evening Routine"
                ))
            }
        }

        return habits
    }

    // MARK: - Habit Stacking Suggestions

    /// Suggest a new ritual to stack onto an existing habit
    /// Example: "You already do X every morning. Try adding Y right after."
    func suggestStackedHabit(for existingHabit: DetectedHabit) -> HabitChain? {
        switch existingHabit.timeOfDay {
        case .morning:
            return suggestMorningStack(for: existingHabit)
        case .afternoon:
            return suggestAfternoonStack(for: existingHabit)
        case .evening:
            return suggestEveningStack(for: existingHabit)
        case .anytime:
            return nil
        }
    }

    private func suggestMorningStack(for habit: DetectedHabit) -> HabitChain {
        // Morning breathing + intention
        if habit.intentionText.lowercased().contains("coffee") || habit.intentionText.lowercased().contains("tea") {
            return HabitChain(
                existingHabit: "Your morning coffee",
                existingHabitTime: "Morning",
                newRitual: "3 deep breaths before your first sip",
                stackingPhrase: "After your morning coffee, do 3 deep breaths",
                category: IntentionCategory.health.rawValue,
                strength: 0.9
            )
        }

        if habit.intentionText.lowercased().contains("breakfast") {
            return HabitChain(
                existingHabit: "Your breakfast routine",
                existingHabitTime: "Morning",
                newRitual: "Set your top 3 priorities for the day",
                stackingPhrase: "After breakfast, set your top 3 priorities for today",
                category: IntentionCategory.work.rawValue,
                strength: 0.8
            )
        }

        // Default morning stack
        return HabitChain(
            existingHabit: "Your morning routine",
            existingHabitTime: "Morning",
            newRitual: "Take 3 deep breaths to center yourself",
            stackingPhrase: "After you wake up, take 3 deep breaths before checking your phone",
            category: IntentionCategory.health.rawValue,
            strength: 0.7
        )
    }

    private func suggestAfternoonStack(for habit: DetectedHabit) -> HabitChain {
        if habit.intentionText.lowercased().contains("exercise") || habit.intentionText.lowercased().contains("gym") {
            return HabitChain(
                existingHabit: "Your exercise routine",
                existingHabitTime: "Afternoon",
                newRitual: "Set an afternoon refresh intention",
                stackingPhrase: "After your workout, set one intention to refresh your afternoon",
                category: IntentionCategory.growth.rawValue,
                strength: 0.8
            )
        }

        // Default afternoon stack
        return HabitChain(
            existingHabit: "Your lunch break",
            existingHabitTime: "Afternoon",
            newRitual: "Take a 5-minute walk to reset",
            stackingPhrase: "After lunch, take a 5-minute walk to reset",
            category: IntentionCategory.health.rawValue,
            strength: 0.7
        )
    }

    private func suggestEveningStack(for habit: DetectedHabit) -> HabitChain {
        if habit.intentionText.lowercased().contains("dinner") {
            return HabitChain(
                existingHabit: "Your dinner routine",
                existingHabitTime: "Evening",
                newRitual: "Reflect on one thing that went well today",
                stackingPhrase: "After dinner, reflect on one thing that went well today",
                category: IntentionCategory.growth.rawValue,
                strength: 0.8
            )
        }

        // Default evening stack
        return HabitChain(
            existingHabit: "Your evening routine",
            existingHabitTime: "Evening",
            newRitual: "Write 3 things you're grateful for",
            stackingPhrase: "Before bed, write down 3 things you're grateful for",
            category: IntentionCategory.health.rawValue,
            strength: 0.9
        )
    }

    // MARK: - All Stacked Habits

    /// Get all suggested habit chains for the user
    func getAllSuggestedChains() -> [HabitChain] {
        let detectedHabits = detectExistingHabits()
        var chains: [HabitChain] = []

        for habit in detectedHabits {
            if let chain = suggestStackedHabit(for: habit) {
                chains.append(chain)
            }
        }

        // If no habits detected, provide default chains
        if chains.isEmpty {
            chains.append(contentsOf: getDefaultChains())
        }

        return chains
    }

    private func getDefaultChains() -> [HabitChain] {
        return [
            HabitChain(
                existingHabit: "Your morning routine",
                existingHabitTime: "Morning",
                newRitual: "Set an daily intention with 3 deep breaths first",
                stackingPhrase: "After your morning routine, set your daily intention",
                category: IntentionCategory.growth.rawValue,
                strength: 0.7
            ),
            HabitChain(
                existingHabit: "Your evening routine",
                existingHabitTime: "Evening",
                newRitual: "Reflect briefly on how your day aligned with your intention",
                stackingPhrase: "Before bed, briefly reflect on how your day went",
                category: IntentionCategory.growth.rawValue,
                strength: 0.8
            ),
            HabitChain(
                existingHabit: "Your lunch break",
                existingHabitTime: "Afternoon",
                newRitual: "Take 3 deep breaths before eating",
                stackingPhrase: "After sitting down for lunch, take 3 deep breaths",
                category: IntentionCategory.health.rawValue,
                strength: 0.6
            )
        ]
    }

    // MARK: - Conflict Detection

    /// Identify potential conflict points between existing routines
    func detectConflicts(existingChains: [HabitChain]) -> [String] {
        var conflicts: [String] = []

        // Check for overloaded mornings
        let morningChains = existingChains.filter { $0.existingHabitTime == "Morning" }
        if morningChains.count > 3 {
            conflicts.append("Your morning routine has \(morningChains.count) stacked habits — consider spreading them out")
        }

        // Check for conflicting categories at same time
        var timeCategories: [String: [String]] = [:]
        for chain in existingChains {
            let key = chain.existingHabitTime
            timeCategories[key, default: []].append(chain.category)
        }

        for (time, categories) in timeCategories {
            let unique = Set(categories)
            if unique.count > 2 {
                conflicts.append("Your \(time.lowercased()) has mixed categories — keeping similar themes together improves adherence")
            }
        }

        return conflicts
    }

    // MARK: - Habit Chain History

    private let habitChainHistoryKey = "habit_chain_history"

    func getAcceptedChains() -> [HabitChain] {
        guard let data = UserDefaults.standard.data(forKey: habitChainHistoryKey),
              let chains = try? JSONDecoder().decode([HabitChain].self, from: data) else {
            return []
        }
        return chains
    }

    func recordAcceptedChain(_ chain: HabitChain) {
        var chains = getAcceptedChains()
        chains.append(chain)

        if let data = try? JSONEncoder().encode(chains) {
            UserDefaults.standard.set(data, forKey: habitChainHistoryKey)
        }
    }

    // MARK: - Visual Habit Chain Description

    /// Generate a human-readable description of a habit chain
    func describeChain(_ chain: HabitChain) -> String {
        """
        \(chain.stackingPhrase). This stacks a new \(chain.newRitual.lowercased()) onto \(chain.existingHabit.lowercased()), \
        building on an existing habit to strengthen your routine.
        """
    }
}
