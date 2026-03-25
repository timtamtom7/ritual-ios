import SwiftUI

struct BreathingCircleView: View {
    let phase: BreathingPhase
    @State private var scale: CGFloat = 0.6
    @State private var glowOpacity: Double = 0.3
    @State private var innerGlow: Double = 0.2

    var body: some View {
        ZStack {
            // Outer glow ring
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Theme.goldPrimary.opacity(glowOpacity * 0.6),
                            Theme.goldPrimary.opacity(glowOpacity * 0.2),
                            Theme.goldPrimary.opacity(0)
                        ]),
                        center: .center,
                        startRadius: 60,
                        endRadius: 180
                    )
                )
                .frame(width: 360, height: 360)
                .scaleEffect(scale)
                .blur(radius: 2)

            // Main breathing circle
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Theme.goldGlow.opacity(innerGlow),
                            Theme.surface,
                            Theme.background
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: 140
                    )
                )
                .frame(width: 280, height: 280)
                .overlay(
                    Circle()
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [
                                    Theme.goldPrimary.opacity(0.8),
                                    Theme.goldMuted.opacity(0.4),
                                    Theme.goldPrimary.opacity(0.6)
                                ]),
                                center: .center,
                                startAngle: .degrees(0),
                                endAngle: .degrees(360)
                            ),
                            lineWidth: 2
                        )
                )
                .scaleEffect(scale)

            // Inner shimmer ring
            Circle()
                .fill(Color.clear)
                .frame(width: 200, height: 200)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Theme.goldPrimary.opacity(0.3),
                                    Theme.goldMuted.opacity(0.1),
                                    Theme.goldPrimary.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
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
                        .transition(.opacity)
                }
            }
        }
        .onChange(of: phase) { _, newPhase in
            animateForPhase(newPhase)
        }
        .onAppear {
            if phase == .idle {
                scale = 0.6
                glowOpacity = 0.25
                innerGlow = 0.15
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
            withAnimation(.spring(response: 3.5, dampingFraction: 0.7, blendDuration: 0)) {
                scale = 1.0
                glowOpacity = 0.7
                innerGlow = 0.4
            }
        case .holdIn:
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0)) {
                glowOpacity = 0.85
                innerGlow = 0.5
            }
        case .exhale:
            withAnimation(.spring(response: 3.5, dampingFraction: 0.75, blendDuration: 0)) {
                scale = 0.6
                glowOpacity = 0.25
                innerGlow = 0.15
            }
        case .holdOut:
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0)) {
                glowOpacity = 0.15
                innerGlow = 0.1
            }
        case .paused:
            break
        case .idle:
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7, blendDuration: 0)) {
                scale = 0.6
                glowOpacity = 0.25
                innerGlow = 0.15
            }
        }
    }
}
