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
                    Button(action: { viewModel.refresh() }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16))
                            .foregroundColor(Theme.goldPrimary)
                    }
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
                        .cornerRadius(2)

                    Rectangle()
                        .fill(Theme.goldPrimary)
                        .frame(width: geometry.size.width * progress, height: 4)
                        .cornerRadius(2)
                }
            }
            .frame(height: 4)
        }
        .padding(.horizontal, Theme.spacingM)
    }
}
