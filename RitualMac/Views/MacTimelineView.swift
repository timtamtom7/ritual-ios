import SwiftUI

struct MacTimelineView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Timeline")
                    .font(.system(size: 28, weight: .light, design: .serif))
                    .foregroundColor(MacTheme.primaryText)
                    .padding(.bottom, 8)

                Text("Your ritual history over time")
                    .font(MacTheme.bodyFont)
                    .foregroundColor(MacTheme.mutedText)

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
        .background(MacTheme.background)
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
                .foregroundColor(MacTheme.mutedText)
            Text(dayNumber)
                .font(.system(size: 14, weight: isToday ? .bold : .regular))
                .foregroundColor(isToday ? .white : (hadIntentions ? MacTheme.primaryText : MacTheme.mutedText))
        }
        .frame(width: 48, height: 48)
        .background(
            isToday ? MacTheme.warmAmber :
            (hadIntentions ? MacTheme.warmAmber.opacity(0.2) : MacTheme.cardBg)
        )
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(MacTheme.mutedText.opacity(0.3), lineWidth: 1)
        )
    }
}

struct MacInsightsView: View {
    @State private var totalIntentions: Int = 0
    @State private var totalCheckIns: Int = 0
    @State private var streakCount: Int = 0
    @State private var monthlyTheme: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Insights")
                    .font(MacTheme.titleFont)
                    .foregroundColor(MacTheme.primaryText)
                    .padding(.bottom, 8)

                HStack(spacing: 16) {
                    MacStatCard(title: "Intentions", value: "\(totalIntentions)")
                    MacStatCard(title: "Check-ins", value: "\(totalCheckIns)")
                    MacStatCard(title: "Streak", value: "\(streakCount)")
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Monthly Theme")
                        .font(MacTheme.headingFont)
                        .foregroundColor(MacTheme.primaryText)

                    if !monthlyTheme.isEmpty {
                        Text(monthlyTheme)
                            .font(MacTheme.bodyFont)
                            .foregroundColor(MacTheme.secondaryText)
                            .italic()
                    } else {
                        Text("Complete more rituals to discover your monthly theme.")
                            .font(MacTheme.bodyFont)
                            .foregroundColor(MacTheme.mutedText)
                    }
                }
                .padding(MacTheme.spacingM)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(MacTheme.cardBg)
                .cornerRadius(MacTheme.cardRadius)
            }
            .padding(24)
        }
        .background(MacTheme.background)
        .onAppear {
            let intentions = DatabaseService.shared.getIntentions()
            let checkIns = DatabaseService.shared.getAllCheckIns()
            totalIntentions = intentions.count
            totalCheckIns = checkIns.count
            streakCount = DatabaseService.shared.getStreakData().currentStreak
            monthlyTheme = DatabaseService.shared.getMonthlyTheme() ?? ""
        }
    }
}
