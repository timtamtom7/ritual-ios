import WidgetKit
import SwiftUI

// MARK: - Widget Bundle

@main
struct RitualWidgets: WidgetBundle {
    var body: some Widget {
        TodaysIntentionWidget()
    }
}

// MARK: - Theme Colors (duplicated for widget)

enum WidgetTheme {
    static let background = Color(red: 0.051, green: 0.043, blue: 0.035)
    static let surface = Color(red: 0.102, green: 0.090, blue: 0.078)
    static let goldPrimary = Color(red: 0.788, green: 0.663, blue: 0.431)
    static let goldMuted = Color(red: 0.545, green: 0.451, blue: 0.333)
    static let textPrimary = Color(red: 0.961, green: 0.941, blue: 0.910)
    static let textSecondary = Color(red: 0.612, green: 0.573, blue: 0.522)
}

// MARK: - Today's Intention Widget

struct IntentionEntry: TimelineEntry {
    let date: Date
    let intentionText: String?
    let affirmation: String?
    let streakCount: Int
}

struct IntentionProvider: TimelineProvider {
    typealias Entry = IntentionEntry

    func placeholder(in context: Context) -> IntentionEntry {
        IntentionEntry(
            date: Date(),
            intentionText: "I choose to respond with calm intention today.",
            affirmation: "Every breath is a fresh start.",
            streakCount: 7
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (IntentionEntry) -> Void) {
        let entry = fetchEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<IntentionEntry>) -> Void) {
        let entry = fetchEntry()
        // Refresh at midnight and noon
        let calendar = Calendar.current
        var refreshDate = calendar.startOfDay(for: Date())
        if Date() > calendar.date(byAdding: .hour, value: 12, to: refreshDate)! {
            refreshDate = calendar.date(byAdding: .hour, value: 12, to: refreshDate)!
        } else {
            refreshDate = calendar.date(byAdding: .hour, value: 8, to: refreshDate)!
        }
        let nextUpdate = calendar.date(byAdding: .day, value: 1, to: refreshDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func fetchEntry() -> IntentionEntry {
        // Read from shared UserDefaults (App Group)
        let sharedDefaults = UserDefaults(suiteName: "group.com.ritual.app")
        let intentionText = sharedDefaults?.string(forKey: "todayIntentionText")
        let affirmation = sharedDefaults?.string(forKey: "todayAffirmation")
        let streakCount = sharedDefaults?.integer(forKey: "ritualStreak") ?? 0

        return IntentionEntry(
            date: Date(),
            intentionText: intentionText,
            affirmation: affirmation,
            streakCount: streakCount
        )
    }
}

struct TodaysIntentionWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TodaysIntentionWidget", provider: IntentionProvider()) { entry in
            TodaysIntentionWidgetView(entry: entry)
                .containerBackground(WidgetTheme.background, for: .widget)
        }
        .configurationDisplayName("Today's Intention")
        .description("Your daily ritual intention and affirmation.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryCircular])
    }
}

struct TodaysIntentionWidgetView: View {
    var entry: IntentionEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
        case .systemMedium:
            mediumWidget
        case .accessoryRectangular:
            accessoryRectangular
        case .accessoryCircular:
            accessoryCircular
        default:
            smallWidget
        }
    }

    private var smallWidget: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "sun.max.fill")
                    .foregroundColor(WidgetTheme.goldPrimary)
                    .font(.caption)
                Text("Today's Intention")
                    .font(.caption2)
                    .foregroundColor(WidgetTheme.textSecondary)
                Spacer()
                if entry.streakCount > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                            .foregroundColor(WidgetTheme.goldPrimary)
                        Text("\(entry.streakCount)")
                            .font(.caption2)
                            .foregroundColor(WidgetTheme.goldPrimary)
                    }
                }
            }

            Spacer()

            if let intention = entry.intentionText {
                Text(intention)
                    .font(.system(.callout, design: .serif))
                    .foregroundColor(WidgetTheme.textPrimary)
                    .lineLimit(3)
            } else {
                Text("Set your intention for today")
                    .font(.system(.callout, design: .serif))
                    .foregroundColor(WidgetTheme.textSecondary)
            }

            if let affirmation = entry.affirmation {
                Text(affirmation)
                    .font(.caption2)
                    .foregroundColor(WidgetTheme.goldMuted)
                    .lineLimit(1)
            }
        }
        .padding(12)
    }

    private var mediumWidget: some View {
        HStack(spacing: 12) {
            // Left: intention
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "sun.max.fill")
                        .foregroundColor(WidgetTheme.goldPrimary)
                    Text("Today's Intention")
                        .font(.caption)
                        .foregroundColor(WidgetTheme.textSecondary)
                }

                Spacer()

                if let intention = entry.intentionText {
                    Text(intention)
                        .font(.system(.callout, design: .serif))
                        .foregroundColor(WidgetTheme.textPrimary)
                        .lineLimit(3)
                } else {
                    Text("Set your daily intention in Ritual")
                        .font(.system(.callout, design: .serif))
                        .foregroundColor(WidgetTheme.textSecondary)
                }
            }

            Divider()
                .background(WidgetTheme.goldMuted.opacity(0.3))

            // Right: streak and affirmation
            VStack(alignment: .trailing, spacing: 8) {
                if entry.streakCount > 0 {
                    VStack(spacing: 2) {
                        HStack(spacing: 2) {
                            Image(systemName: "flame.fill")
                                .font(.caption)
                                .foregroundColor(WidgetTheme.goldPrimary)
                            Text("\(entry.streakCount)")
                                .font(.system(.title2, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(WidgetTheme.goldPrimary)
                        }
                        Text("day streak")
                            .font(.caption2)
                            .foregroundColor(WidgetTheme.textSecondary)
                    }
                }

                Spacer()

                if let affirmation = entry.affirmation {
                    Text("\"\(affirmation)\"")
                        .font(.caption2)
                        .foregroundColor(WidgetTheme.goldMuted)
                        .italic()
                        .lineLimit(2)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
        .padding(12)
    }

    private var accessoryRectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Image(systemName: "sun.max.fill")
                    .font(.caption2)
                Text("Ritual")
                    .font(.caption2)
                    .fontWeight(.semibold)
            }
            .foregroundColor(WidgetTheme.goldPrimary)

            if let intention = entry.intentionText {
                Text(intention)
                    .font(.caption2)
                    .lineLimit(2)
            } else {
                Text("Set your intention")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var accessoryCircular: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 1) {
                Image(systemName: "sun.max.fill")
                    .font(.caption)
                if entry.streakCount > 0 {
                    Text("\(entry.streakCount)")
                        .font(.system(.caption2, design: .rounded))
                        .fontWeight(.bold)
                }
            }
            .foregroundColor(WidgetTheme.goldPrimary)
        }
    }
}

// MARK: - Widget Preview

#Preview("Small", as: .systemSmall) {
    TodaysIntentionWidget()
} timeline: {
    IntentionEntry(
        date: Date(),
        intentionText: "I choose calm and intentional responses today.",
        affirmation: "Every breath is a fresh start.",
        streakCount: 7
    )
}
