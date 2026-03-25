import Foundation
import Combine

struct CategoryInsight: Identifiable {
    let id: String
    let category: String
    let successRate: Double
    let totalCount: Int
    let successCount: Int
    let isStrongest: Bool
    let isWeakest: Bool

    var headline: String {
        "Intentions about \(category.lowercased()) succeed \(Int(successRate))% of the time."
    }

    var subtext: String {
        "You've set \(totalCount) \(category.lowercased()) intention\(totalCount == 1 ? "" : "s"). \(successCount) led to action."
    }

    var trend: String {
        if isStrongest {
            return "This is your strongest category."
        } else if isWeakest {
            return "This is an area to nurture."
        }
        return ""
    }

    var icon: String {
        IntentionCategory(rawValue: category)?.icon ?? "sparkle"
    }
}

@MainActor
final class InsightsViewModel: ObservableObject {
    @Published var insights: [CategoryInsight] = []
    @Published var hasEnoughData: Bool = false
    @Published var totalIntentions: Int = 0
    @Published var totalCheckIns: Int = 0

    private let database = DatabaseService.shared

    init() {
        calculateInsights()
    }

    func calculateInsights() {
        let allIntentions = database.getIntentions()
        let allCheckIns = database.getAllCheckIns()

        totalIntentions = allIntentions.count
        totalCheckIns = allCheckIns.count

        // Need at least 2 weeks of data (14 days)
        let minDate = Calendar.current.date(byAdding: .day, value: -14, to: Date())!
        let recentIntentions = allIntentions.filter { $0.createdAt >= minDate }
        hasEnoughData = recentIntentions.count >= 3

        guard hasEnoughData else {
            insights = []
            return
        }

        let grouped = database.getIntentionsGroupedByCategory()
        var categoryInsights: [CategoryInsight] = []

        var maxRate: Double = 0
        var minRate: Double = 100

        for (category, intentions) in grouped {
            let successRate = database.getSuccessRate(forCategory: category)
            let successCount = intentions.filter { intention in
                let checkIns = database.getCheckIns(forIntentionId: intention.id)
                return checkIns.first?.acted == true
            }.count

            if successRate > maxRate { maxRate = successRate }
            if successRate < minRate && !intentions.isEmpty { minRate = successRate }

            categoryInsights.append(CategoryInsight(
                id: UUID().uuidString,
                category: category,
                successRate: successRate,
                totalCount: intentions.count,
                successCount: successCount,
                isStrongest: false,
                isWeakest: false
            ))
        }

        // Mark strongest and weakest
        for i in categoryInsights.indices {
            if categoryInsights[i].successRate == maxRate && maxRate > 0 {
                categoryInsights[i] = CategoryInsight(
                    id: categoryInsights[i].id,
                    category: categoryInsights[i].category,
                    successRate: categoryInsights[i].successRate,
                    totalCount: categoryInsights[i].totalCount,
                    successCount: categoryInsights[i].successCount,
                    isStrongest: true,
                    isWeakest: false
                )
            }
            if categoryInsights[i].successRate == minRate && minRate < 100 && !categoryInsights.isEmpty {
                categoryInsights[i] = CategoryInsight(
                    id: categoryInsights[i].id,
                    category: categoryInsights[i].category,
                    successRate: categoryInsights[i].successRate,
                    totalCount: categoryInsights[i].totalCount,
                    successCount: categoryInsights[i].successCount,
                    isStrongest: false,
                    isWeakest: true
                )
            }
        }

        insights = categoryInsights.filter { $0.totalCount > 0 }.sorted { $0.successRate > $1.successRate }
    }

    func refresh() {
        calculateInsights()
    }
}
