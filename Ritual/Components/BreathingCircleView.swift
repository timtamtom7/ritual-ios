import SwiftUI

struct BreathingCircleView: View {
    let phase: BreathingPhase
    @State private var scale: CGFloat = 0.6
    @State private var glowOpacity: Double = 0.3

    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Theme.goldPrimary.opacity(glowOpacity * 0.5),
                            Theme.goldPrimary.opacity(0)
                        ]),
                        center: .center,
                        startRadius: 80,
                        endRadius: 160
                    )
                )
                .frame(width: 320, height: 320)
                .scaleEffect(scale)

            // Main circle
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Theme.surface,
                            Theme.background
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: 130
                    )
                )
                .frame(width: 260, height: 260)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Theme.goldPrimary, Theme.goldMuted],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .scaleEffect(scale)

            // Inner ring
            Circle()
                .fill(Color.clear)
                .frame(width: 200, height: 200)
                .overlay(
                    Circle()
                        .stroke(Theme.goldMuted.opacity(0.3), lineWidth: 1)
                )

            // Center text
            VStack(spacing: 12) {
                Text(phase.rawValue)
                    .font(.system(size: 24, weight: .light, design: .serif))
                    .foregroundColor(Theme.textPrimary)
                    .multilineTextAlignment(.center)

                if phase != .idle && phase != .paused {
                    Text(phaseHint)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Theme.textSecondary)
                }
            }
        }
        .onChange(of: phase) { _, newPhase in
            animateForPhase(newPhase)
        }
        .onAppear {
            if phase == .idle {
                scale = 0.6
                glowOpacity = 0.3
            }
        }
    }

    private var phaseHint: String {
        switch phase {
        case .inhale: return "Let your chest expand"
        case .holdIn, .holdOut: return "Feel the stillness"
        case .exhale: return "Release gently"
        default: return ""
        }
    }

    private func animateForPhase(_ phase: BreathingPhase) {
        switch phase {
        case .inhale:
            withAnimation(.easeInOut(duration: 4)) {
                scale = 1.0
                glowOpacity = 0.6
            }
        case .holdIn:
            withAnimation(.easeInOut(duration: 0.5)) {
                glowOpacity = 0.8
            }
        case .exhale:
            withAnimation(.easeInOut(duration: 4)) {
                scale = 0.6
                glowOpacity = 0.3
            }
        case .holdOut:
            withAnimation(.easeInOut(duration: 0.5)) {
                glowOpacity = 0.2
            }
        case .paused:
            break
        case .idle:
            withAnimation(.easeInOut(duration: 0.8)) {
                scale = 0.6
                glowOpacity = 0.3
            }
        }
    }
}
