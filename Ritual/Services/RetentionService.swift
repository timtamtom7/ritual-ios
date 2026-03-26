import Foundation
import SwiftUI

/// R13: Retention tracking for Ritual
/// Day 1: first intention
/// Day 3: first session
/// Day 7: first insight
@MainActor
final class RetentionService: ObservableObject {
    static let shared = RetentionService()

    private let installDateKey = "ritual_install_date"
    private let day1IntentionKey = "day1_intention_completed"
    private let day3SessionKey = "day3_session_completed"
    private let day7InsightKey = "day7_insight_completed"
    private let lastActiveKey = "ritual_last_active"

    @Published var daysSinceInstall: Int = 0
    @Published var day1Completed: Bool = false
    @Published var day3Completed: Bool = false
    @Published var day7Completed: Bool = false

    var currentMilestone: RetentionMilestone {
        if day7Completed { return .completed }
        else if day3Completed { return .day7 }
        else if day1Completed { return .day3 }
        else { return .day1 }
    }

    enum RetentionMilestone: String {
        case day1 = "Set your first intention"
        case day3 = "Complete your first breathing session"
        case day7 = "Gain your first insight"
        case completed = "Ritual established!"
    }

    init() {
        loadRetentionData()
    }

    func loadRetentionData() {
        if let installDate = UserDefaults.standard.object(forKey: installDateKey) as? Date {
            daysSinceInstall = Calendar.current.dateComponents([.day], from: installDate, to: Date()).day ?? 0
        } else {
            UserDefaults.standard.set(Date(), forKey: installDateKey)
            daysSinceInstall = 0
        }

        day1Completed = UserDefaults.standard.bool(forKey: day1IntentionKey)
        day3Completed = UserDefaults.standard.bool(forKey: day3SessionKey)
        day7Completed = UserDefaults.standard.bool(forKey: day7InsightKey)
        UserDefaults.standard.set(Date(), forKey: lastActiveKey)
    }

    func recordIntentionSet() {
        guard !day1Completed else { return }
        day1Completed = true
        UserDefaults.standard.set(true, forKey: day1IntentionKey)
        trackMilestone(.day1)
    }

    func recordSessionCompleted() {
        guard !day3Completed else { return }
        day3Completed = true
        UserDefaults.standard.set(true, forKey: day3SessionKey)
        trackMilestone(.day3)
    }

    func recordInsightGained() {
        guard !day7Completed else { return }
        day7Completed = true
        UserDefaults.standard.set(true, forKey: day7InsightKey)
        trackMilestone(.day7)
    }

    private func trackMilestone(_ milestone: RetentionMilestone) {
        print("[Retention] Milestone completed: \(milestone.rawValue)")
    }
}
