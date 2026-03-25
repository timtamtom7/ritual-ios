import Foundation

/// Generates AI-like narrative insights from ritual data
struct NarrativeInsight: Identifiable {
    let id = UUID()
    let type: InsightType
    let headline: String
    let body: String
    let icon: String
    let priority: Int // lower = more important

    enum InsightType {
        case pattern
        case correlation
        case theme
        case recommendation
    }
}

@MainActor
final class NarrativeService {
    static let shared = NarrativeService()
    private let database = DatabaseService.shared

    private init() {}

    /// Generates a rich narrative summary of the week's ritual practice
    func generateWeeklyNarrative() -> [NarrativeInsight] {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let intentions = database.getIntentions().filter { $0.createdAt >= weekAgo }
        let allIntentions = database.getIntentions()

        var insights: [NarrativeInsight] = []

        guard !intentions.isEmpty else {
            return [NarrativeInsight(
                type: .recommendation,
                headline: "A fresh week awaits",
                body: "You haven't set any intentions this week. Each day is a new opportunity to begin.",
                icon: "sunrise",
                priority: 0
            )]
        }

        // Overall rhythm
        let weekdayIntentions = intentions.filter { calendar.component(.weekday, from: $0.createdAt) != 1 && calendar.component(.weekday, from: $0.createdAt) != 7 }
        let weekendIntentions = intentions.filter { calendar.component(.weekday, from: $0.createdAt) == 1 || calendar.component(.weekday, from: $0.createdAt) == 7 }

        if !weekdayIntentions.isEmpty && !weekendIntentions.isEmpty {
            insights.append(NarrativeInsight(
                type: .pattern,
                headline: "Weekend warrior",
                body: "You set \(weekendIntentions.count) intention\(weekendIntentions.count == 1 ? "" : "s") on weekends and \(weekdayIntentions.count) on weekdays. Consistency across the whole week strengthens the practice.",
                icon: "calendar",
                priority: 2
            ))
        } else if weekdayIntentions.count > weekendIntentions.count * 2 {
            insights.append(NarrativeInsight(
                type: .pattern,
                headline: "Weekday focus",
                body: "Your intentions are concentrated on weekdays. Consider bringing that same intention to your weekends.",
                icon: "calendar.badge.clock",
                priority: 3
            ))
        }

        // Success analysis
        var weeklySuccesses = 0
        for intention in intentions {
            let checkIns = database.getCheckIns(forIntentionId: intention.id)
            if let latest = checkIns.first, latest.acted { weeklySuccesses += 1 }
        }
        let weeklyRate = intentions.isEmpty ? 0 : Double(weeklySuccesses) / Double(intentions.count)

        if weeklyRate >= 0.8 {
            insights.append(NarrativeInsight(
                type: .theme,
                headline: "A week of alignment",
                body: "You acted on \(Int(weeklyRate * 100))% of your intentions this week. That's remarkable commitment. Your intentions and your actions are in strong harmony.",
                icon: "checkmark.seal.fill",
                priority: 0
            ))
        } else if weeklyRate >= 0.5 {
            insights.append(NarrativeInsight(
                type: .theme,
                headline: "Halfway there, building momentum",
                body: "\(Int(weeklyRate * 100))% of your intentions led to action this week. Each check-in, win or not, is data. You're learning what pushes and what pulls.",
                icon: "arrow.up.right",
                priority: 1
            ))
        } else if weeklyRate < 0.3 && intentions.count >= 3 {
            insights.append(NarrativeInsight(
                type: .recommendation,
                headline: "Something is in the way",
                body: "Only \(Int(weeklyRate * 100))% of intentions translated to action this week. Look at what's blocking — is it energy, environment, or something deeper? Sometimes a smaller, simpler intention is the way forward.",
                icon: "questionmark.circle",
                priority: 0
            ))
        }

        // Category analysis
        let recentGrouped = Dictionary(grouping: intentions) { $0.category ?? "Other" }
        if let dominant = recentGrouped.max(by: { $0.value.count < $1.value.count }), dominant.value.count >= 2 {
            let catSuccesses = dominant.value.filter { intention in
                let checkIns = database.getCheckIns(forIntentionId: intention.id)
                return checkIns.first?.acted == true
            }.count
            let catRate = Double(catSuccesses) / Double(dominant.value.count)

            let categoryStatements: [String: String] = [
                "Work": "Work intentions show \(Int(catRate * 100))% success this week.",
                "Health": "Health-related intentions — your body is listening. \(Int(catRate * 100))% success.",
                "Relationships": "Relationships take energy and attention. \(Int(catRate * 100))% of your relational intentions resonated this week.",
                "Growth": "Your growth intentions succeeded \(Int(catRate * 100))% of the time.",
                "Other": "Your intentions this week had a \(Int(catRate * 100))% follow-through rate."
            ]
            insights.append(NarrativeInsight(
                type: .correlation,
                headline: "\(dominant.key) dominates",
                body: categoryStatements[dominant.key] ?? "Your \(dominant.key.lowercased()) intentions led to action \(Int(catRate * 100))% of the time.",
                icon: IntentionCategory(rawValue: dominant.key)?.icon ?? "sparkle",
                priority: 2
            ))
        }

        // Length analysis
        let longIntentions = intentions.filter { $0.text.count > 80 }
        let shortIntentions = intentions.filter { $0.text.count <= 40 }
        if !longIntentions.isEmpty && !shortIntentions.isEmpty {
            var longSuccesses = 0
            for intention in longIntentions {
                let checkIns = database.getCheckIns(forIntentionId: intention.id)
                if checkIns.first?.acted == true { longSuccesses += 1 }
            }
            var shortSuccesses = 0
            for intention in shortIntentions {
                let checkIns = database.getCheckIns(forIntentionId: intention.id)
                if checkIns.first?.acted == true { shortSuccesses += 1 }
            }
            let longRate = Double(longSuccesses) / Double(longIntentions.count)
            let shortRate = Double(shortSuccesses) / Double(shortIntentions.count)

            if abs(longRate - shortRate) > 0.2 {
                let longer = longRate > shortRate ? "longer, more specific" : "shorter, focused"
                let shorter = longRate > shortRate ? "shorter" : "longer"
                insights.append(NarrativeInsight(
                    type: .recommendation,
                    headline: "Brevity matters",
                    body: "Your \(longer) intentions succeed more often. Try \(shorter) ones if you're not seeing results.",
                    icon: "text.alignleft",
                    priority: 3
                ))
            }
        }

        // Time-of-day analysis
        let morningIntentions = intentions.filter {
            let hour = calendar.component(.hour, from: $0.createdAt)
            return hour < 12
        }
        let eveningIntentions = intentions.filter {
            let hour = calendar.component(.hour, from: $0.createdAt)
            return hour >= 18
        }
        if !morningIntentions.isEmpty && !eveningIntentions.isEmpty {
            var morningSuccesses = 0
            for intention in morningIntentions {
                if database.getCheckIns(forIntentionId: intention.id).first?.acted == true {
                    morningSuccesses += 1
                }
            }
            var eveningSuccesses = 0
            for intention in eveningIntentions {
                if database.getCheckIns(forIntentionId: intention.id).first?.acted == true {
                    eveningSuccesses += 1
                }
            }
            let morningRate = Double(morningSuccesses) / Double(morningIntentions.count)
            let eveningRate = Double(eveningSuccesses) / Double(eveningIntentions.count)

            if morningRate > eveningRate {
                insights.append(NarrativeInsight(
                    type: .pattern,
                    headline: "Morning intentions lead",
                    body: "Intentions set before noon succeed \(Int(morningRate * 100))% of the time, vs \(Int(eveningRate * 100))% for evening. The early hours carry weight.",
                    icon: "sunrise",
                    priority: 2
                ))
            } else if eveningRate > morningRate {
                insights.append(NarrativeInsight(
                    type: .pattern,
                    headline: "Evening resonates",
                    body: "Evening intentions succeed \(Int(eveningRate * 100))% of the time, vs \(Int(morningRate * 100))% for morning. You're a twilight practitioner.",
                    icon: "moon.stars",
                    priority: 2
                ))
            }
        }

        // Reflection patterns
        let reflectionsWithContent = intentions.compactMap { intention -> String? in
            guard let checkIn = database.getCheckIns(forIntentionId: intention.id).first,
                  let reflection = checkIn.reflection,
                  !reflection.isEmpty else { return nil }
            return reflection
        }
        if reflectionsWithContent.count >= 3 {
            insights.append(NarrativeInsight(
                type: .pattern,
                headline: "Reflection builds awareness",
                body: "You've written \(reflectionsWithContent.count) reflections this week. The practice of articulating what got in the way is itself a form of intention-setting.",
                icon: "pencil.and.list",
                priority: 3
            ))
        }

        return insights.sorted { $0.priority < $1.priority }
    }

