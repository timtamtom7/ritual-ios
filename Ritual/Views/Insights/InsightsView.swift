import SwiftUI

struct InsightsView: View {
    @StateObject private var viewModel = InsightsViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                if viewModel.hasEnoughData {
                    insightsContent
                } else {
                    placeholderView
                }
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { HapticFeedback.selection(); viewModel.refresh() }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16))
                            .foregroundColor(Theme.goldPrimary)
                    }
                    .accessibilityLabel("Refresh insights")
                }
            }
        }
    }

    private var placeholderView: some View {
        ScrollView {
            VStack(spacing: Theme.spacingL) {
                Spacer()
                    .frame(height: Theme.spacingXL)

                Image(systemName: "sparkles")
                    .font(.system(size: 48))
                    .foregroundColor(Theme.goldMuted.opacity(0.5))

                VStack(spacing: Theme.spacingS) {
                    Text("Insights emerge with practice")
                        .font(.system(size: 20, weight: .regular, design: .serif))
                        .foregroundColor(Theme.textPrimary)

                    Text("Keep setting intentions and checking in. After a couple weeks, patterns will reveal themselves.")
                        .font(.system(size: 15))
                        .foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Theme.spacingL)
                }

                VStack(spacing: Theme.spacingM) {
                    ProgressRow(label: "Intentions set", value: "\(viewModel.totalIntentions)", target: 10)
                    ProgressRow(label: "Check-ins completed", value: "\(viewModel.totalCheckIns)", target: 10)
                }
                .padding(.top, Theme.spacingL)

                Spacer()
            }
            .padding(.horizontal, Theme.spacingM)
        }
    }

    private var insightsContent: some View {
        ScrollView {
            VStack(spacing: Theme.spacingL) {
                // Summary stats
                HStack(spacing: Theme.spacingM) {
                    StatCard(title: "Total Intentions", value: "\(viewModel.totalIntentions)", icon: "list.bullet")
                    StatCard(title: "Check-Ins", value: "\(viewModel.totalCheckIns)", icon: "checkmark.circle")
                }
                .padding(.horizontal, Theme.spacingM)

                // Weekly Report
                if let report = viewModel.weeklyReport {
                    WeeklyReportCard(report: report)
                        .padding(.horizontal, Theme.spacingM)
                }

                // Monthly Theme
                if let theme = viewModel.monthlyTheme {
                    MonthlyThemeCard(theme: theme)
                        .padding(.horizontal, Theme.spacingM)
                }

                // R7: Seasonal Theme Banner
                SeasonalBanner(seasonTheme: viewModel.seasonalTheme)
                    .padding(.horizontal, Theme.spacingM)

                // R7: Monthly Narrative
                if let narrative = viewModel.monthlyNarrative {
                    MonthlyNarrativeCard(narrative: narrative)
                        .padding(.horizontal, Theme.spacingM)
                }

                // R7: HealthKit Sleep Correlation
                if viewModel.healthKitAvailable {
                    if viewModel.isLoadingHealthKit {
                        HealthKitLoadingCard()
                            .padding(.horizontal, Theme.spacingM)
                    } else if let report = viewModel.sleepCorrelationReport {
                        HealthKitSleepCorrelationCard(report: report)
                            .padding(.horizontal, Theme.spacingM)
                    }
                }

                // R4: AI Narrative Insights
                if !viewModel.narrativeInsights.isEmpty {
                    VStack(alignment: .leading, spacing: Theme.spacingS) {
                        Text("WEEKLY NARRATIVE")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Theme.textMuted)
                            .tracking(1)
                            .padding(.horizontal, Theme.spacingM)

                        ForEach(viewModel.narrativeInsights) { insight in
                            NarrativeInsightCard(insight: insight)
                                .padding(.horizontal, Theme.spacingM)
                        }
                    }
                }

                // R4: Sleep Correlation
                if let sleep = viewModel.sleepCorrelation {
                    SleepCorrelationCard(correlation: sleep)
                        .padding(.horizontal, Theme.spacingM)
                }

                // R4: Calendar Conflict Warning
                if let conflict = viewModel.calendarConflict {
                    CalendarConflictCard(conflict: conflict)
                        .padding(.horizontal, Theme.spacingM)
                }

                // Category insights
                if !viewModel.insights.isEmpty {
                    VStack(alignment: .leading, spacing: Theme.spacingS) {
                        Text("BY CATEGORY")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Theme.textMuted)
                            .tracking(1)
                            .padding(.horizontal, Theme.spacingM)

                        ForEach(viewModel.insights) { insight in
                            InsightCard(insight: insight)
                                .padding(.horizontal, Theme.spacingM)
                        }
                    }
                }

                Spacer()
                    .frame(height: Theme.spacingL)
            }
            .padding(.vertical, Theme.spacingM)
        }
    }
}

