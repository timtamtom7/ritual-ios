import SwiftUI

struct BreathingSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var breathingService = BreathingService.shared

    @State private var selectedPattern: BreathingPattern = .box
    @State private var selectedDuration: Int = 3
    @State private var isSessionActive: Bool = false
    @State private var showHistory: Bool = false

    private let durations = [1, 3, 5, 10]

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            if isSessionActive {
                activeSessionView
            } else {
                setupView
            }
        }
        .onDisappear {
            breathingService.stopSession()
        }
        .sheet(isPresented: $showHistory) {
            BreathingHistoryView()
        }
    }

    private var setupView: some View {
        VStack(spacing: Theme.spacingXL) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Theme.textMuted)
                }
                Spacer()
                Button(action: { showHistory = true }) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 16))
                        .foregroundColor(Theme.goldMuted)
                }
            }
            .padding(.horizontal, Theme.spacingM)

            Spacer()

            Text("Breathe")
                .font(.system(size: 48, weight: .light, design: .serif))
                .foregroundColor(Theme.textPrimary)

            // Adaptive suggestion
            AdaptiveBreathingHint()

            VStack(spacing: Theme.spacingS) {
                Text("Select your pattern")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textMuted)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.spacingS) {
                        ForEach(BreathingPattern.allCases, id: \.self) { pattern in
                            PatternButton(
                                title: pattern.rawValue,
                                subtitle: pattern.suggestedTime,
                                isSelected: selectedPattern == pattern
                            ) {
                                selectedPattern = pattern
                            }
                            .frame(width: 80)
                        }
                    }
                    .padding(.horizontal, Theme.spacingM)
                }
            }

            VStack(spacing: Theme.spacingS) {
                Text("Duration")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textMuted)

                HStack(spacing: Theme.spacingS) {
                    ForEach(durations, id: \.self) { duration in
                        DurationButton(
                            minutes: duration,
                            isSelected: selectedDuration == duration
                        ) {
                            selectedDuration = duration
                        }
                    }
                }
            }

            Spacer()

            PrimaryButton(title: "Begin") {
                startSession()
            }
            .padding(.horizontal, Theme.spacingM)
            .padding(.bottom, Theme.spacingXL)
        }
    }

    private var activeSessionView: some View {
        VStack(spacing: Theme.spacingXL) {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Theme.textMuted)
            }
            .padding(.horizontal, Theme.spacingM)

            Spacer()

            BreathingCircleView(phase: breathingService.currentPhase)
                .frame(height: 320)

            Spacer()

            VStack(spacing: Theme.spacingS) {
                Text(selectedPattern.rawValue)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(Theme.textPrimary)

                Text("\(selectedDuration) minute\(selectedDuration == 1 ? "" : "s")")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textMuted)
            }

            Button(action: togglePause) {
                Text(breathingService.isPaused ? "Resume" : "Pause")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(Theme.goldPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Theme.goldPrimary.opacity(0.1))
                    .cornerRadius(Theme.buttonRadius)
            }
            .padding(.horizontal, Theme.spacingM)

            Button(action: stopSession) {
                Text("End Session")
                    .font(.system(size: 15))
                    .foregroundColor(Theme.textMuted)
            }
            .padding(.bottom, Theme.spacingXL)
        }
    }

    private func startSession() {
        isSessionActive = true
        breathingService.startSession(pattern: selectedPattern, durationMinutes: selectedDuration, hapticEnabled: true)
    }

    private func togglePause() {
        if breathingService.isPaused {
            breathingService.resumeSession()
        } else {
            breathingService.pauseSession()
        }
    }

    private func stopSession() {
        breathingService.stopSession()
        isSessionActive = false
        dismiss()
    }
}

struct AdaptiveBreathingHint: View {
    @State private var suggestion: String = ""

    var body: some View {
        Text(suggestion)
            .font(.system(size: 13, design: .serif))
            .foregroundColor(Theme.goldMuted)
            .italic()
            .onAppear {
                suggestion = getSuggestion()
            }
    }

    private func getSuggestion() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 10 {
            return "Calm or Energize works well for morning clarity"
        } else if hour >= 20 || hour < 6 {
            return "Sleep pattern helps wind down before rest"
        } else if hour < 14 {
            return "Box breathing brings focus for the day ahead"
        } else {
            return "Coherent breathing balances energy and calm"
        }
    }
}

// MARK: - Breathing History

struct BreathingHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var sessions: [BreathingSession] = []

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                if sessions.isEmpty {
                    emptyView
                } else {
                    historyList
                }
            }
            .navigationTitle("Breathing History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Text("Done")
                            .font(.system(size: 16))
                            .foregroundColor(Theme.goldPrimary)
                    }
                }
            }
            .onAppear {
                sessions = DatabaseService.shared.getBreathingHistory()
            }
        }
    }

    private var emptyView: some View {
        VStack(spacing: Theme.spacingM) {
            Image(systemName: "wind")
                .font(.system(size: 48))
                .foregroundColor(Theme.goldMuted.opacity(0.5))

            Text("No breathing sessions yet")
                .font(.system(size: 20, weight: .regular, design: .serif))
                .foregroundColor(Theme.textSecondary)
        }
    }

    private var historyList: some View {
        ScrollView {
            LazyVStack(spacing: Theme.spacingS) {
                ForEach(sessions) { session in
                    BreathingSessionRow(session: session)
                }
            }
            .padding(.horizontal, Theme.spacingM)
            .padding(.vertical, Theme.spacingS)
        }
    }
}

struct BreathingSessionRow: View {
    let session: BreathingSession

    var body: some View {
        HStack(spacing: Theme.spacingM) {
            Image(systemName: "wind")
                .font(.system(size: 16))
                .foregroundColor(Theme.goldPrimary)
                .frame(width: 32, height: 32)
                .background(Theme.goldPrimary.opacity(0.1))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 2) {
                Text(session.pattern.rawValue)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Theme.textPrimary)

                Text(formattedDate)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.textMuted)
            }

            Spacer()

            Text(formattedDuration)
                .font(.system(size: 14))
                .foregroundColor(Theme.textSecondary)

            Image(systemName: session.completed ? "checkmark.circle.fill" : "xmark.circle")
                .font(.system(size: 16))
                .foregroundColor(session.completed ? Theme.success : Theme.textMuted)
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(Theme.cardRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius)
                .stroke(Theme.goldMuted.opacity(0.2), lineWidth: 1)
        )
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: session.createdAt)
    }

    private var formattedDuration: String {
        let minutes = session.durationSeconds / 60
        return "\(minutes)m"
    }
}

// MARK: - Pattern Buttons

struct PatternButton: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                Text(subtitle)
                    .font(.system(size: 11))
            }
            .foregroundColor(isSelected ? Theme.background : Theme.textSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(isSelected ? Theme.goldPrimary : Theme.surface)
            .cornerRadius(Theme.buttonRadius)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.buttonRadius)
                    .stroke(Theme.goldMuted.opacity(0.3), lineWidth: isSelected ? 0 : 1)
            )
        }
    }
}

struct DurationButton: View {
    let minutes: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("\(minutes)m")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(isSelected ? Theme.background : Theme.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(isSelected ? Theme.goldPrimary : Theme.surface)
                .cornerRadius(Theme.buttonRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.buttonRadius)
                        .stroke(Theme.goldMuted.opacity(0.3), lineWidth: isSelected ? 0 : 1)
                )
        }
    }
}
