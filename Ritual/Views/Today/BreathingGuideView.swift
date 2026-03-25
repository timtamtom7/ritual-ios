import SwiftUI

struct BreathingGuideView: View {
    let breathCount: Int
    let onComplete: () -> Void

    @State private var currentBreath: Int = 0
    @State private var phase: BreathingPhase = .inhale

    private let breathDuration: Double = 4.0

    var body: some View {
        VStack(spacing: Theme.spacingL) {
            Spacer()

            Text("Breath \(min(currentBreath + 1, breathCount))")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.textMuted)

            BreathingCircleView(phase: phase)
                .frame(height: 280)

            Text(phaseText)
                .font(.system(size: 17))
                .foregroundColor(Theme.textSecondary)

            Spacer()
        }
        .onAppear {
            startBreathingCycle()
        }
    }

    private var phaseText: String {
        switch phase {
        case .inhale: return "Breathe in slowly..."
        case .holdIn: return "Hold..."
        case .exhale: return "Breathe out..."
        case .holdOut: return "Hold..."
        default: return ""
        }
    }

    private func startBreathingCycle() {
        Timer.scheduledTimer(withTimeInterval: breathDuration, repeats: true) { timer in
            let phaseIndex = currentBreath % 4

            withAnimation(.easeInOut(duration: 0.3)) {
                switch phaseIndex {
                case 0: phase = .inhale
                case 1: phase = .holdIn
                case 2: phase = .exhale
                case 3: phase = .holdOut
                default: break
                }
            }

            currentBreath += 1

            if currentBreath >= breathCount {
                timer.invalidate()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    onComplete()
                }
            }
        }
    }
}