    /// Generates a sleep-to-intention success correlation report
    func analyzeSleepCorrelation() -> SleepCorrelation? {
        let allIntentions = database.getIntentions()
        guard allIntentions.count >= 5 else { return nil }

        let calendar = Calendar.current
        // Group by weekday to approximate sleep patterns
        var weekdaySuccessRates: [Int: (successes: Int, total: Int)] = [:]
        for intention in allIntentions {
            let weekday = calendar.component(.weekday, from: intention.createdAt)
            var current = weekdaySuccessRates[weekday] ?? (0, 0)
            current.total += 1
            if database.getCheckIns(forIntentionId: intention.id).first?.acted == true {
                current.successes += 1
            }
            weekdaySuccessRates[weekday] = current
        }

        // Sunday (1) and Monday (2) often have disrupted sleep patterns
        // Calculate correlation between early-week (disrupted) vs late-week (settled)
        let earlyWeek = [1, 2].compactMap { weekdaySuccessRates[$0] }
        let lateWeek = [5, 6, 7].compactMap { weekdaySuccessRates[$0] }

        guard !earlyWeek.isEmpty && !lateWeek.isEmpty else { return nil }

        let earlyAvg = Double(earlyWeek.reduce(0) { $0 + $1.successes }) / Double(earlyWeek.reduce(0) { $0 + $1.total })
        let lateAvg = Double(lateWeek.reduce(0) { $0 + $1.successes }) / Double(lateWeek.reduce(0) { $0 + $1.total })

        let diff = lateAvg - earlyAvg

        if abs(diff) < 0.05 {
            return SleepCorrelation(
                pattern: .neutral,
                headline: "Consistent success across the week",
                body: "Your intention success is steady regardless of the day. You've built a practice that doesn't depend on external rhythms."
            )
        } else if diff > 0.1 {
            return SleepCorrelation(
                pattern: .betterWithSettledSleep,
                headline: "Rested days = better alignment",
                body: "Success rates are higher later in the week, after you've settled into routines. Consider how sleep and recovery affect your follow-through."
            )
        } else {
            return SleepCorrelation(
                pattern: .strongerWhenTired,
                headline: "You rise to the challenge when tired",
                body: "Early-week intentions succeed more despite potential fatigue. You may be more intentional when your body is still waking up."
            )
        }
    }

