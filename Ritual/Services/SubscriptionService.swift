import Foundation
import StoreKit

enum SubscriptionTier: String, CaseIterable {
    case free = "Free"
    case pro = "Pro"
    case teacher = "Teacher"

    var displayName: String { rawValue }

    var monthlyPrice: String {
        switch self {
        case .free: return "Free"
        case .pro: return "$4.99/mo"
        case .teacher: return "$9.99/mo"
        }
    }

    var yearlyPrice: String {
        switch self {
        case .free: return "Free"
        case .pro: return "$39.99/yr"
        case .teacher: return "$79.99/yr"
        }
    }

    var yearlySavings: String? {
        switch self {
        case .free: return nil
        case .pro: return "Save 33%"
        case .teacher: return "Save 33%"
        }
    }

    var features: [String] {
        switch self {
        case .free:
            return [
                "3 intentions per day",
                "Basic breathing patterns",
                "7-day streak tracking",
                "Simple insights"
            ]
        case .pro:
            return [
                "Unlimited intentions",
                "All breathing patterns",
                "Full insights & sleep correlation",
                "Seasonal themes & monthly narrative",
                "Adaptive breathing AI",
                "Data export",
                "Priority support"
            ]
        case .teacher:
            return [
                "Everything in Pro",
                "Create & share ritual templates",
                "Host group breathing sessions",
                "Community templates gallery",
                "Community streak tracking",
                "Student/group management",
                "Teacher profile page"
            ]
        }
    }

    var intentionLimit: Int {
        switch self {
        case .free: return 3
        case .pro: return Int.max
        case .teacher: return Int.max
        }
    }

    var canUseAllPatterns: Bool {
        self != .free
    }

    var canUseSeasonalThemes: Bool {
        self != .free
    }

    var canUseHealthKit: Bool {
        self != .free
    }

    var canUseMonthlyNarrative: Bool {
        self != .free
    }

    var canUseGroupRituals: Bool {
        self == .teacher
    }

    var canShareTemplates: Bool {
        self == .teacher
    }

    var canExportData: Bool {
        self == .pro || self == .teacher
    }
}

@MainActor
final class SubscriptionService: ObservableObject {
    static let shared = SubscriptionService()

    @Published private(set) var currentTier: SubscriptionTier = .free
    @Published private(set) var isYearly: Bool = false
    @Published private(set) var isSubscribed: Bool = false
    @Published private(set) var expirationDate: Date?
    @Published private(set) var isLoading: Bool = false
    @Published var showPaywall: Bool = false

    private let userDefaults = UserDefaults.standard
    private let tierKey = "subscription_tier"
    private let isYearlyKey = "subscription_is_yearly"
    private let expirationKey = "subscription_expiration"

    // Product IDs
    private let proMonthlyID = "com.ritual.pro.monthly"
    private let proYearlyID = "com.ritual.pro.yearly"
    private let teacherMonthlyID = "com.ritual.teacher.monthly"
    private let teacherYearlyID = "com.ritual.teacher.yearly"

    private init() {
        loadSubscriptionState()
    }

    private func loadSubscriptionState() {
        if let tierString = userDefaults.string(forKey: tierKey),
           let tier = SubscriptionTier(rawValue: tierString) {
            currentTier = tier
            isYearly = userDefaults.bool(forKey: isYearlyKey)
            if let expTimeInterval = userDefaults.object(forKey: expirationKey) as? TimeInterval {
                expirationDate = Date(timeIntervalSince1970: expTimeInterval)
            }
            isSubscribed = tier != .free && (expirationDate == nil || (expirationDate ?? Date.distantPast) > Date())
        }
    }

    private func saveSubscriptionState() {
        userDefaults.set(currentTier.rawValue, forKey: tierKey)
        userDefaults.set(isYearly, forKey: isYearlyKey)
        if let exp = expirationDate {
            userDefaults.set(exp.timeIntervalSince1970, forKey: expirationKey)
        } else {
            userDefaults.removeObject(forKey: expirationKey)
        }
    }

    // MARK: - Feature Flags

    func canSetIntention() -> Bool {
        if currentTier != .free { return true }
        return true // Check actual usage in production
    }

    func intentionLimitReached(todayCount: Int) -> Bool {
        return todayCount >= currentTier.intentionLimit
    }

    func canUseFeature(_ feature: SubscriptionFeature) -> Bool {
        switch feature {
        case .allPatterns:
            return currentTier.canUseAllPatterns
        case .seasonalThemes:
            return currentTier.canUseSeasonalThemes
        case .healthKit:
            return currentTier.canUseHealthKit
        case .monthlyNarrative:
            return currentTier.canUseMonthlyNarrative
        case .groupRituals:
            return currentTier.canUseGroupRituals
        case .shareTemplates:
            return currentTier.canShareTemplates
        case .dataExport:
            return currentTier.canExportData
        case .unlimitedIntentions:
            return currentTier != .free
        }
    }

    enum SubscriptionFeature {
        case allPatterns
        case seasonalThemes
        case healthKit
        case monthlyNarrative
        case groupRituals
        case shareTemplates
        case dataExport
        case unlimitedIntentions
    }

    // MARK: - Purchase

    func purchase(_ tier: SubscriptionTier, yearly: Bool) async -> Bool {
        isLoading = true
        defer { isLoading = false }

        // In a real implementation, this would call StoreKit2
        // For now, we simulate a successful purchase
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        currentTier = tier
        isYearly = yearly
        isSubscribed = true

        if yearly {
            expirationDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())
        } else {
            expirationDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())
        }

        saveSubscriptionState()
        return true
    }

    func restorePurchases() async -> Bool {
        isLoading = true
        defer { isLoading = false }

        // In a real implementation, this would call StoreKit2
        try? await Task.sleep(nanoseconds: 500_000_000)
        return false
    }

    func cancelSubscription() {
        currentTier = .free
        isSubscribed = false
        expirationDate = nil
        saveSubscriptionState()
    }
}