struct NarrativeInsightCard: View {
    let insight: NarrativeInsight

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            HStack {
                Image(systemName: insight.icon)
                    .font(.system(size: 16))
                    .foregroundColor(Theme.goldPrimary)
                Text(insight.headline)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Theme.textPrimary)
            }

            Text(insight.body)
                .font(.system(size: 14))
                .foregroundColor(Theme.textSecondary)
        }
        .padding(Theme.spacingM)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface)
        .cornerRadius(Theme.cardRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius)
                .stroke(Theme.goldMuted.opacity(0.3), lineWidth: 1)
        )
    }
}

struct SleepCorrelationCard: View {
    let correlation: SleepCorrelation

    private var icon: String {
        switch correlation.pattern {
        case .neutral: return "equal.circle"
        case .betterWithSettledSleep: return "moon.zzz.fill"
        case .strongerWhenTired: return "bolt.fill"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(Theme.goldPrimary)
                Text("Sleep Pattern")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Theme.textPrimary)
            }

            Text(correlation.headline)
                .font(.system(size: 15, weight: .medium, design: .serif))
                .foregroundColor(Theme.goldGlow)

            Text(correlation.body)
                .font(.system(size: 14))
                .foregroundColor(Theme.textSecondary)
        }
        .padding(Theme.spacingM)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface)
        .cornerRadius(Theme.cardRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius)
                .stroke(Theme.goldPrimary.opacity(0.4), lineWidth: 1)
        )
    }
}

struct CalendarConflictCard: View {
    let conflict: CalendarConflictReport

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            HStack {
                Image(systemName: "calendar.badge.exclamationmark")
                    .font(.system(size: 16))
                    .foregroundColor(Theme.warning)
                Text("Calendar Today")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Theme.textPrimary)
            }

            Text(conflict.headline)
                .font(.system(size: 15, weight: .medium, design: .serif))
                .foregroundColor(Theme.warning)

            Text(conflict.body)
                .font(.system(size: 14))
                .foregroundColor(Theme.textSecondary)
        }
        .padding(Theme.spacingM)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface)
        .cornerRadius(Theme.cardRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius)
                .stroke(Theme.warning.opacity(0.5), lineWidth: 1)
        )
    }
}

struct WeeklyReportCard: View {
    let report: String

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            HStack {
                Image(systemName: "text.alignleft")
                    .font(.system(size: 16))
                    .foregroundColor(Theme.goldPrimary)
                Text("Weekly Ritual Report")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Theme.textPrimary)
            }

            Text(report)
                .font(.system(size: 15, weight: .regular, design: .serif))
                .foregroundColor(Theme.textSecondary)
                .italic()
        }
        .padding(Theme.spacingM)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface)
        .cornerRadius(Theme.cardRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius)
                .stroke(Theme.goldMuted.opacity(0.3), lineWidth: 1)
        )
    }
}

struct MonthlyThemeCard: View {
    let theme: String

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            HStack {
                Image(systemName: "calendar")
                    .font(.system(size: 16))
                    .foregroundColor(Theme.goldPrimary)
                Text("Monthly Theme")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Theme.textPrimary)
            }

            Text(theme)
                .font(.system(size: 15, weight: .regular, design: .serif))
                .foregroundColor(Theme.textSecondary)
        }
        .padding(Theme.spacingM)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface)
        .cornerRadius(Theme.cardRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius)
                .stroke(Theme.goldMuted.opacity(0.3), lineWidth: 1)
        )
    }
}

