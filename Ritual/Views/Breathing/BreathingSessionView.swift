import SwiftUI

struct BreathingSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var breathingService = BreathingService.shared

    @State private var selectedPattern: BreathingPattern = .box
    @State private var selectedDuration: Int = 3
    @State private var isSessionActive: Bool = false
    @State private var showSettings: Bool = false

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
            }
            .padding(.horizontal, Theme.spacingM)

            Spacer()

            Text("Breathe")
                .font(.system(size: 48, weight: .light, design: .serif))
                .foregroundColor(Theme.textPrimary)

            VStack(spacing: Theme.spacingS) {
                Text("Select your pattern")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textMuted)

                HStack(spacing: Theme.spacingS) {
                    ForEach(BreathingPattern.allCases, id: \.self) { pattern in
                        PatternButton(
                            title: pattern.rawValue,
                            subtitle: pattern.description,
                            isSelected: selectedPattern == pattern
                        ) {
                            selectedPattern = pattern
                        }
                    }
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

struct PatternButton: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                Text(subtitle)
                    .font(.system(size: 12))
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
