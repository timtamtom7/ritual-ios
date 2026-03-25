import Foundation

enum RitualSeason: String, CaseIterable {
    case spring = "Spring"
    case summer = "Summer"
    case autumn = "Autumn"
    case winter = "Winter"

    var months: [Int] {
        switch self {
        case .spring: return [3, 4, 5]
        case .summer: return [6, 7, 8]
        case .autumn: return [9, 10, 11]
        case .winter: return [12, 1, 2]
        }
    }

    var icon: String {
        switch self {
        case .spring: return "leaf.fill"
        case .summer: return "sun.max.fill"
        case .autumn: return "wind"
        case .winter: return "snowflake"
        }
    }

    var theme: String {
        switch self {
        case .spring: return "Renewal & Growth"
        case .summer: return "Vibrance & Vitality"
        case .autumn: return "Harvest & Reflection"
        case .winter: return "Rest & Restoration"
        }
    }

    var description: String {
        switch self {
        case .spring: return "A time for new beginnings, planting seeds, and embracing growth."
        case .summer: return "Full expression, energy in motion, and enjoying the fruits of effort."
        case .autumn: return "Gathering wisdom, releasing what no longer serves, and gratitude."
        case .winter: return "Deep rest, inner work, and quiet restoration before renewal."
        }
    }

    var suggestedIntentions: [String] {
        switch self {
        case .spring:
            return [
                "Today, I intend to begin something new with courage",
                "Today, I intend to nurture growth in myself and others",
                "Today, I intend to embrace change as an invitation"
            ]
        case .summer:
            return [
                "Today, I intend to live with full presence and joy",
                "Today, I intend to act boldly on what matters most",
                "Today, I intend to share my energy generously"
            ]
        case .autumn:
            return [
                "Today, I intend to appreciate what has ripened",
                "Today, I intend to release what no longer belongs",
                "Today, I intend to find beauty in the letting go"
            ]
        case .winter:
            return [
                "Today, I intend to honor my need for rest",
                "Today, I intend to turn inward with curiosity",
                "Today, I intend to be gentle with myself"
            ]
        }
    }

    var breathingPatternSuggestion: BreathingPattern {
        switch self {
        case .spring: return .box
        case .summer: return .energize
        case .autumn: return .coherent
        case .winter: return .sleep
        }
    }

    var accentColor: String {
        switch self {
        case .spring: return "7A9E7A"
        case .summer: return "C9A96E"
        case .autumn: return "C4956A"
        case .winter: return "9B9BAA"
        }
    }

    static func current(for date: Date = Date()) -> RitualSeason {
        let month = Calendar.current.component(.month, from: date)
        return allCases.first { $0.months.contains(month) } ?? .spring
    }
}

@MainActor
final class SeasonService {
    static let shared = SeasonService()

    private init() {}

    var currentSeason: RitualSeason {
        RitualSeason.current()
    }

    var seasonalTheme: String {
        currentSeason.theme
    }

    var seasonalSuggestion: String {
        let suggestions = currentSeason.suggestedIntentions
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return suggestions[dayOfYear % suggestions.count]
    }

    var seasonDescription: String {
        currentSeason.description
    }

    func daysUntilNextSeason() -> Int {
        let calendar = Calendar.current
        let today = Date()
        let currentMonth = calendar.component(.month, from: today)

        // Find next season month
        let allMonths = [3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 1, 2]
        var nextSeasonMonth = allMonths.first { $0 > currentMonth } ?? allMonths.first!

        var components = calendar.dateComponents([.year], from: today)
        components.month = nextSeasonMonth
        components.day = 1

        if nextSeasonMonth <= currentMonth {
            components.year = (components.year ?? 0) + 1
        }

        guard let nextSeasonDate = calendar.date(from: components) else { return 0 }
        return max(0, calendar.dateComponents([.day], from: today, to: nextSeasonDate).day ?? 0)
    }

    func monthNarrative(for date: Date = Date()) -> String {
        let season = RitualSeason.current(for: date)
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)

        let monthNames = [
            1: "January", 2: "February", 3: "March", 4: "April",
            5: "May", 6: "June", 7: "July", 8: "August",
            9: "September", 10: "October", 11: "November", 12: "December"
        ]

        let monthName = monthNames[month] ?? ""

        let templates = [
            "In \(monthName) of \(year), we are in the season of \(season.rawValue.lowercased()). \(season.description) This is a month to \(seasonThemeAction(season)).",
            "\(monthName) arrives with the energy of \(season.rawValue): \(season.theme.lowercased()). \(season.description) Let this month be one of \(seasonThemeAction(season)).",
            "As \(season.rawValue) settles in for \(monthName), the ritual invites you toward \(season.theme.lowercased()). \(season.description) This month's practice: \(seasonThemeAction(season))."
        ]

        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        return templates[dayOfYear % templates.count]
    }

    private func seasonThemeAction(_ season: RitualSeason) -> String {
        switch season {
        case .spring: return "planting new seeds and trusting growth"
        case .summer: return "expressing fully and enjoying the warmth"
        case .autumn: return "harvesting what worked and releasing the rest"
        case .winter: return "resting deeply and dreaming quietly"
        }
    }
}
