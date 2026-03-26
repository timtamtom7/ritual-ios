import Foundation
import HealthKit

struct SleepCorrelationReport: Identifiable {
    let id = UUID()
    let headline: String
    let body: String
    let strength: CorrelationStrength
    let weeklyAverageSleep: Double?
    let intentionSuccessRate: Double
    let daysAnalyzed: Int

    enum CorrelationStrength {
        case strong
        case moderate
        case weak

        var icon: String {
            switch self {
            case .strong: return "arrow.right.arrow.left.circle.fill"
            case .moderate: return "arrow.right.arrow.left.circle"
            case .weak: return "minus.circle"
            }
        }

        var label: String {
            switch self {
            case .strong: return "Strong link"
            case .moderate: return "Moderate link"
            case .weak: return "Weak link"
            }
        }
    }
}

@MainActor
final class HealthKitService: ObservableObject {
    static let shared = HealthKitService()

    private let healthStore = HKHealthStore()

    @Published var isAuthorized: Bool = false
    @Published var todaySleepHours: Double?
    @Published var weeklySleepAverage: Double?
    @Published var sleepHistory: [Date: Double] = [:] // date -> hours of sleep

    private init() {}

    var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization() async -> Bool {
        guard isHealthDataAvailable else { return false }

        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return false
        }

        let typesToRead: Set<HKObjectType> = [sleepType]

