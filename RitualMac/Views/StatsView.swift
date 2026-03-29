import SwiftUI

// MARK: - StatsView
// Streak calendar, completion rate, most consistent rituals, weekly summary

struct StatsView: View {
    @ObservedObject var viewModel: RitualMacViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: MacTheme.spacingL) {
                headerSection
                
                streakSection
                
                completionRateSection
                
                weeklySummarySection
                
                categoryBreakdownSection
            }
            .padding(MacTheme.spacingL)
        }
        .background(MacTheme.background)
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: MacTheme.spacingS) {
            Text("Your Progress")
                .font(MacTheme.titleFont)
                .foregroundColor(MacTheme.primaryText)
            
            Text("Track your ritual consistency over time")
                .font(MacTheme.captionFont)
                .foregroundColor(MacTheme.mutedText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Streak Section
    private var streakSection: some View {
        VStack(spacing: MacTheme.spacingM) {
            // Streak calendar (last 30 days)
            VStack(alignment: .leading, spacing: MacTheme.spacingM) {
                Text("Last 30 Days")
                    .font(MacTheme.headingFont)
                    .foregroundColor(MacTheme.primaryText)
                
                // Calendar grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                    ForEach(viewModel.last30Days, id: \.self) { date in
                        DayCellMac(date: date, status: viewModel.dayStatus(for: date))
                    }
                }
                
                // Legend
                HStack(spacing: MacTheme.spacingM) {
                    LegendItem(color: MacTheme.sage, label: "Completed")
                    LegendItem(color: MacTheme.warmAmber.opacity(0.5), label: "Partial")
                    LegendItem(color: MacTheme.mutedText.opacity(0.3), label: "Missed")
                }
                .font(MacTheme.captionFont)
            }
            .padding(MacTheme.spacingM)
            .background(MacTheme.cardBg)
            .cornerRadius(MacTheme.cardRadius)
            .shadow(color: MacTheme.cardShadow, radius: 4, x: 0, y: 2)
        }
    }
    
    // MARK: - Completion Rate Section
    private var completionRateSection: some View {
        VStack(spacing: MacTheme.spacingM) {
            Text("Completion Rate")
                .font(MacTheme.headingFont)
                .foregroundColor(MacTheme.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: MacTheme.spacingL) {
                // Ring chart
                CompletionRing(progress: viewModel.overallCompletionRate)
                    .frame(width: 100, height: 100)
                
                // Stats
                VStack(alignment: .leading, spacing: MacTheme.spacingS) {
                    StatRow(label: "This Week", value: "\(Int(viewModel.weeklyCompletionRate))%")
                    StatRow(label: "This Month", value: "\(Int(viewModel.monthlyCompletionRate))%")
                    StatRow(label: "All Time", value: "\(Int(viewModel.overallCompletionRate))%")
                }
            }
        }
        .padding(MacTheme.spacingM)
        .background(MacTheme.cardBg)
        .cornerRadius(MacTheme.cardRadius)
        .shadow(color: MacTheme.cardShadow, radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Weekly Summary Section
    private var weeklySummarySection: some View {
        VStack(alignment: .leading, spacing: MacTheme.spacingM) {
            Text("This Week")
                .font(MacTheme.headingFont)
                .foregroundColor(MacTheme.primaryText)
            
            HStack(spacing: MacTheme.spacingM) {
                WeeklyStatCard(
                    icon: "flame.fill",
                    value: "\(viewModel.currentStreak)",
                    label: "Day Streak",
                    color: MacTheme.warmAmber
                )
                
                WeeklyStatCard(
                    icon: "checkmark.circle.fill",
                    value: "\(viewModel.weeklyCompleted)",
                    label: "Completed",
                    color: MacTheme.sage
                )
                
                WeeklyStatCard(
                    icon: "target",
                    value: "\(viewModel.weeklyTotal)",
                    label: "Total",
                    color: MacTheme.deepBrown
                )
            }
            
            // Weekly narrative
            if !viewModel.weeklyNarrative.isEmpty {
                Text(viewModel.weeklyNarrative)
                    .font(MacTheme.bodyFont)
                    .foregroundColor(MacTheme.secondaryText)
                    .italic()
                    .padding(MacTheme.spacingM)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(MacTheme.surface)
                    .cornerRadius(MacTheme.buttonRadius)
            }
        }
        .padding(MacTheme.spacingM)
        .background(MacTheme.cardBg)
        .cornerRadius(MacTheme.cardRadius)
        .shadow(color: MacTheme.cardShadow, radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Category Breakdown
    private var categoryBreakdownSection: some View {
        VStack(alignment: .leading, spacing: MacTheme.spacingM) {
            Text("By Category")
                .font(MacTheme.headingFont)
                .foregroundColor(MacTheme.primaryText)
            
            if viewModel.categoryStats.isEmpty {
                Text("Complete rituals to see category breakdown")
                    .font(MacTheme.bodyFont)
                    .foregroundColor(MacTheme.mutedText)
                    .padding(MacTheme.spacingM)
            } else {
                VStack(spacing: MacTheme.spacingS) {
                    ForEach(viewModel.categoryStats, id: \.category) { stat in
                        CategoryStatRow(stat: stat)
                    }
                }
            }
        }
        .padding(MacTheme.spacingM)
        .background(MacTheme.cardBg)
        .cornerRadius(MacTheme.cardRadius)
        .shadow(color: MacTheme.cardShadow, radius: 4, x: 0, y: 2)
    }
}

// MARK: - DayCellMac
struct DayCellMac: View {
    let date: Date
    let status: DayStatus
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    var body: some View {
        VStack(spacing: 2) {
            Text(dayNumber)
                .font(.system(size: 11, weight: isToday ? .bold : .regular))
                .foregroundColor(textColor)
        }
        .frame(width: 32, height: 32)
        .background(backgroundColor)
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isToday ? MacTheme.warmAmber : Color.clear, lineWidth: 2)
        )
    }
    
    private var backgroundColor: Color {
        switch status {
        case .completed: return MacTheme.sage
        case .partial: return MacTheme.warmAmber.opacity(0.5)
        case .missed: return MacTheme.mutedText.opacity(0.2)
        case .future: return Color.clear
        case .today: return MacTheme.warmAmber
        }
    }
    
    private var textColor: Color {
        switch status {
        case .completed, .partial, .today: return .white
        case .missed: return MacTheme.mutedText
        case .future: return MacTheme.mutedText
        }
    }
}

enum DayStatus {
    case completed
    case partial
    case missed
    case future
    case today
}

// MARK: - LegendItem
struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .foregroundColor(MacTheme.mutedText)
        }
    }
}

