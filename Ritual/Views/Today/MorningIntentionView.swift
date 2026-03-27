import SwiftUI

struct MorningIntentionView: View {
    let onComplete: (String) -> Void
    let onDismiss: () -> Void

    @State private var currentStep: Int = 0
    @State private var intentionText: String = ""
    @State private var breathingPhase: Int = 0
    @State private var breathingTask: Task<Void, Never>?

    private let breathingCount = 3
    private let breathDuration: Double = 4.0

    var body: some View {
        VStack(spacing: Theme.spacingL) {
            if currentStep == 0 {
                settlingView
            } else {
                intentionInputView
            }
        }
        .animation(.easeInOut(duration: 0.6), value: currentStep)
        .onDisappear {
            breathingTask?.cancel()
            breathingPhase = 0
        }
    }

    private var settlingView: some View {
        VStack(spacing: Theme.spacingL) {
            Spacer()

            Text("Take a moment to arrive")
                .font(.system(size: 28, weight: .regular, design: .serif))
                .foregroundColor(Theme.textPrimary)
                .multilineTextAlignment(.center)

            Text("Three breaths to settle in")
                .font(.system(size: 17))
                .foregroundColor(Theme.textSecondary)

            BreathingCircleView(phase: currentBreathingPhase)
                .frame(height: 320)
                .padding(.vertical, Theme.spacingL)

            Text("Breath \(breathingPhase + 1) of \(breathingCount)")
                .font(.system(size: 14))
                .foregroundColor(Theme.textMuted)

            Spacer()

            Button(action: { HapticFeedback.impact(.light); currentStep = 1 }) {
                Text("Skip")
                    .font(.system(size: 15))
                    .foregroundColor(Theme.textMuted)
            }
            .accessibilityLabel("Skip breathing exercise")
            .padding(.bottom, Theme.spacingM)
        }
        .onAppear {
            startBreathingGuide()
        }
        .onDisappear {
            breathingTask?.cancel()
        }
    }

    private var intentionInputView: some View {
        VStack(spacing: Theme.spacingL) {
            Text("What is your intention for today?")
                .font(.system(size: 24, weight: .regular, design: .serif))
                .foregroundColor(Theme.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.top, Theme.spacingXL)

            Spacer()

            IntentionInputView(
                text: $intentionText,
                onSubmit: {
                    if !intentionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        onComplete(intentionText.trimmingCharacters(in: .whitespacesAndNewlines))
                    }
                }
            )

            Spacer()
        }
    }

    private var currentBreathingPhase: BreathingPhase {
        let phaseInCycle = breathingPhase % 4
        switch phaseInCycle {
        case 0: return .inhale
        case 1: return .holdIn
        case 2: return .exhale
        case 3: return .holdOut
        default: return .idle
        }
    }

    private func startBreathingGuide() {
        breathingTask = Task { @MainActor in
            for i in 0..<(self.breathingCount * 4) {
                try? await Task.sleep(nanoseconds: UInt64(self.breathDuration * 1_000_000_000))
                if Task.isCancelled || self.currentStep != 0 { break }
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.breathingPhase = i + 1
                }
            }
            if self.currentStep != 0 { return }
            withAnimation {
                self.currentStep = 1
            }
        }
    }
}
