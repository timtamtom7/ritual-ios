import Foundation
import SQLite

@MainActor
final class DatabaseService {
    static let shared = DatabaseService()

    private var db: Connection?

    // Tables
    private let intentions = Table("intentions")
    private let checkIns = Table("check_ins")
    private let breathingSessions = Table("breathing_sessions")

    // Intention columns
    private let id = SQLite.Expression<String>("id")
    private let text = SQLite.Expression<String>("text")
    private let createdAt = SQLite.Expression<String>("created_at")
    private let category = SQLite.Expression<String?>("category")

    // CheckIn columns
    private let intentionId = SQLite.Expression<String>("intention_id")
    private let acted = SQLite.Expression<Bool>("acted")
    private let reflection = SQLite.Expression<String?>("reflection")

    // BreathingSession columns
    private let pattern = SQLite.Expression<String>("pattern")
    private let durationSeconds = SQLite.Expression<Int>("duration_seconds")
    private let completed = SQLite.Expression<Bool>("completed")

    private let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private init() {
        setupDatabase()
    }

    private func setupDatabase() {
        do {
            let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
            db = try Connection("\(path)/ritual.sqlite3")
            try createTables()
        } catch {
            print("Database setup error: \(error)")
        }
    }

    private func createTables() throws {
        try db?.run(intentions.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(text)
            t.column(createdAt)
            t.column(category)
        })