// R7: Seasonal Banner
struct SeasonalBanner: View {
    let seasonTheme: String
    @State private var season: RitualSeason = SeasonService.shared.currentSeason

    var body: some View {
        HStack(spacing: Theme.spacingM) {
            Image(systemName: season.icon)
                .font(.system(size: 32))
                .foregroundColor(Theme.goldPrimary)

            VStack(alignment: .leading, spacing: 2) {
                Text(season.rawValue)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Theme.textMuted)

                Text(seasonTheme)
                    .font(.system(size: 17, weight: .medium, design: .serif))
                    .foregroundColor(Theme.goldGlow)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(SeasonService.shared.daysUntilNextSeason()) days")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Theme.textMuted)
                Text("until next season")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textMuted)
            }
        }
        .padding(Theme.spacingM)
        .background(
            LinearGradient(
                colors: [Theme.goldPrimary.opacity(0.15), Theme.surface],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(Theme.cardRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius)
                .stroke(Theme.goldPrimary.opacity(0.3), lineWidth: 1)
        )
    }
}

// R7: Monthly Narrative Card
struct MonthlyNarrativeCard: View {
    let narrative: MonthlyNarrative
    @State private var isExpanded: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            HStack {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Theme.goldPrimary)
                Text("\(narrative.monthName) Ritual Report")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                if narrative.rateChangeVsLastMonth > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 10, weight: .bold))
                        Text("\(Int(narrative.rateChangeVsLastMonth * 100))%")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(Theme.success)
                } else if narrative.rateChangeVsLastMonth < -0 {
                    HStack(spacing: 2) {
                        Image(systemName: "arrow.down.right")
                            .font(.system(size: 10, weight: .bold))
                        Text("\(Int(abs(narrative.rateChangeVsLastMonth) * 100))%")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(Theme.warning)
                }
            }

            Text(narrative.openingParagraph)
                .font(.system(size: 14, design: .serif))
                .foregroundColor(Theme.textSecondary)
                .italic()

            // Stats row
            HStack(spacing: Theme.spacingM) {
                VStack(spacing: 2) {
                    Text("\(narrative.totalIntentions)")
                        .font(.system(size: 20, weight: .light, design: .serif))
                        .foregroundColor(Theme.textPrimary)
                    Text("intentions")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textMuted)
                }
                VStack(spacing: 2) {
                    Text("\(Int(narrative.successRate * 100))%")
                        .font(.system(size: 20, weight: .light, design: .serif))
                        .foregroundColor(Theme.textPrimary)
                    Text("follow-through")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textMuted)
                }
                VStack(spacing: 2) {
                    Text("\(narrative.uniquePracticeDays)")
                        .font(.system(size: 20, weight: .light, design: .serif))
                        .foregroundColor(Theme.textPrimary)
                    Text("practice days")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textMuted)
                }
                VStack(spacing: 2) {
                    Text("\(narrative.breathingMinutesTotal)")
                        .font(.system(size: 20, weight: .light, design: .serif))
                        .foregroundColor(Theme.textPrimary)
                    Text("breath mins")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textMuted)
                }
            }
            .frame(maxWidth: .infinity)

            if !isExpanded {
                Button(action: { withAnimation { isExpanded = true } }) {
                    HStack {
                        Text("Read full report")
                            .font(.system(size: 13))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11))
                    }
                    .foregroundColor(Theme.goldPrimary)
                }
                .padding(.top, Theme.spacingXS)
            } else {
                VStack(alignment: .leading, spacing: Theme.spacingS) {
                    Divider()
                        .background(Theme.goldMuted.opacity(0.3))

                    Text(narrative.categoryParagraph)
                        .font(.system(size: 14))
                        .foregroundColor(Theme.textSecondary)

                    Text(narrative.breathParagraph)
                        .font(.system(size: 14))
                        .foregroundColor(Theme.textSecondary)

                    Text(narrative.changeParagraph)
                        .font(.system(size: 14))
                        .foregroundColor(Theme.textSecondary)

                    Text(narrative.seasonalParagraph)
                        .font(.system(size: 14, design: .serif))
                        .foregroundColor(Theme.goldMuted)
                        .italic()
                }
                .padding(.top, Theme.spacingXS)

                Button(action: { withAnimation { isExpanded = false } }) {
                    HStack {
                        Text("Collapse")
                            .font(.system(size: 13))
                        Image(systemName: "chevron.up")
                            .font(.system(size: 11))
                    }
                    .foregroundColor(Theme.goldPrimary)
                }
                .padding(.top, Theme.spacingXS)
            }
        }
        .padding(Theme.spacingM)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface)
        .cornerRadius(Theme.cardRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius)
                .stroke(Theme.goldPrimary.opacity(0.3), lineWidth: 1)
        )
    }
}

