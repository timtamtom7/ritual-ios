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
}
