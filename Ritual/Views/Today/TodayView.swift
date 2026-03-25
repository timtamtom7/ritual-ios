import SwiftUI

struct TodayView: View {
    @StateObject private var viewModel = TodayViewModel()
    @State private var showingBreathing = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.spacingL) {
                        streakSection
                        headerSection

                        if viewModel.showMorningFlow {
                            morningFlowSection
                        } else if viewModel.todaysIntention != nil {
                            intentionSection
                        }

                        breathingButton

                        if viewModel.showEveningFlow {
                            eveningFlowSection
                        } else if viewModel.todaysCheckIn != nil {
                            checkInSummary
                        }
                    }
                    .padding(.horizontal, Theme.spacingM)
                    .padding(.vertical, Theme.spacingL)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(greeting)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(Theme.textPrimary)
                }
            }
            .sheet(isPresented: $showingBreathing) {
                BreathingSessionView()
            }
            .onAppear {
                viewModel.loadTodaysData()
            }
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 {
            return "Good Morning"
        } else if hour < 17 {
            return "Good Afternoon"
        } else {
            return "Good Evening"
        }
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }

    @ViewBuilder
    private var streakSection: some View {
        let streak = viewModel.streakData
        VStack(spacing: Theme.spacingS) {
            if streak.hasStreak {
                StreakFlameView(streak: streak.currentStreak)
                    .frame(height: 60)
            }

            HStack(spacing: Theme.spacingL) {
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        if streak.hasStreak {
                            StreakFlameIcon()
                        }
                        Text("\(streak.currentStreak)")
                            .font(.system(size: 24, weight: .light, design: .serif))
                            .foregroundColor(Theme.textPrimary)
                    }
                    Text("Current")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textMuted)
                }

                VStack(spacing: 4) {
                    Text("\(streak.longestStreak)")
                        .font(.system(size: 24, weight: .light, design: .serif))
                        .foregroundColor(Theme.textPrimary)
                    Text("Longest")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textMuted)
                }

                VStack(spacing: 4) {
                    Text("\(streak.streakFreezes)")
                        .font(.system(size: 24, weight: .light, design: .serif))
                        .foregroundColor(Theme.textPrimary)
                    Text("Freezes")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textMuted)
                }
            }

            if let anniversary = viewModel.streakAnniversary {
                Text(anniversary)
                    .font(.system(size: 13, weight: .regular, design: .serif))
                    .foregroundColor(Theme.goldMuted)
                    .italic()
                    .multilineTextAlignment(.center)
                    .padding(.top, Theme.spacingXS)
            }

            if !streak.missedDays.isEmpty {
                MissTrackerView(missedDays: streak.missedDays)
            }
        }
        .padding(Theme.spacingM)
        .frame(maxWidth: .infinity)
        .background(Theme.surface)
        .cornerRadius(Theme.cardRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius)
                .stroke(Theme.goldMuted.opacity(0.3), lineWidth: 1)
        )
    }

    private var headerSection: some View {
        VStack(spacing: Theme.spacingS) {
            Text(dateString)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Theme.textMuted)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var morningFlowSection: some View {
        MorningIntentionView(
            onComplete: { text in
                viewModel.saveIntention(text)
            },
            onDismiss: {
                viewModel.showMorningFlow = false
            }
        )
    }

    @ViewBuilder
    private var intentionSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            Text("Today's Intention")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Theme.textMuted)
                .textCase(.uppercase)
                .tracking(1)

            if let intention = viewModel.todaysIntention {
                IntentionCard(intention: intention, isHighlighted: true)
            }
        }
    }

    private var breathingButton: some View {
        Button(action: { showingBreathing = true }) {
            HStack(spacing: Theme.spacingS) {
                Image(systemName: "wind")
                    .font(.system(size: 18))
                Text("Breathe")
                    .font(.system(size: 17, weight: .medium))
            }
            .foregroundColor(Theme.goldPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Theme.goldPrimary.opacity(0.1))
            .cornerRadius(Theme.buttonRadius)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.buttonRadius)
                    .stroke(Theme.goldMuted.opacity(0.3), lineWidth: 1)
            )
        }
        .padding(.top, Theme.spacingS)
    }

    @ViewBuilder
    private var eveningFlowSection: some View {
        EveningCheckInView(
            onComplete: { acted, reflection in
                viewModel.saveCheckIn(acted: acted, reflection: reflection)
            },
            onDismiss: {
                viewModel.showEveningFlow = false
            }
        )
    }

    @ViewBuilder
    private var checkInSummary: some View {
        if let checkIn = viewModel.todaysCheckIn {
            VStack(alignment: .leading, spacing: Theme.spacingS) {
                Text("Evening Check-In")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Theme.textMuted)
                    .textCase(.uppercase)
                    .tracking(1)

                HStack {
                    Image(systemName: checkIn.acted ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(checkIn.acted ? Theme.success : Theme.warning)
                        .font(.system(size: 24))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(checkIn.acted ? "You acted on your intention" : "You didn't quite get there")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(Theme.textPrimary)

                        if let reflection = checkIn.reflection, !reflection.isEmpty {
                            Text(reflection)
                                .font(.system(size: 14))
                                .foregroundColor(Theme.textSecondary)
                                .lineLimit(2)
                        }
                    }
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
            .padding(.top, Theme.spacingS)
        }
    }
}

// MARK: - Streak Components

struct StreakFlameView: View {
    let streak: Int
    @State private var flicker: Double = 1.0

    var body: some View {
        HStack(spacing: Theme.spacingS) {
            StreakFlameIcon()
            Text("\(streak)-day streak")
                .font(.system(size: 17, weight: .medium, design: .serif))
                .foregroundColor(Theme.goldPrimary)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                flicker = 1.1
            }
        }
        .scaleEffect(flicker)
    }
}

struct StreakFlameIcon: View {
    @State private var flameScale: CGFloat = 1.0
    @State private var flameOpacity: Double = 1.0

    var body: some View {
        Image(systemName: "flame.fill")
            .font(.system(size: 28))
            .foregroundStyle(
                LinearGradient(
                    colors: [Theme.goldPrimary, Theme.warning],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .shadow(color: Theme.goldPrimary.opacity(0.5), radius: 6, x: 0, y: 2)
            .scaleEffect(flameScale)
            .opacity(flameOpacity)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    flameScale = 1.15
                    flameOpacity = 0.85
                }
            }
    }
}

struct MissTrackerView: View {
    let missedDays: [Date]
    @State private var isExpanded = false

    private var recentMisses: [Date] {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        return missedDays.filter { $0 >= weekAgo }.sorted(by: >)
    }

    var body: some View {
        if !recentMisses.isEmpty {
            VStack(alignment: .leading, spacing: Theme.spacingXS) {
                Button(action: { withAnimation { isExpanded.toggle() } }) {
                    HStack {
                        Image(systemName: "xmark.circle")
                            .font(.system(size: 12))
                        Text("Missed \(recentMisses.count) day\(recentMisses.count == 1 ? "" : "s") this week")
                            .font(.system(size: 13))
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(Theme.textMuted)
                }

                if isExpanded {
                    HStack(spacing: 6) {
                        ForEach(recentMisses.prefix(7), id: \.self) { date in
                            MissDot(date: date)
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
    }
}

struct MissDot: View {
    let date: Date

    var body: some View {
        VStack(spacing: 2) {
            Circle()
                .fill(Theme.warning.opacity(0.3))
                .frame(width: 24, height: 24)
                .overlay(
                    Text(dayAbbrev)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(Theme.warning)
                )
        }
    }

    private var dayAbbrev: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return String(formatter.string(from: date).prefix(1))
    }
}
