import Foundation
import Combine

// MARK: - RitualMacViewModel
// Main ViewModel for RitualMac providing data to all views

@MainActor
final class RitualMacViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var dailyRituals: [DailyRitual] = []
    @Published var currentStreak: Int = 0
    @Published var weeklyNarrative: String = ""
    
    // MARK: - Private Properties
    
    private let database = DatabaseService.shared
    private let calendar = Calendar.current
    
    // MARK: - Computed Properties
    
    var morningRituals: [DailyRitual] {
        dailyRituals.filter { $0.timeOfDay == .morning }
    }
    
    var afternoonRituals: [DailyRitual] {
        dailyRituals.filter { $0.timeOfDay == .afternoon }
    }
    
    var eveningRituals: [DailyRitual] {
        dailyRituals.filter { $0.timeOfDay == .evening }
    }
    
    var totalRituals: Int {
        dailyRituals.count
    }
    
    var completedCount: Int {
        dailyRituals.filter { $0.isCompleted }.count
    }
    
    var dailyProgress: Double {
        guard totalRituals > 0 else { return 0 }
        return Double(completedCount) / Double(totalRituals)
    }
    
    var nextRitual: DailyRitual? {
        let now = Date()
        return dailyRituals
            .filter { !$0.isCompleted && $0.scheduledTime > now }
            .sorted { $0.scheduledTime < $1.scheduledTime }
            .first
    }
    
    var last30Days: [Date] {
        (0..<30).compactMap { day in
            calendar.date(byAdding: .day, value: -day, to: Date())
        }.reversed()
    }
    
    var weeklyCompleted: Int {
        // Get intentions from this week
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let intentions = database.getIntentions().filter { $0.createdAt >= weekAgo }
        
        var count = 0
        for intention in intentions {
            let checkIns = database.getCheckIns(forIntentionId: intention.id)
            if let latest = checkIns.first, latest.acted { count += 1 }
        }
        return count
    }
    
    var weeklyTotal: Int {
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return database.getIntentions().filter { $0.createdAt >= weekAgo }.count
    }
    
    var weeklyCompletionRate: Double {
        guard weeklyTotal > 0 else { return 0 }
        return Double(weeklyCompleted) / Double(weeklyTotal) * 100
    }
    
    var monthlyCompletionRate: Double {
        let monthAgo = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let intentions = database.getIntentions().filter { $0.createdAt >= monthAgo }
        guard !intentions.isEmpty else { return 0 }
        
        var completed = 0
        for intention in intentions {
            let checkIns = database.getCheckIns(forIntentionId: intention.id)
            if let latest = checkIns.first, latest.acted { completed += 1 }
        }
        return Double(completed) / Double(intentions.count) * 100
    }
    
    var overallCompletionRate: Double {
        let intentions = database.getIntentions()
        guard !intentions.isEmpty else { return 0 }
        
        var completed = 0
        for intention in intentions {
            let checkIns = database.getCheckIns(forIntentionId: intention.id)
            if let latest = checkIns.first, latest.acted { completed += 1 }
        }
        return Double(completed) / Double(intentions.count) * 100
    }
    
    var categoryStats: [CategoryStat] {
        let intentions = database.getIntentions()
        let grouped = Dictionary(grouping: intentions) { $0.category ?? "Other" }
        
        return grouped.map { category, intentions in
            var completed = 0
            for intention in intentions {
                let checkIns = database.getCheckIns(forIntentionId: intention.id)
                if let latest = checkIns.first, latest.acted { completed += 1 }
            }
            return CategoryStat(category: category, total: intentions.count, completed: completed)
        }.sorted { $0.completionRate > $1.completionRate }
    }
    
    // MARK: - Navigation Callbacks (for menu bar quick actions)
    
    var onShowRitualList: (() -> Void)?
    var onShowStats: (() -> Void)?
    var onShowDailyFlow: (() -> Void)?
    
    // MARK: - Initialization
    
    init() {
        loadData()
    }
    
    // MARK: - Data Loading
    
    func loadData() {
        loadDailyRituals()
        loadStreak()
        loadWeeklyNarrative()
    }
    
    private func loadDailyRituals() {
        let intentions = database.getIntentions()
        let today = calendar.startOfDay(for: Date())
        
        // Get today's intentions
        let todaysIntentions = intentions.filter {
            calendar.isDate($0.createdAt, inSameDayAs: today)
        }
        
        // Calculate streaks per intention
        dailyRituals = todaysIntentions.map { intention in
            let checkIns = database.getCheckIns(forIntentionId: intention.id)
            let latestCheckIn = checkIns.first
            let streak = calculateStreak(for: intention)
            
            return DailyRitual(
                id: intention.id,
                name: intention.text,
                category: intention.category,
                scheduledTime: intention.createdAt,
                isCompleted: latestCheckIn?.acted ?? false,
                streak: streak
            )
        }.sorted { $0.scheduledTime < $1.scheduledTime }
    }
    
    private func calculateStreak(for intention: Intention) -> Int {
        let allIntentions = database.getIntentions()
            .filter { $0.category == intention.category }
            .sorted { $0.createdAt > $1.createdAt }
        
        var streak = 0
        var currentDate = Date()
        
        for intention in allIntentions.prefix(30) {
            let checkIns = database.getCheckIns(forIntentionId: intention.id)
            if let latest = checkIns.first, latest.acted {
                // Check if this intention is within our lookback
                if calendar.isDate(intention.createdAt, inSameDayAs: currentDate) ||
                   calendar.isDate(intention.createdAt, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate) {
                    streak += 1
                    currentDate = intention.createdAt
                } else {
                    break
                }
            } else {
                break
            }
        }
        
        return streak
    }
    
    private func loadStreak() {
        currentStreak = database.getStreakData().currentStreak
    }
    
    private func loadWeeklyNarrative() {
        weeklyNarrative = database.generateWeeklyReport() ?? "Complete more rituals to see your weekly narrative."
    }
    
    // MARK: - Actions
    
    func isRitualCompleted(_ ritual: DailyRitual) -> Bool {
        guard let todaysCheckIn = database.getTodaysCheckIn(forIntentionId: ritual.id) else {
            return false
        }
        return todaysCheckIn.acted
    }
    
    func toggleRitualCompletion(_ ritual: DailyRitual) {
        let existingCheckIn = database.getTodaysCheckIn(forIntentionId: ritual.id)
        
        if let existing = existingCheckIn {
            // Toggle existing
            let updated = CheckIn(
                id: existing.id,
                intentionId: existing.intentionId,
                acted: !existing.acted,
                reflection: existing.reflection,
                createdAt: existing.createdAt
            )
            try? database.saveCheckIn(updated)
        } else {
            // Create new check-in
            let newCheckIn = CheckIn(
                id: UUID().uuidString,
                intentionId: ritual.id,
                acted: true,
                reflection: nil,
                createdAt: Date()
            )
            try? database.saveCheckIn(newCheckIn)
            database.updateStreak(checkedIn: true)
        }
        
        loadData()
    }
    
    func getCompletionHistory(for ritual: DailyRitual) -> [CompletionRecord] {
        let checkIns = database.getCheckIns(forIntentionId: ritual.id)
        return checkIns.map { checkIn in
            CompletionRecord(
                id: checkIn.id,
                date: checkIn.createdAt,
                completed: checkIn.acted,
                reflection: checkIn.reflection
            )
        }
    }
    
    func dayStatus(for date: Date) -> DayStatus {
        let today = calendar.startOfDay(for: Date())
        let dayStart = calendar.startOfDay(for: date)
        
        if dayStart > today {
            return .future
        }
        
        let intentions = database.getIntentions().filter {
            calendar.isDate($0.createdAt, inSameDayAs: dayStart)
        }
        
        if intentions.isEmpty {
            return .missed
        }
        
        var completed = 0
        for intention in intentions {
            let checkIns = database.getCheckIns(forIntentionId: intention.id)
            if let latest = checkIns.first, latest.acted {
                completed += 1
            }
        }
        
        if completed == intentions.count {
            return .completed
        } else if completed > 0 {
            return .partial
        } else {
            return .missed
        }
    }
    
    // MARK: - Navigation Actions
    
    func showRitualList() {
        onShowRitualList?()
    }
    
    func showStats() {
        onShowStats?()
    }
    
    func showDailyFlow() {
        onShowDailyFlow?()
    }
}
