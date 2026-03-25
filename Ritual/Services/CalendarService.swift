import Foundation
import EventKit

@MainActor
final class CalendarService: ObservableObject {
    static let shared = CalendarService()

    @Published var todayEvents: [EKEvent] = []
    @Published var conflictingEvents: [EKEvent] = []
    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined

    private let eventStore = EKEventStore()

    private init() {
        checkAuthorizationStatus()
    }

    func checkAuthorizationStatus() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
    }

    func requestAccess() async -> Bool {
        do {
            if #available(iOS 17.0, *) {
                let granted = try await eventStore.requestFullAccessToEvents()
                await MainActor.run { checkAuthorizationStatus() }
                return granted
            } else {
                let granted = try await eventStore.requestAccess(to: .event)
                await MainActor.run { checkAuthorizationStatus() }
                return granted
            }
        } catch {
            print("Calendar access error: \(error)")
            return false
        }
    }

    func fetchTodaysEvents() {
        guard authorizationStatus == .fullAccess || authorizationStatus == .authorized else { return }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return }

        let predicate = eventStore.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: nil)
        let events = eventStore.events(matching: predicate)
        todayEvents = events.sorted { $0.startDate < $1.startDate }
    }

    func checkConflicts(forTime time: Date, withinMinutes minutes: Int = 60) -> [EKEvent] {
        let calendar = Calendar.current
        let windowStart = calendar.date(byAdding: .minute, value: -minutes, to: time) ?? time
        let windowEnd = calendar.date(byAdding: .minute, value: minutes, to: time) ?? time

        return todayEvents.filter { event in
            guard let eventStart = event.startDate, let eventEnd = event.endDate else { return false }
            // Event overlaps with the window around the given time
            return eventStart < windowEnd && eventEnd > windowStart
        }
    }

    func conflictingEventsForToday(intentionTime: Date? = nil) -> [EKEvent] {
        fetchTodaysEvents()
        guard !todayEvents.isEmpty else { return [] }

        // Check conflicts for morning (intention time or default 8am)
        let morningTime: Date
        if let intentionTime = intentionTime {
            morningTime = intentionTime
        } else {
            var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            components.hour = 8
            components.minute = 0
            morningTime = Calendar.current.date(from: components) ?? Date()
        }

        let morningConflicts = checkConflicts(forTime: morningTime, withinMinutes: 90)

        // Check conflicts for evening check-in (default 6pm)
        var eveningComponents = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        eveningComponents.hour = 18
        eveningComponents.minute = 0
        let eveningTime = Calendar.current.date(from: eveningComponents) ?? Date()
        let eveningConflicts = checkConflicts(forTime: eveningTime, withinMinutes: 90)

        // Combine unique conflicts
        var allConflicts = morningConflicts
        for event in eveningConflicts {
            if !allConflicts.contains(where: { $0.eventIdentifier == event.eventIdentifier }) {
                allConflicts.append(event)
            }
        }
        return allConflicts
    }
}
