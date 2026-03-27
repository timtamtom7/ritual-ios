import SwiftUI

struct TimelineView: View {
    @StateObject private var viewModel = TimelineViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                if viewModel.isEmpty {
                    emptyStateView
                } else {
                    timelineList
                }
            }
            .navigationTitle("Timeline")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear {
                viewModel.loadTimeline()
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: Theme.spacingM) {
            RitualEmptyIllustration(size: 180)

            Text("Your ritual begins\nwhen you're ready.")
                .font(.system(size: 20, weight: .regular, design: .serif))
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private var timelineList: some View {
        ScrollView {
            LazyVStack(spacing: Theme.spacingL, pinnedViews: .sectionHeaders) {
                ForEach(viewModel.weekGroups) { group in
                    Section {
                        ForEach(group.entries) { entry in
                            TimelineRowView(entry: entry)
                        }
                    } header: {
                        WeekHeaderView(label: group.weekLabel)
                    }
                }
            }
            .padding(.horizontal, Theme.spacingM)
            .padding(.vertical, Theme.spacingS)
        }
    }
}

struct WeekHeaderView: View {
    let label: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Theme.textMuted)
            Spacer()
        }
        .padding(.vertical, Theme.spacingS)
        .background(Theme.background)
    }
}

struct TimelineRowView: View {
    let entry: TimelineEntry
    @State private var isExpanded: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            HStack(alignment: .top, spacing: Theme.spacingM) {
                // Date column
                VStack(alignment: .center, spacing: 2) {
                    Text(dayNumber)
                        .font(.system(size: 24, weight: .light, design: .serif))
                        .foregroundColor(Theme.textPrimary)
                    Text(dayAbbrev)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.textMuted)
                }
                .frame(width: 48)

                // Content
                VStack(alignment: .leading, spacing: Theme.spacingS) {
                    Text(entry.intention.text)
                        .font(.system(size: 17, weight: .regular, design: .serif))
                        .foregroundColor(Theme.textPrimary)
                        .lineLimit(isExpanded ? nil : 2)

                    HStack(spacing: Theme.spacingS) {
                        if let checkIn = entry.checkIn {
                            CheckInStatusBadge(acted: checkIn.acted)
                        }

                        if entry.hasReflection {
                            Button(action: { withAnimation { isExpanded.toggle() } }) {
                                HStack(spacing: 4) {
                                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 10))
                                    Text("Reflection")
                                        .font(.system(size: 12))
                                }
                                .foregroundColor(Theme.textMuted)
                            }
                        }
                    }
                }
            }

            if isExpanded, let reflection = entry.checkIn?.reflection, !reflection.isEmpty {
                Text(reflection)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textSecondary)
                    .padding(.leading, 48 + Theme.spacingM)
                    .padding(.top, Theme.spacingXS)
            }
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(Theme.cardRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius)
                .stroke(Theme.goldMuted.opacity(0.2), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if entry.hasReflection {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }
        }
    }

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: entry.date)
    }

    private var dayAbbrev: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: entry.date).uppercased()
    }
}

struct CheckInStatusBadge: View {
    let acted: Bool

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: acted ? "checkmark" : "xmark")
                .font(.system(size: 10, weight: .bold))
            Text(acted ? "Acted" : "Didn't")
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundColor(acted ? Theme.success : Theme.warning)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background((acted ? Theme.success : Theme.warning).opacity(0.15))
        .cornerRadius(Theme.compactRadius)
    }
}
