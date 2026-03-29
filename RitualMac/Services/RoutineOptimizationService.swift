import Foundation

/// Routine Optimization Service
/// Analyzes completion rates by time of day and day of week,
/// identifies optimal times for new rituals, and detects overload.
@MainActor
final class RoutineOptimizationService {
    static let shared = RoutineOptimizationService()

    private let database = DatabaseService.shared

    private init() {}

    // MARK: - Time Slot Analysis

    struct TimeSlotAnalysis {
        let timeOfDay: String
        let totalIntentions: Int
        let successfulCheckIns: Int
        let completionRate: Double
        let recommendations: [String]
    }

    // MARK: - Day of Week Analysis

    struct DayOfWeekAnalysis {
        let dayName: String
        let weekday: Int
        let totalIntentions: Int
        let successfulCheckIns: Int
        let completionRate: Double
        let isChallenging: Bool
    }

    // MARK: - Routine Overload

    struct OverloadWarning: Identifiable {
        let id = UUID()
        let severity: Severity
        let message: String
        let suggestion: String

        enum Severity: String {
            case warning = "Warning"
            case critical = "Critical"
            case info = "Info"
        }
    }

    // MARK: - Optimal Time

    struct OptimalTime: Identifiable {
        let id = UUID()
        let timeOfDay: String
        let description: String
        let completionRate: Double
        let bestRituals: [String]
    }

    // MARK: - Duration Suggestion

    struct DurationSuggestion: Identifiable {
        let id = UUID()
        let ritualType: String
        let suggestedDuration: String
        let reason: String
    }

    // MARK: - Analyze Completion by Time of Day

    /// Analyze completion rates by time of day
    func analyzeByTimeOfDay() -> [TimeSlotAnalysis] {
        let intentions = database.getIntentions()
        let checkIns = database.getAllCheckIns()
        let calendar = Calendar.current

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

        var analyses: [TimeSlotAnalysis] = []

        // Morning analysis
        let morningSuccesses = countSuccessfulCheckIns(for: morningIntentions, checkIns: checkIns)
        let morningRate = morningIntentions.isEmpty ? 0 : Double(morningSuccesses) / Double(morningIntentions.count) * 100
        var morningRecs: [String] = []
        if morningRate < 50 {
            morningRecs.append("Consider a shorter morning ritual or moving intention-setting to a less busy time")
        }
        if morningIntentions.count > 5 {
            morningRecs.append("Your morning is quite packed — consider moving some intentions to afternoon")
        }
        if morningRate > 70 {
            morningRecs.append("Your morning routine is your strongest — continue what works")
        }
        analyses.append(TimeSlotAnalysis(
            timeOfDay: "Morning",
            totalIntentions: morningIntentions.count,
            successfulCheckIns: morningSuccesses,
            completionRate: morningRate,
            recommendations: morningRecs
        ))

        // Afternoon analysis
        let afternoonSuccesses = countSuccessfulCheckIns(for: afternoonIntentions, checkIns: checkIns)
        let afternoonRate = afternoonIntentions.isEmpty ? 0 : Double(afternoonSuccesses) / Double(afternoonIntentions.count) * 100
        var afternoonRecs: [String] = []
        if afternoonRate < 50 {
            afternoonRecs.append("Afternoon intentions are harder to track — consider grouping them with morning or evening")
        }
        if afternoonRate > 70 {
            afternoonRecs.append("Afternoon is a hidden strength for you")
        }
        analyses.append(TimeSlotAnalysis(
            timeOfDay: "Afternoon",
            totalIntentions: afternoonIntentions.count,
            successfulCheckIns: afternoonSuccesses,
            completionRate: afternoonRate,
            recommendations: afternoonRecs
        ))

        // Evening analysis
        let eveningSuccesses = countSuccessfulCheckIns(for: eveningIntentions, checkIns: checkIns)
        let eveningRate = eveningIntentions.isEmpty ? 0 : Double(eveningSuccesses) / Double(eveningIntentions.count) * 100
        var eveningRecs: [String] = []
        if eveningRate < 50 {
            eveningRecs.append("Evening rituals often get missed — try a shorter wind-down or reminder")
        }
        if eveningRate > 70 {
            eveningRecs.append("Evening reflection is powerful for you — keep it consistent")
        }
        analyses.append(TimeSlotAnalysis(
            timeOfDay: "Evening",
            totalIntentions: eveningIntentions.count,
            successfulCheckIns: eveningSuccesses,
            completionRate: eveningRate,
            recommendations: eveningRecs
        ))

        return analyses
    }

