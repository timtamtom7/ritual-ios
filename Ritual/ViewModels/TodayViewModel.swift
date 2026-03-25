import Foundation
import Combine
import EventKit

@MainActor
final class TodayViewModel: ObservableObject {
    @Published var todaysIntention: Intention?
    @Published var todaysCheckIn: CheckIn?
    @Published var hasCompletedMorningIntention: Bool = false
    @Published var hasCompletedEveningCheckIn: Bool = false
    @Published var showMorningFlow: Bool = false
    @Published var showEveningFlow: Bool = false
    @Published var showBreathingSession: Bool = false
    @Published var streakData: StreakData = StreakData()
    @Published var streakAnniversary: String?
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    @Published var morningConflicts: [EKEvent] = []
    @Published var calendarRequested: Bool = false

    private let database = DatabaseService.shared
    private let calendarService = CalendarService.shared
    private let subscriptionService = SubscriptionService.shared

    var isMorning: Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        return hour < 12
    }

    var isEvening: Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        return hour >= 18
    }

    var intentionLimitReached: Bool {
        subscriptionService.intentionLimitReached(todayCount: todaysIntentions.count)
    }

    var currentTier: SubscriptionTier {
        subscriptionService.currentTier
    }

    var isSubscribed: Bool {
        subscriptionService.isSubscribed
    }

    var todaysIntentions: [Intention] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        return database.getIntentions().filter {
            calendar.isDate($0.createdAt, inSameDayAs: startOfDay)
        }
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
        streakData = database.getStreakData()
        streakAnniversary = database.streakAnniversary()

        // Show morning flow if it's morning and no intention set
        if isMorning && todaysIntention == nil {
            showMorningFlow = true
            checkCalendarConflicts()
        } else if isEvening && todaysIntention != nil && todaysCheckIn == nil {
            // Show evening flow if it's evening, intention exists, but no check-in
            showEveningFlow = true
        }
    }

    func checkCalendarConflicts() {
        let conflicts = calendarService.conflictingEventsForToday()
        morningConflicts = conflicts.filter { event in
            guard let startHour = Calendar.current.dateComponents([.hour], from: event.startDate).hour else { return false }
            return startHour < 14 // Morning/afternoon conflicts
        }
    }

    func requestCalendarAccess() {
        Task {
            let granted = await calendarService.requestAccess()
            await MainActor.run {
                calendarRequested = true
                if granted {
                    checkCalendarConflicts()
                }
            }
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
            errorMessage = "Couldn't save your intention. Please try again."
            showError = true
        }
    }

    func saveCheckIn(acted: Bool, reflection: String?) {
        guard let intention = todaysIntention else { return }
        let checkIn = CheckIn(intentionId: intention.id, acted: acted, reflection: reflection)
        do {
            try database.saveCheckIn(checkIn)
            database.updateStreak(checkedIn: acted)
            todaysCheckIn = checkIn
            hasCompletedEveningCheckIn = true
            showEveningFlow = false
            streakData = database.getStreakData()
            streakAnniversary = database.streakAnniversary()
        } catch {
            errorMessage = "Couldn't save your check-in. Please try again."
            showError = true
        }
    }

    func useStreakFreeze() {
        if database.useStreakFreeze() {
            streakData = database.getStreakData()
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