        do {
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
            let authorized = healthStore.authorizationStatus(for: sleepType) != .sharingDenied
            await MainActor.run { isAuthorized = authorized }
            return authorized
        } catch {
            print("HealthKit authorization error: \(error)")
            return false
        }
    }

    func fetchTodaysSleep() async {
        guard isHealthDataAvailable else { return }

        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let endOfYesterday = calendar.date(byAdding: .day, value: -1, to: startOfDay) ?? startOfDay
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? now

        let predicate = HKQuery.predicateForSamples(withStart: endOfYesterday, end: endOfToday, options: .strictStartDate)

        let query = HKSampleQuery(
            sampleType: HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: nil
        ) { [weak self] _, samples, error in
            guard error == nil, let samples = samples as? [HKCategorySample] else { return }

            let sleepSamples = samples.filter { $0.value != HKCategoryValueSleepAnalysis.awake.rawValue }
            let totalSleep = sleepSamples.reduce(0.0) { total, sample in
                total + sample.endDate.timeIntervalSince(sample.startDate)
            } / 3600.0 // Convert to hours

            Task { @MainActor in
                self?.todaySleepHours = totalSleep
            }
        }

        healthStore.execute(query)
    }

    func fetchWeeklySleepAverage() async {
        guard isHealthDataAvailable else { return }

        let calendar = Calendar.current
        let now = Date()
        guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) else { return }

        let predicate = HKQuery.predicateForSamples(withStart: weekAgo, end: now, options: .strictStartDate)

        let query = HKSampleQuery(
            sampleType: HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
        ) { [weak self] _, samples, error in
            guard error == nil, let samples = samples as? [HKCategorySample] else { return }

            // Group by day
            let calendar = Calendar.current
            var dailySleep: [Date: Double] = [:]

            for sample in samples {
                guard sample.value != HKCategoryValueSleepAnalysis.awake.rawValue else { continue }
                let day = calendar.startOfDay(for: sample.startDate)
                let duration = sample.endDate.timeIntervalSince(sample.startDate) / 3600.0
                dailySleep[day, default: 0] += duration
            }

            let daysWithSleep = dailySleep.values.filter { $0 >= 4 }.count
            guard daysWithSleep > 0 else { return }

            let average = dailySleep.values.filter { $0 >= 4 }.reduce(0, +) / Double(daysWithSleep)

            Task { @MainActor in
                self?.weeklySleepAverage = average
                self?.sleepHistory = dailySleep
            }
        }

        healthStore.execute(query)
    }

    /// Analyzes correlation between sleep quality and next-day intention success
    func analyzeSleepToIntentionCorrelation() async -> SleepCorrelationReport? {
        await fetchWeeklySleepAverage()

        let sleepAvg = weeklySleepAverage ?? 7.0 // Default assumption if HealthKit unavailable
        let calendar = Calendar.current

        // Get intention history from the last 2 weeks
        let twoWeeksAgo = calendar.date(byAdding: .day, value: -14, to: Date()) ?? Date()
        let intentions = DatabaseService.shared.getIntentions().filter { $0.createdAt >= twoWeeksAgo }

        guard intentions.count >= 4 else { return nil }

        // Analyze each intention's success relative to prior night's sleep
        var wellRestedSuccesses = 0
        var wellRestedTotal = 0
        var poorSleepSuccesses = 0
        var poorSleepTotal = 0

        for intention in intentions {
            // Find the night before (sleep typically happens the previous night)
            guard let nightBefore = calendar.date(byAdding: .day, value: -1, to: intention.createdAt) else { continue }
            let dayKey = calendar.startOfDay(for: nightBefore)

            let sleepHours = sleepHistory[dayKey] ?? 7.0 // Default if no data

            let checkIns = DatabaseService.shared.getCheckIns(forIntentionId: intention.id)
            let wasSuccessful = checkIns.first?.acted == true

            if sleepHours >= 7 {
                wellRestedTotal += 1
                if wasSuccessful { wellRestedSuccesses += 1 }
            } else if sleepHours < 5 {
                poorSleepTotal += 1
                if wasSuccessful { poorSleepSuccesses += 1 }
            }
        }

        guard wellRestedTotal > 0 || poorSleepTotal > 0 else { return nil }

        let wellRestedRate = wellRestedTotal > 0 ? Double(wellRestedSuccesses) / Double(wellRestedTotal) : 0
        let poorSleepRate = poorSleepTotal > 0 ? Double(poorSleepSuccesses) / Double(poorSleepTotal) : 0

        let intentionSuccessRate = wellRestedRate // primary metric

        // Determine correlation strength
        let diff = wellRestedRate - poorSleepRate
        let strength: SleepCorrelationReport.CorrelationStrength
        let headline: String
        let body: String

        if wellRestedTotal >= 3 && poorSleepTotal >= 2 {
            if diff > 0.25 {
                strength = .strong
                headline = "Sleep predicts your intention success"
                body = "When you sleep 7+ hours, your intention follow-through jumps to \(Int(wellRestedRate * 100))%. After less than 5 hours, it drops to \(Int(poorSleepRate * 100))%. Treat sleep as a ritual prerequisite."
            } else if diff > 0.1 {
                strength = .moderate
                headline = "Sleep has a moderate effect on your rituals"
                body = "Well-rested days yield \(Int(wellRestedRate * 100))% success vs \(Int(poorSleepRate * 100))% after poor sleep. Sleep matters — but so does intention."
            } else if diff < -0.1 {
                strength = .weak
                headline = "You override fatigue with intention"
                body = "Interestingly, you're slightly more successful on low-sleep days (\(Int(poorSleepRate * 100))%) than well-rested ones (\(Int(wellRestedRate * 100))%). Your willpower is notable."
            } else {
                strength = .weak
                headline = "Consistent ritual practice regardless of sleep"
                body = "Your intention follow-through is steady at around \(Int((wellRestedRate + poorSleepRate) / 2 * 100))% whether you slept well or not. That's remarkable consistency."
            }
        } else {
            strength = .moderate
            headline = "Sleep patterns are emerging in your data"
            body = "You're averaging \(String(format: "%.1f", sleepAvg)) hours of sleep. With more data, we'll see how sleep affects your ritual practice."
        }

        let daysAnalyzed = max(wellRestedTotal + poorSleepTotal, intentions.count)

        return SleepCorrelationReport(
            headline: headline,
            body: body,
            strength: strength,
            weeklyAverageSleep: sleepAvg,
            intentionSuccessRate: intentionSuccessRate,
            daysAnalyzed: daysAnalyzed
        )
    }
}
