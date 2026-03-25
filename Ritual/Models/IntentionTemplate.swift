import Foundation

struct IntentionTemplate: Identifiable {
    let id: String
    let title: String
    let category: String
    let description: String
    let example: String
    let timesUsed: Int

    var icon: String {
        IntentionCategory(rawValue: category)?.icon ?? "sparkle"
    }
}

// MARK: - Community Templates (local defaults + user-adopted)

struct IntentionTemplateStore {
    static let popularTemplates: [IntentionTemplate] = [
        IntentionTemplate(
            id: "morning-focus",
            title: "Morning Focus Ritual",
            category: "Work",
            description: "Start your day with clarity and purpose",
            example: "Today, I intend to focus deeply on my most important task",
            timesUsed: 1240
        ),
        IntentionTemplate(
            id: "evening-wind-down",
            title: "Evening Wind-Down",
            category: "Health",
            description: "Transition from work to rest",
            example: "Today, I intend to let go of work and embrace rest",
            timesUsed: 980
        ),
        IntentionTemplate(
            id: "creative-kickoff",
            title: "Creative Project Kickoff",
            category: "Growth",
            description: "Begin a creative endeavor with intention",
            example: "Today, I intend to take one brave step in my creative project",
            timesUsed: 756
        ),
        IntentionTemplate(
            id: "kindness-practice",
            title: "Daily Kindness",
            category: "Relationships",
            description: "Spread warmth in your interactions",
            example: "Today, I intend to offer kindness to at least one person",
            timesUsed: 1102
        ),
        IntentionTemplate(
            id: "boundary-setting",
            title: "Healthy Boundaries",
            category: "Relationships",
            description: "Honor your limits with grace",
            example: "Today, I intend to protect my time and energy by setting one healthy boundary",
            timesUsed: 634
        ),
        IntentionTemplate(
            id: "movement-intention",
            title: "Body Movement",
            category: "Health",
            description: "Honor your body through movement",
            example: "Today, I intend to move my body with joy and not punishment",
            timesUsed: 889
        ),
        IntentionTemplate(
            id: "presence-practice",
            title: "Present Moment",
            category: "Growth",
            description: "Be where you are, fully",
            example: "Today, I intend to stay present in each moment rather than rushing ahead",
            timesUsed: 543
        ),
        IntentionTemplate(
            id: "gratitude-focus",
            title: "Gratitude Practice",
            category: "Growth",
            description: "Cultivate appreciation daily",
            example: "Today, I intend to notice three things I'm grateful for",
            timesUsed: 1203
        )
    ]

    static func getTemplates(forCategory: String? = nil) -> [IntentionTemplate] {
        if let cat = forCategory {
            return popularTemplates.filter { $0.category == cat }
        }
        return popularTemplates
    }
}
