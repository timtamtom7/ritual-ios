import Foundation

struct StreakData: Codable {
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var streakFreezes: Int = 1
    var lastCheckInDate: Date?
    var missedDays: [Date] = []

    var hasStreak: Bool { currentStreak > 0 }

    var isStreakActive: Bool {
        guard let lastDate = lastCheckInDate else { return false }
        let calendar = Calendar.current
        if calendar.isDateInToday(lastDate) { return true }
        if calendar.isDateInYesterday(lastDate) { return true }
        return false
    }
}