    /// Detects calendar conflicts for today's intention window
    func checkCalendarConflicts() -> CalendarConflictReport? {
        let conflicts = CalendarService.shared.conflictingEventsForToday()
        guard !conflicts.isEmpty else { return nil }

        let eventTitles = conflicts.prefix(3).map { $0.title ?? "Untitled" }
        return CalendarConflictReport(
            hasConflicts: true,
            conflictingTitles: Array(eventTitles),
            headline: "\(conflicts.count) event\(conflicts.count == 1 ? "" : "s") today may compete for attention",
            body: "You have \"\(eventTitles.joined(separator: "\", \""))\" on your calendar today. These may affect your ability to act on today's intention."
        )
    }

    /// R7: Generates a rich monthly ritual narrative
    func generateMonthlyNarrative() -> MonthlyNarrative {
        let calendar = Calendar.current
        let now = Date()
        let monthAgo = calendar.date(byAdding: .day, value: -30, to: now) ?? now
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now

        let intentions = database.getIntentions().filter { $0.createdAt >= monthStart }
        let allIntentions = database.getIntentions()

        let season = SeasonService.shared.currentSeason

        // Overall stats
        let totalIntentions = intentions.count
        var successfulIntentions = 0
        for intention in intentions {
            let checkIns = database.getCheckIns(forIntentionId: intention.id)
            if checkIns.first?.acted == true { successfulIntentions += 1 }
        }
        let successRate = totalIntentions > 0 ? Double(successfulIntentions) / Double(totalIntentions) : 0

        // Category breakdown
        let categoryBreakdown = Dictionary(grouping: intentions) { $0.category ?? "Other" }
            .mapValues { intentions -> (total: Int, successful: Int) in
                var successes = 0
                for intention in intentions {
                    let checkIns = database.getCheckIns(forIntentionId: intention.id)
                    if checkIns.first?.acted == true { successes += 1 }
                }
                return (intentions.count, successes)
            }
            .sorted { $0.value.total > $1.value.total }

        // Breathing practice
        let breathingSessions = database.getBreathingSessions().filter { $0.createdAt >= monthStart }
        let completedBreathing = breathingSessions.filter { $0.completed }.count
        let breathingMinutes = breathingSessions.reduce(0) { $0 + $1.durationSeconds } / 60

        // Consistency
        let uniqueDays = Set(intentions.map { calendar.startOfDay(for: $0.createdAt) }).count
        let daysInMonth = calendar.ordinality(of: .day, in: .year, for: now) ?? 30

        // Compare to previous month
        let prevMonthStart = calendar.date(byAdding: .month, value: -1, to: monthStart) ?? monthStart
        let prevMonthIntentions = allIntentions.filter { $0.createdAt >= prevMonthStart && $0.createdAt < monthStart }
        var prevMonthSuccesses = 0
        for intention in prevMonthIntentions {
            let checkIns = database.getCheckIns(forIntentionId: intention.id)
            if checkIns.first?.acted == true { prevMonthSuccesses += 1 }
        }
        let prevMonthRate = prevMonthIntentions.isEmpty ? 0 : Double(prevMonthSuccesses) / Double(prevMonthIntentions.count)
        let rateChange = successRate - prevMonthRate

        // Theme
        let dominantCategory = categoryBreakdown.first.map { $0.key }

        // Narrative paragraphs
        var opening: String
        if totalIntentions == 0 {
            opening = "This month has been quiet on the ritual front — no intentions set yet. The practice is always available to you."
        } else if successRate >= 0.8 {
            opening = "This has been a month of deep alignment. \(totalIntentions) intentions set, \(Int(successRate * 100))% followed through. Your practice is maturing."
        } else if successRate >= 0.5 {
            opening = "This month brought \(totalIntentions) intentions and a \(Int(successRate * 100))% follow-through rate. You're building something real."
        } else if totalIntentions > 0 {
            opening = "This month you set \(totalIntentions) intentions. The rate of follow-through — \(Int(successRate * 100))% — tells a story worth reading."
        } else {
            opening = "Ritual continues, even in quiet months. Your practice is not gone, only resting."
        }

        var categoryStory: String
        if let dominant = dominantCategory, categoryBreakdown.count > 0 {
            let stats = categoryBreakdown.first!.value
            let catRate = stats.total > 0 ? Double(stats.successful) / Double(stats.total) : 0
            categoryStory = "Your \(dominant.lowercased()) intentions led the month, appearing \(stats.total) times with \(Int(catRate * 100))% success."

            if categoryBreakdown.count > 1 {
                let secondStats = categoryBreakdown[1].value
                categoryStory += " \(categoryBreakdown[1].key.lowercased()) intentions (\(secondStats.total) total) followed."
            }
        } else {
            categoryStory = "Your intentions were varied, spanning multiple life areas."
        }

        var breathStory: String
        if breathingSessions.isEmpty {
            breathStory = "Breathing sessions were absent this month. When you're ready, a single session can reset everything."
        } else {
            breathStory = "You completed \(completedBreathing) of \(breathingSessions.count) breathing sessions — \(breathingMinutes) minutes of conscious breath in total."
        }

        var changeStory: String
        if rateChange > 0.1 {
            changeStory = "Your follow-through improved by \(Int(rateChange * 100))% compared to last month. Something is working."
        } else if rateChange < -0.1 {
            changeStory = "Follow-through dropped \(Int(abs(rateChange) * 100))% versus last month. Consider what changed — environment, energy, or something else."
        } else {
            changeStory = "Consistency held steady across the month. Your practice is becoming predictable — which is a strength."
        }

        var seasonalStory: String
        seasonalStory = "As \(season.rawValue.lowercased()) settles in — \(season.description) — let this season's theme of \(season.theme.lowercased()) guide next month's intentions."

        let seasonSuggestions = season.suggestedIntentions.prefix(2).map { "\"\($0)\"" }.joined(separator: " or ")
        seasonalStory += " Consider intentions like \(seasonSuggestions)."

        return MonthlyNarrative(
            month: calendar.component(.month, from: now),
            year: calendar.component(.year, from: now),
            season: season,
            totalIntentions: totalIntentions,
            successfulIntentions: successfulIntentions,
            successRate: successRate,
            rateChangeVsLastMonth: rateChange,
            uniquePracticeDays: uniqueDays,
            breathingSessionsCount: breathingSessions.count,
            breathingMinutesTotal: breathingMinutes,
            dominantCategory: dominantCategory,
            openingParagraph: opening,
            categoryParagraph: categoryStory,
            breathParagraph: breathStory,
            changeParagraph: changeStory,
            seasonalParagraph: seasonalStory
        )
    }
}

struct MonthlyNarrative: Identifiable {
    let id = UUID()
    let month: Int
    let year: Int
    let season: RitualSeason
    let totalIntentions: Int
    let successfulIntentions: Int
    let successRate: Double
    let rateChangeVsLastMonth: Double
    let uniquePracticeDays: Int
    let breathingSessionsCount: Int
    let breathingMinutesTotal: Int
    let dominantCategory: String?
    let openingParagraph: String
    let categoryParagraph: String
    let breathParagraph: String
    let changeParagraph: String
    let seasonalParagraph: String

    var monthName: String {
        let names = ["", "January", "February", "March", "April", "May", "June",
                     "July", "August", "September", "October", "November", "December"]
        return names[month]
    }
}

struct SleepCorrelation {
    enum Pattern {
        case neutral
        case betterWithSettledSleep
        case strongerWhenTired
    }

    let pattern: Pattern
    let headline: String
    let body: String
}

struct CalendarConflictReport {
    let hasConflicts: Bool
    let conflictingTitles: [String]
    let headline: String
    let body: String
}
