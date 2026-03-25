import Foundation
import Combine

struct TimelineEntry: Identifiable {
    let id: String
    let intention: Intention
    let checkIn: CheckIn?

    var date: Date { intention.createdAt }
    var hasReflection: Bool { checkIn?.reflection != nil && !checkIn!.reflection!.isEmpty }
}

struct WeekGroup: Identifiable {
    let id: String
    let startDate: Date
    let entries: [TimelineEntry]

    var weekLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let endDate = Calendar.current.date(byAdding: .day, value: 6, to: startDate)!
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
}

@MainActor
final class TimelineViewModel: ObservableObject {
    @Published var weekGroups: [WeekGroup] = []
    @Published var isEmpty: Bool = true

    private let database = DatabaseService.shared

    init() {
        loadTimeline()
    }

    func loadTimeline() {
        let intentions = database.getIntentions()
        var entries: [TimelineEntry] = []

        for intention in intentions {
            let checkIns = database.getCheckIns(forIntentionId: intention.id)
            let checkIn = checkIns.first
            entries.append(TimelineEntry(id: intention.id, intention: intention, checkIn: checkIn))
        }

        isEmpty = entries.isEmpty
        weekGroups = groupByWeek(entries)
    }

    private func groupByWeek(_ entries: [TimelineEntry]) -> [WeekGroup] {
        let calendar = Calendar.current
        var weekDict: [String: [TimelineEntry]] = [:]
        var weekStarts: [String: Date] = [:]

        for entry in entries {
            let weekStart = calendar.dateInterval(of: .weekOfYear, for: entry.date)?.start ?? entry.date
            let key = keyForDate(weekStart)
            weekDict[key, default: []].append(entry)
            weekStarts[key] = weekStart
        }

        return weekDict.keys.sorted(by: >).compactMap { key in
            guard let startDate = weekStarts[key],
                  let entries = weekDict[key] else { return nil }
            return WeekGroup(id: key, startDate: startDate, entries: entries.sorted { $0.date > $1.date })
        }
    }

    private func keyForDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