        try db?.run(checkIns.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(intentionId)
            t.column(acted)
            t.column(reflection)
            t.column(createdAt)
        })

        try db?.run(breathingSessions.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(pattern)
            t.column(durationSeconds)
            t.column(completed)
            t.column(createdAt)
        })
    }

    // MARK: - Intentions

    func saveIntention(_ intention: Intention) throws {
        let insert = intentions.insert(
            id <- intention.id,
            text <- intention.text,
            createdAt <- dateFormatter.string(from: intention.createdAt),
            category <- intention.category
        )
        try db?.run(insert)
    }

    func getIntentions() -> [Intention] {
        guard let db = db else { return [] }
        var result: [Intention] = []
        do {
            for row in try db.prepare(intentions.order(createdAt.desc)) {
                if let date = dateFormatter.date(from: row[createdAt]) {
                    result.append(Intention(
                        id: row[id],
                        text: row[text],
                        createdAt: date,
                        category: row[category]
                    ))
                }
            }
        } catch {
            print("Error fetching intentions: \(error)")
        }
        return result
    }

    func getTodaysIntention() -> Intention? {
        getIntentions().first { $0.isToday }
    }

    func getIntention(byId intentionId: String) -> Intention? {
        guard let db = db else { return nil }
        do {
            let query = intentions.filter(id == intentionId)
            if let row = try db.pluck(query) {
                if let date = dateFormatter.date(from: row[createdAt]) {
                    return Intention(
                        id: row[id],
                        text: row[text],
                        createdAt: date,
                        category: row[category]
                    )
                }
            }
        } catch {
            print("Error fetching intention: \(error)")
        }
        return nil
    }

    func updateIntentionCategory(_ intentionId: String, category: String) throws {
        let query = intentions.filter(id == intentionId)
        try db?.run(query.update(self.category <- category))
    }

    // MARK: - Check-Ins

    func saveCheckIn(_ checkIn: CheckIn) throws {
        let insert = checkIns.insert(
            id <- checkIn.id,
            intentionId <- checkIn.intentionId,
            acted <- checkIn.acted,
            reflection <- checkIn.reflection,
            createdAt <- dateFormatter.string(from: checkIn.createdAt)
        )
        try db?.run(insert)
    }

    func getCheckIns(forIntentionId intentionId: String) -> [CheckIn] {
        guard let db = db else { return [] }
        var result: [CheckIn] = []
        do {
            let query = checkIns.filter(self.intentionId == intentionId)
            for row in try db.prepare(query.order(createdAt.desc)) {
                if let date = dateFormatter.date(from: row[createdAt]) {
                    result.append(CheckIn(
                        id: row[id],
                        intentionId: row[self.intentionId],
                        acted: row[acted],
                        reflection: row[reflection],
                        createdAt: date
                    ))
                }
            }
        } catch {
            print("Error fetching check-ins: \(error)")
        }
        return result
    }

    func getAllCheckIns() -> [CheckIn] {
        guard let db = db else { return [] }
        var result: [CheckIn] = []
        do {
            for row in try db.prepare(checkIns.order(createdAt.desc)) {
                if let date = dateFormatter.date(from: row[createdAt]) {
                    result.append(CheckIn(
                        id: row[id],
                        intentionId: row[intentionId],
                        acted: row[acted],
                        reflection: row[reflection],
                        createdAt: date
                    ))
                }
            }
        } catch {
            print("Error fetching all check-ins: \(error)")
        }
        return result
    }

    func getTodaysCheckIn(forIntentionId intentionId: String) -> CheckIn? {
        getCheckIns(forIntentionId: intentionId).first { Calendar.current.isDateInToday($0.createdAt) }
    }

    // MARK: - Breathing Sessions

    func saveBreathingSession(_ session: BreathingSession) throws {
        let insert = breathingSessions.insert(
            id <- session.id,
            pattern <- session.pattern.rawValue,
            durationSeconds <- session.durationSeconds,
            completed <- session.completed,
            createdAt <- dateFormatter.string(from: session.createdAt)
        )
        try db?.run(insert)
    }

    func updateBreathingSessionCompleted(_ sessionId: String, completed: Bool) throws {
        let query = breathingSessions.filter(id == sessionId)
        try db?.run(query.update(self.completed <- completed))
    }

    func getBreathingSessions() -> [BreathingSession] {
        guard let db = db else { return [] }
        var result: [BreathingSession] = []
        do {
            for row in try db.prepare(breathingSessions.order(createdAt.desc)) {
                if let date = dateFormatter.date(from: row[createdAt]),
                   let patternEnum = BreathingPattern(rawValue: row[pattern]) {
                    result.append(BreathingSession(
                        id: row[id],
                        pattern: patternEnum,
                        durationSeconds: row[durationSeconds],
                        completed: row[completed],
                        createdAt: date
                    ))
                }
            }
        } catch {
            print("Error fetching breathing sessions: \(error)")
        }
        return result
    }

    // MARK: - Analytics

    func getIntentionsGroupedByCategory() -> [String: [Intention]] {
        let allIntentions = getIntentions()
        var grouped: [String: [Intention]] = [:]
        for intention in allIntentions {
            let cat = intention.category ?? IntentionCategory.other.rawValue
            grouped[cat, default: []].append(intention)
        }
        return grouped
    }

    func getSuccessRate(forCategory category: String) -> Double {
        let grouped = getIntentionsGroupedByCategory()
        guard let categoryIntentions = grouped[category], !categoryIntentions.isEmpty else {
            return 0
        }
        var successes = 0
        for intention in categoryIntentions {
            let checkIns = getCheckIns(forIntentionId: intention.id)
            if let latestCheckIn = checkIns.first, latestCheckIn.acted {
                successes += 1
            }
        }
        return Double(successes) / Double(categoryIntentions.count) * 100
    }

    // MARK: - Streak

    private let streakDataKey = "streak_data"

    func getStreakData() -> StreakData {
        guard let data = UserDefaults.standard.data(forKey: streakDataKey),
              let streak = try? JSONDecoder().decode(StreakData.self, from: data) else {
            return StreakData()
        }
        return streak
    }

    func updateStreak(checkedIn: Bool, usedFreeze: Bool = false) {
        var streak = getStreakData()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if checkedIn {
            if let lastDate = streak.lastCheckInDate {
                let lastDay = calendar.startOfDay(for: lastDate)
                if lastDay == today {
                    // Already checked in today
                    return
                } else if let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
                          lastDay == yesterday || streak.missedDays.contains(where: { calendar.isDate($0, inSameDayAs: yesterday) }) {
                    // Continuing streak or yesterday was missed but we used freeze
                    if usedFreeze {
                        streak.currentStreak += 1
                    } else {
                        streak.currentStreak += 1
                    }
                } else {
                    // Streak broken, start new
                    streak.currentStreak = 1
                }
            } else {
                streak.currentStreak = 1
            }

            streak.lastCheckInDate = today
            if streak.currentStreak > streak.longestStreak {
                streak.longestStreak = streak.currentStreak
            }
            // Remove today from missed if it was there
            streak.missedDays.removeAll { calendar.isDate($0, inSameDayAs: today) }
        } else {
            // Missed day
            if streak.lastCheckInDate != nil && !calendar.isDateInToday(streak.lastCheckInDate!) {
                if !streak.missedDays.contains(where: { calendar.isDate($0, inSameDayAs: today) }) {
                    streak.missedDays.append(today)
                }
                // Only reset if yesterday wasn't checked in and we didn't use freeze
                if !usedFreeze {
                    streak.currentStreak = 0
                }
            }
        }

        saveStreakData(streak)
    }

    func useStreakFreeze() -> Bool {
        var streak = getStreakData()
        guard streak.streakFreezes > 0 else { return false }
        streak.streakFreezes -= 1
        streak.currentStreak += 1
        if streak.currentStreak > streak.longestStreak {
            streak.longestStreak = streak.currentStreak
        }
        saveStreakData(streak)
        return true
    }

    func addStreakFreeze() {
        var streak = getStreakData()
        streak.streakFreezes += 1
        saveStreakData(streak)
    }

    func streakAnniversary() -> String? {
        let streak = getStreakData()
        let milestones = [7, 14, 21, 30, 60, 90, 100, 365]
        if let milestone = milestones.first(where: { $0 == streak.currentStreak }) {
            return "You hit \(milestone) days. Intention-setting is now a habit."
        }
        return nil
    }

    private func saveStreakData(_ streak: StreakData) {
        if let data = try? JSONEncoder().encode(streak) {
            UserDefaults.standard.set(data, forKey: streakDataKey)
        }
    }

    // MARK: - Weekly Report

    func generateWeeklyReport() -> String? {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        let intentions = getIntentions().filter { $0.createdAt >= weekAgo }
        guard !intentions.isEmpty else { return nil }

        var lines: [String] = []
        lines.append("This week, you set \(intentions.count) intention\(intentions.count == 1 ? "" : "s").")

        // Success rate
        var successes = 0
        for intention in intentions {
            let checkIns = getCheckIns(forIntentionId: intention.id)
            if let latest = checkIns.first, latest.acted { successes += 1 }
        }
        let rate = intentions.isEmpty ? 0 : Int(Double(successes) / Double(intentions.count) * 100)
        lines.append("You acted on \(rate)% of them.")

        // Deadline correlation
        let deadlineKeywords = ["by ", "today", "tonight", "before"]
        let withDeadline = intentions.filter { intention in
            let text = intention.text.lowercased()
            return deadlineKeywords.contains { text.contains($0) }
        }
        if !withDeadline.isEmpty {
            var deadlineSuccesses = 0
            for intention in withDeadline {
                let checkIns = getCheckIns(forIntentionId: intention.id)
                if let latest = checkIns.first, latest.acted { deadlineSuccesses += 1 }
            }
            let deadlineRate = withDeadline.isEmpty ? 0 : Int(Double(deadlineSuccesses) / Double(withDeadline.count) * 100)
            if deadlineRate > rate {
                lines.append("Intentions with a deadline succeed \(deadlineRate)% of the time — \(deadlineRate - rate)% higher than average.")
            }
        }

        // Category theme
        let grouped = getIntentionsGroupedByCategory()
        let recentGrouped = Dictionary(grouping: intentions) { $0.category ?? "Other" }
        if let dominant = recentGrouped.max(by: { $0.value.count < $1.value.count }) {
            lines.append("This week, \(dominant.key.lowercased()) intentions dominated your practice.")
        }

        return lines.joined(separator: " ")
    }

    // MARK: - Monthly Theme

    func getMonthlyTheme() -> String? {
        let calendar = Calendar.current
        let monthAgo = calendar.date(byAdding: .day, value: -30, to: Date())!
        let intentions = getIntentions().filter { $0.createdAt >= monthAgo }
        guard intentions.count >= 3 else { return nil }

        let recentGrouped = Dictionary(grouping: intentions) { $0.category ?? "Other" }
        guard let dominant = recentGrouped.max(by: { $0.value.count < $1.value.count }) else { return nil }
        guard let allTimeDominant = getIntentionsGroupedByCategory().max(by: { $0.value.count < $1.value.count }) else { return nil }

        if dominant.key != allTimeDominant.key {
            return "This month you set a lot of \(dominant.key.lowercased()) intentions. \(allTimeDominant.key.lowercased()) intentions dropped."
        } else {
            return "\(dominant.key.lowercased()) has been your consistent focus this month."
        }
    }

    // MARK: - Breathing History

    func getBreathingHistory() -> [BreathingSession] {
        return getBreathingSessions()
    }
}
