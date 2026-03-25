import Foundation
import Combine

@MainActor
final class TodayViewModel: ObservableObject {
    @Published var todaysIntention: Intention?
    @Published var todaysCheckIn: CheckIn?
    @Published var hasCompletedMorningIntention: Bool = false
    @Published var hasCompletedEveningCheckIn: Bool = false
    @Published var showMorningFlow: Bool = false
    @Published var showEveningFlow: Bool = false
    @Published var showBreathingSession: Bool = false

    private let database = DatabaseService.shared

    var isMorning: Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        return hour < 12
    }

    var isEvening: Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        return hour >= 18
    }

    init() {
        loadTodaysData()
    }

    func loadTodaysData() {
        todaysIntention = database.getTodaysIntention()
        if let intention = todaysIntention {
            todaysCheckIn = database.getTodaysCheckIn(forIntentionId: intention.id)
        }
        hasCompletedMorningIntention = todaysIntention != nil
        hasCompletedEveningCheckIn = todaysCheckIn != nil

        // Show morning flow if it's morning and no intention set
        if isMorning && todaysIntention == nil {
            showMorningFlow = true
        } else if isEvening && todaysIntention != nil && todaysCheckIn == nil {
            // Show evening flow if it's evening, intention exists, but no check-in
            showEveningFlow = true
        }
    }

    func saveIntention(_ text: String) {
        let intention = Intention(text: text)
        do {
            try database.saveIntention(intention)
            // Auto-categorize
            let category = categorizeIntention(text)
            try database.updateIntentionCategory(intention.id, category: category)
            todaysIntention = Intention(id: intention.id, text: intention.text, createdAt: intention.createdAt, category: category)
            hasCompletedMorningIntention = true
            showMorningFlow = false
        } catch {
            print("Error saving intention: \(error)")
        }
    }

    func saveCheckIn(acted: Bool, reflection: String?) {
        guard let intention = todaysIntention else { return }
        let checkIn = CheckIn(intentionId: intention.id, acted: acted, reflection: reflection)
        do {
            try database.saveCheckIn(checkIn)
            todaysCheckIn = checkIn
            hasCompletedEveningCheckIn = true
            showEveningFlow = false
        } catch {
            print("Error saving check-in: \(error)")
        }
    }

    private func categorizeIntention(_ text: String) -> String {
        let lowercased = text.lowercased()
        let workKeywords = ["work", "project", "meeting", "deadline", "task", "colleague", "boss", "office", "career", "professional"]
        let relationshipKeywords = ["family", "friend", "partner", "love", "relationship", "connect", "listen", "support", "wife", "husband", "kids", "children", "parents"]
        let healthKeywords = ["health", "exercise", "gym", "run", "walk", "sleep", "rest", "meditate", "yoga", "wellness", "body", "mindful"]

        if workKeywords.contains(where: { lowercased.contains($0) }) {
            return IntentionCategory.work.rawValue
        } else if relationshipKeywords.contains(where: { lowercased.contains($0) }) {
            return IntentionCategory.relationships.rawValue
        } else if healthKeywords.contains(where: { lowercased.contains($0) }) {
            return IntentionCategory.health.rawValue
        } else if lowercased.contains("learn") || lowercased.contains("grow") || lowercased.contains("read") || lowercased.contains("practice") {
            return IntentionCategory.growth.rawValue
        }
        return IntentionCategory.other.rawValue
    }
}