// R7: HealthKit Loading Card
struct HealthKitLoadingCard: View {
    var body: some View {
        HStack(spacing: Theme.spacingM) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Theme.goldPrimary))
                .scaleEffect(0.8)
            Text("Analyzing sleep patterns...")
                .font(.system(size: 14))
                .foregroundColor(Theme.textMuted)
            Spacer()
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(Theme.cardRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius)
                .stroke(Theme.goldMuted.opacity(0.3), lineWidth: 1)
        )
    }
}

// R7: HealthKit Sleep Correlation Card
struct HealthKitSleepCorrelationCard: View {
    let report: SleepCorrelationReport

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            HStack {
                Image(systemName: report.strength.icon)
                    .font(.system(size: 16))
                    .foregroundColor(Theme.goldPrimary)
                Text("Sleep → Intention Link")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Text(report.strength.label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Theme.goldMuted)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Theme.goldPrimary.opacity(0.1))
                    .cornerRadius(Theme.compactRadius)
            }

            Text(report.headline)
                .font(.system(size: 15, weight: .medium, design: .serif))
                .foregroundColor(Theme.goldGlow)

            Text(report.body)
                .font(.system(size: 14))
                .foregroundColor(Theme.textSecondary)

            if let avgSleep = report.weeklyAverageSleep {
                HStack(spacing: Theme.spacingM) {
                    VStack(spacing: 2) {
                        Text(String(format: "%.1f", avgSleep))
                            .font(.system(size: 18, weight: .light, design: .serif))
                            .foregroundColor(Theme.textPrimary)
                        Text("hrs avg sleep")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.textMuted)
                    }
                    VStack(spacing: 2) {
                        Text("\(Int(report.intentionSuccessRate * 100))%")
                            .font(.system(size: 18, weight: .light, design: .serif))
                            .foregroundColor(Theme.textPrimary)
                        Text("intention success")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.textMuted)
                    }
                    VStack(spacing: 2) {
                        Text("\(report.daysAnalyzed)")
                            .font(.system(size: 18, weight: .light, design: .serif))
                            .foregroundColor(Theme.textPrimary)
                        Text("days analyzed")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.textMuted)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, Theme.spacingXS)
            }
        }
        .padding(Theme.spacingM)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface)
        .cornerRadius(Theme.cardRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius)
                .stroke(Theme.goldPrimary.opacity(0.4), lineWidth: 1)
        )
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: Theme.spacingS) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Theme.goldPrimary)

            Text(value)
                .font(.system(size: 28, weight: .light, design: .serif))
                .foregroundColor(Theme.textPrimary)

            Text(title)
                .font(.system(size: 12))
                .foregroundColor(Theme.textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(Theme.cardRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius)
                .stroke(Theme.goldMuted.opacity(0.3), lineWidth: 1)
        )
    }
}

struct ProgressRow: View {
    let label: String
    let value: String
    let target: Int

    private var progress: Double {
        min(Double(Int(value) ?? 0) / Double(target), 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingXS) {
            HStack {
                Text(label)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textSecondary)
                Spacer()
                Text("\(value)/\(target)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.textPrimary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Theme.surface)
                        .frame(height: 4)
                        .cornerRadius(Theme.tinyRadius)

                    Rectangle()
                        .fill(Theme.goldPrimary)
                        .frame(width: geometry.size.width * progress, height: 4)
                        .cornerRadius(Theme.tinyRadius)
                }
            }
            .frame(height: 4)
        }
        .padding(.horizontal, Theme.spacingM)
    }
}