// MARK: - CompletionRing
struct CompletionRing: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(MacTheme.surface, lineWidth: 10)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    MacTheme.amberGradient,
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
            
            // Percentage text
            VStack(spacing: 0) {
                Text("\(Int(progress * 100))")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(MacTheme.primaryText)
                Text("%")
                    .font(.system(size: 12))
                    .foregroundColor(MacTheme.mutedText)
            }
        }
    }
}

// MARK: - StatRow
struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(MacTheme.captionFont)
                .foregroundColor(MacTheme.mutedText)
            Spacer()
            Text(value)
                .font(MacTheme.bodyFont)
                .fontWeight(.medium)
                .foregroundColor(MacTheme.primaryText)
        }
    }
}

// MARK: - WeeklyStatCard
struct WeeklyStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: MacTheme.spacingS) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(MacTheme.primaryText)
            
            Text(label)
                .font(MacTheme.captionFont)
                .foregroundColor(MacTheme.mutedText)
        }
        .frame(maxWidth: .infinity)
        .padding(MacTheme.spacingM)
        .background(MacTheme.surface)
        .cornerRadius(MacTheme.buttonRadius)
    }
}

// MARK: - CategoryStatRow
struct CategoryStatRow: View {
    let stat: CategoryStat
    
    var body: some View {
        VStack(spacing: MacTheme.spacingS) {
            HStack {
                Text(stat.category)
                    .font(MacTheme.bodyFont)
                    .foregroundColor(MacTheme.primaryText)
                
                Spacer()
                
                Text("\(Int(stat.completionRate))%")
                    .font(MacTheme.bodyFont)
                    .fontWeight(.medium)
                    .foregroundColor(stat.completionRate >= 70 ? MacTheme.sage : MacTheme.warmAmber)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(MacTheme.surface)
                        .frame(height: 6)
                    
                    Capsule()
                        .fill(stat.completionRate >= 70 ? MacTheme.sage : MacTheme.warmAmber)
                        .frame(width: geometry.size.width * (stat.completionRate / 100), height: 6)
                }
            }
            .frame(height: 6)
            
            HStack {
                Text("\(stat.completed)/\(stat.total) completed")
                    .font(MacTheme.captionFont)
                    .foregroundColor(MacTheme.mutedText)
                
                Spacer()
            }
        }
        .padding(MacTheme.spacingS)
    }
}

// MARK: - CategoryStat
struct CategoryStat {
    let category: String
    let total: Int
    let completed: Int
    
    var completionRate: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total) * 100
    }
}
