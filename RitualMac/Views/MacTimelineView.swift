import SwiftUI

struct MacTimelineView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Timeline")
                    .font(.system(size: 28, weight: .light, design: .serif))
                    .foregroundColor(Color(hex: "F5F0E8"))
                    .padding(.bottom, 8)

                Text("Your ritual history over time")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "9C9285"))

                // Show last 30 days
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                    ForEach(last30Days, id: \.self) { date in
                        DayCell(date: date, hadIntentions: hasIntentions(on: date))
                    }
                }
                .padding(.top, 16)
            }
            .padding(24)
        }
        .background(Color(hex: "0D0B09"))
    }

    private var last30Days: [Date] {
        let calendar = Calendar.current
        return (0..<30).compactMap { day in
            calendar.date(byAdding: .day, value: -day, to: Date())
        }.reversed()
    }

    private func hasIntentions(on date: Date) -> Bool {
        let calendar = Calendar.current
        return DatabaseService.shared.getIntentions().contains { intention in
            calendar.isDate(intention.createdAt, inSameDayAs: date)
        }
    }
}

struct DayCell: View {
    let date: Date
    let hadIntentions: Bool

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    private var monthAbbr: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date)
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    var body: some View {
        VStack(spacing: 2) {
            Text(monthAbbr)
                .font(.system(size: 9))
                .foregroundColor(Color(hex: "9C9285"))
            Text(dayNumber)
                .font(.system(size: 14, weight: isToday ? .bold : .regular))
                .foregroundColor(isToday ? Color(hex: "0D0B09") : (hadIntentions ? Color(hex: "F5F0E8") : Color(hex: "5C544A")))
        }
        .frame(width: 48, height: 48)
        .background(
            isToday ? Color(hex: "C9A96E") :
            (hadIntentions ? Color(hex: "C9A96E").opacity(0.2) : Color(hex: "1A1714"))
        )
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(hex: "8B7355").opacity(0.3), lineWidth: 1)
        )
    }
}

struct MacInsightsView: View {
    @State private var totalIntentions: Int = 0
    @State private var totalCheckIns: Int = 0
    @State private var streakCount: Int = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Insights")
                    .font(.system(size: 28, weight: .light, design: .serif))
                    .foregroundColor(Color(hex: "F5F0E8"))
                    .padding(.bottom, 8)

                HStack(spacing: 16) {
                    MacStatCard(title: "Intentions", value: "\(totalIntentions)")
                    MacStatCard(title: "Check-ins", value: "\(totalCheckIns)")
                    MacStatCard(title: "Streak", value: "\(streakCount)")
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Monthly Narrative")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "9C9285"))
                        .textCase(.uppercase)
                        .tracking(1)

                    let narrative = NarrativeService.shared.generateMonthlyNarrative()
                    VStack(alignment: .leading, spacing: 8) {
                        Text(narrative.openingParagraph)
                            .font(.system(size: 15, design: .serif))
                            .foregroundColor(Color(hex: "F5F0E8"))
                            .italic()

                        Text(narrative.categoryParagraph)
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "9C9285"))

                        Text(narrative.changeParagraph)
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "9C9285"))
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(hex: "1A1714"))
                    .cornerRadius(12)
                }
            }
            .padding(24)
        }
        .background(Color(hex: "0D0B09"))
        .onAppear {
            let intentions = DatabaseService.shared.getIntentions()
            let checkIns = DatabaseService.shared.getAllCheckIns()
            totalIntentions = intentions.count
            totalCheckIns = checkIns.count
            streakCount = DatabaseService.shared.getStreakData().currentStreak
        }
    }
}