    // MARK: - Analyze by Day of Week

    /// Analyze completion rates by day of week
    func analyzeByDayOfWeek() -> [DayOfWeekAnalysis] {
        let intentions = database.getIntentions()
        let checkIns = database.getAllCheckIns()
        let calendar = Calendar.current

        let dayNames = ["", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        var analyses: [DayOfWeekAnalysis] = []

        for weekday in 1...7 {
            let dayIntentions = intentions.filter { calendar.component(.weekday, from: $0.createdAt) == weekday }
            let successes = countSuccessfulCheckIns(for: dayIntentions, checkIns: checkIns)
            let rate = dayIntentions.isEmpty ? 0 : Double(successes) / Double(dayIntentions.count) * 100

            let isChallenging = weekday == 2 || weekday == 3 // Monday and Tuesday often challenging

            analyses.append(DayOfWeekAnalysis(
                dayName: dayNames[weekday],
                weekday: weekday,
                totalIntentions: dayIntentions.count,
                successfulCheckIns: successes,
                completionRate: rate,
                isChallenging: isChallenging
            ))
        }

        return analyses
    }

    // MARK: - Find Optimal Times

    /// Identify optimal times for different types of rituals
    func findOptimalTimes() -> [OptimalTime] {
        let timeAnalysis = analyzeByTimeOfDay()
        var optimalTimes: [OptimalTime] = []

        // Find best performing time slot
        let bestSlot = timeAnalysis.max(by: { $0.completionRate < $1.completionRate })

        if let best = bestSlot, best.totalIntentions > 0 {
            optimalTimes.append(OptimalTime(
                timeOfDay: best.timeOfDay,
                description: "Your \(best.timeOfDay.lowercased()) completion rate is \(Int(best.completionRate))% — your best time for rituals",
                completionRate: best.completionRate,
                bestRituals: getBestRitualsForTime(best.timeOfDay)
            ))
        }

        // Find worst performing time slot
        let worstSlot = timeAnalysis.min(by: { $0.completionRate < $1.completionRate })
        if let worst = worstSlot, worst.totalIntentions > 0, worst.completionRate < 50 {
            optimalTimes.append(OptimalTime(
                timeOfDay: worst.timeOfDay,
                description: "Your \(worst.timeOfDay.lowercased()) is challenging (\(Int(worst.completionRate))% rate) — consider adjusting expectations",
                completionRate: worst.completionRate,
                bestRituals: []
            ))
        }

        // Day of week analysis
        let dayAnalysis = analyzeByDayOfWeek()
        let bestDay = dayAnalysis.max(by: { $0.completionRate < $1.completionRate })
        if let best = bestDay, best.totalIntentions >= 2 {
            optimalTimes.append(OptimalTime(
                timeOfDay: best.dayName,
                description: "\(best.dayName)s show your highest intention adherence",
                completionRate: best.completionRate,
                bestRituals: []
            ))
        }

        return optimalTimes
    }

    private func getBestRitualsForTime(_ timeOfDay: String) -> [String] {
        switch timeOfDay {
        case "Morning":
            return [
                "Daily intention setting",
                "Morning breathing or meditation",
                "Priority setting for the day"
            ]
        case "Afternoon":
            return [
                "Midday check-in and reset",
                "Movement or stretch break",
                "Progress review"
            ]
        case "Evening":
            return [
                "Evening reflection",
                "Gratitude practice",
                "Wind-down ritual"
            ]
        default:
            return []
        }
    }

    // MARK: - Detect Overload

    /// Detect ritual overload and suggest adjustments
    func detectOverload() -> [OverloadWarning] {
        var warnings: [OverloadWarning] = []
        let intentions = database.getIntentions()
        let calendar = Calendar.current

        // Check today's load
        let todayIntentions = intentions.filter { calendar.isDateInToday($0.createdAt) }
        if todayIntentions.count > 5 {
            warnings.append(OverloadWarning(
                severity: .warning,
                message: "Today's routine has \(todayIntentions.count) intentions — this is above average",
                suggestion: "Consider consolidating to 3-4 key intentions for better focus"
            ))
        }

        // Check morning load specifically
        let morningIntentions = intentions.filter {
            let hour = calendar.component(.hour, from: $0.createdAt)
            return hour >= 5 && hour < 12 && calendar.isDateInToday($0.createdAt)
        }
        if morningIntentions.count > 3 {
            warnings.append(OverloadWarning(
                severity: .critical,
                message: "Your morning is too packed — \(morningIntentions.count) rituals scheduled",
                suggestion: "Consider moving exercise or non-essential rituals to lunch or evening"
            ))
        }

        // Check for rapid-fire intentions
        let recentIntentions = intentions.filter {
            guard let daysAgo = calendar.date(byAdding: .day, value: -3, to: Date()) else { return false }
            return $0.createdAt >= daysAgo
        }
        if recentIntentions.count > 15 {
            warnings.append(OverloadWarning(
                severity: .info,
                message: "You've set \(recentIntentions.count) intentions in 3 days — high intensity",
                suggestion: "Quality over quantity. Focus on 1-2 meaningful intentions per day"
            ))
        }

        // Check for conflicting time slots
        let timeAnalysis = analyzeByTimeOfDay()
        let crowdedSlots = timeAnalysis.filter { $0.totalIntentions > 4 }
        for slot in crowdedSlots {
            warnings.append(OverloadWarning(
                severity: .warning,
                message: "\(slot.timeOfDay) is crowded with \(slot.totalIntentions) intentions",
                suggestion: "Try spreading intentions across different times for better adherence"
            ))
        }

        return warnings
    }

    // MARK: - Suggest Duration Adjustments

    /// Suggest ritual duration adjustments based on completion rates
    func suggestDurationAdjustments() -> [DurationSuggestion] {
        var suggestions: [DurationSuggestion] = []

        let checkIns = database.getAllCheckIns()
        let breathingSessions = database.getBreathingSessions()

        // Analyze breathing session completion
        let completedSessions = breathingSessions.filter { $0.completed }
        let incompleteSessions = breathingSessions.filter { !$0.completed }

        if breathingSessions.count >= 3 {
            let completionRate = Double(completedSessions.count) / Double(breathingSessions.count)

            if completionRate < 0.5 {
                suggestions.append(DurationSuggestion(
                    ritualType: "Breathing Sessions",
                    suggestedDuration: "1-2 minutes",
                    reason: "Your breathing sessions often go incomplete — shorter sessions may improve adherence"
                ))
            } else if completionRate > 0.8 {
                suggestions.append(DurationSuggestion(
                    ritualType: "Breathing Sessions",
                    suggestedDuration: "3-5 minutes",
                    reason: "You consistently complete breathing sessions — ready for longer practice"
                ))
            }
        }

        // Analyze check-in patterns
        let intentions = database.getIntentions()
        let intentionsWithReflection = checkIns.filter { $0.reflection != nil && !$0.reflection!.isEmpty }
        let intentionsWithoutReflection = checkIns.filter { $0.reflection == nil || $0.reflection!.isEmpty }

        if intentions.count > 5 && !intentionsWithReflection.isEmpty {
            let reflectionRate = Double(intentionsWithReflection.count) / Double(checkIns.count)
            if reflectionRate < 0.3 {
                suggestions.append(DurationSuggestion(
                    ritualType: "Evening Reflections",
                    suggestedDuration: "30 seconds to 1 minute",
                    reason: "Short reflections may feel less burdensome and still provide value"
                ))
            }
        }

        // Analyze morning routine load
        let calendar = Calendar.current
        let morningIntentions = intentions.filter {
            let hour = calendar.component(.hour, from: $0.createdAt)
            return hour >= 5 && hour < 12
        }
        let morningCompletionRate = calculateCompletionRate(for: morningIntentions, checkIns: checkIns)

        if morningCompletionRate < 60 && morningIntentions.count > 2 {
            suggestions.append(DurationSuggestion(
                ritualType: "Morning Ritual",
                suggestedDuration: "Under 5 minutes",
                reason: "Your morning has high dropout — keeping it under 5 minutes increases consistency"
            ))
        }

        return suggestions
    }

    // MARK: - Weekly Routine Summary

    /// Generate a summary of the user's weekly routine patterns
    func getWeeklyRoutineSummary() -> String {
        let intentions = database.getIntentions()
        let checkIns = database.getAllCheckIns()
        let calendar = Calendar.current

        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let thisWeekIntentions = intentions.filter { $0.createdAt >= weekAgo }

        guard !thisWeekIntentions.isEmpty else {
            return "No intentions set this week yet. Start fresh today!"
        }

        var lines: [String] = []

        // Count by day
        let dayCounts = Dictionary(grouping: thisWeekIntentions) {
            calendar.component(.weekday, from: $0.createdAt)
        }

        let mostActiveDay = dayCounts.max(by: { $0.value.count < $1.value.count })
        let dayNames = ["", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

        if let (day, intentions) = mostActiveDay {
            lines.append("Your most active day is \(dayNames[day]) with \(intentions.count) intention\(intentions.count == 1 ? "" : "s").")
        }

        // Overall completion
        let successes = countSuccessfulCheckIns(for: thisWeekIntentions, checkIns: checkIns)
        let rate = thisWeekIntentions.isEmpty ? 0 : Int(Double(successes) / Double(thisWeekIntentions.count) * 100)
        lines.append("This week: \(rate)% completion rate (\(successes)/\(thisWeekIntentions.count)).")

        // Overload check
        let overloads = detectOverload()
        if let critical = overloads.first(where: { $0.severity == .critical }) {
            lines.append("\(critical.severity.rawValue): \(critical.message)")
            lines.append("Suggestion: \(critical.suggestion)")
        }

        return lines.joined(separator: " ")
    }

    // MARK: - Helper Methods

    private func countSuccessfulCheckIns(for intentions: [Intention], checkIns: [CheckIn]) -> Int {
        var count = 0
        for intention in intentions {
            let relatedCheckIns = checkIns.filter { $0.intentionId == intention.id }
            if let latest = relatedCheckIns.first, latest.acted {
                count += 1
            }
        }
        return count
    }

    private func calculateCompletionRate(for intentions: [Intention], checkIns: [CheckIn]) -> Double {
        guard !intentions.isEmpty else { return 0 }
        let successes = countSuccessfulCheckIns(for: intentions, checkIns: checkIns)
        return Double(successes) / Double(intentions.count)
    }

    // MARK: - Actionable Recommendations

    /// Get a prioritized list of actionable recommendations
    func getActionableRecommendations() -> [String] {
        var recommendations: [String] = []

        let overloads = detectOverload()
        for overload in overloads where overload.severity != .info {
            recommendations.append(overload.suggestion)
        }

        let optimalTimes = findOptimalTimes()
        for time in optimalTimes where time.completionRate > 70 {
            recommendations.append("Double down on your \(time.timeOfDay) routine — it's working well")
        }

        let durationSuggestions = suggestDurationAdjustments()
        for suggestion in durationSuggestions {
            recommendations.append("\(suggestion.ritualType): try \(suggestion.suggestedDuration). \(suggestion.reason)")
        }

        let timeAnalysis = analyzeByTimeOfDay()
        if let worst = timeAnalysis.min(by: { $0.completionRate < $1.completionRate }), worst.completionRate < 40 {
            recommendations.append("Your \(worst.timeOfDay.lowercased()) is your weakest time — consider a different approach or timing")
        }

        return Array(Set(recommendations)).sorted()
    }
}
