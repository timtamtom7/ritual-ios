import SwiftUI

/// R14: Vision Pro spatial breathing room
/// Immersive environments for mindfulness
struct SpatialBreathingView: View {
    @StateObject private var breathingService = BreathingService.shared
    @State private var selectedEnvironment: BreathingEnvironment = .calmForest
    @State private var isSessionActive = false
    @State private var currentPhase: BreathPhase = .inhale

    enum BreathingEnvironment: String, CaseIterable {
        case calmForest = "Calm Forest"
        case oceanWaves = "Ocean Waves"
        case mountainPeak = "Mountain Peak"
        case nightSky = "Night Sky"

        var gradientColors: [Color] {
            switch self {
            case .calmForest: return [Color(hex: "1A3A2A"), Color(hex: "2D5A3D"), Color(hex: "3D7A4D")]
            case .oceanWaves: return [Color(hex: "1A2A3A"), Color(hex: "2A4A5A"), Color(hex: "3A6A8A")]
            case .mountainPeak: return [Color(hex: "2A2A3A"), Color(hex: "3A3A5A"), Color(hex: "4A4A7A")]
            case .nightSky: return [Color(hex: "0A0A1A"), Color(hex: "1A1A3A"), Color(hex: "2A2A5A")]
            }
        }

        var icon: String {
            switch self {
            case .calmForest: return "leaf.fill"
            case .oceanWaves: return "water.waves"
            case .mountainPeak: return "mountain.2.fill"
            case .nightSky: return "moon.stars.fill"
            }
        }
    }

    enum BreathPhase: String {
        case inhale = "Breathe In"
        case hold = "Hold"
        case exhale = "Breathe Out"
        case rest = "Rest"
    }

    var body: some View {
        ZStack {
            // Environment background
            LinearGradient(
                colors: selectedEnvironment.gradientColors,
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                // Environment selector
                environmentSelector

                Spacer()

                // Breathing circle
                breathingCircle

                // Phase text
                phaseText

                Spacer()

                // Controls
                controlButtons
            }
            .padding()
        }
    }

    private var environmentSelector: some View {
        HStack(spacing: 16) {
            ForEach(BreathingEnvironment.allCases, id: \.self) { env in
                Button {
                    withAnimation {
                        selectedEnvironment = env
                    }
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: env.icon)
                            .font(.title2)
                        Text(env.rawValue)
                            .font(.caption)
                    }
                    .foregroundColor(selectedEnvironment == env ? .white : .white.opacity(0.5))
                    .padding()
                    .background(selectedEnvironment == env ? Color.white.opacity(0.2) : Color.clear)
                    .cornerRadius(12)
                }
            }
        }
    }

    private var breathingCircle: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(currentPhase == .inhale ? Color.white.opacity(0.1) : Color.clear)
                .frame(width: 280, height: 280)
                .blur(radius: 20)

            // Main circle
            Circle()
                .stroke(Color.white.opacity(0.3), lineWidth: 4)
                .frame(width: 200, height: 200)

            // Animated inner circle
            Circle()
                .fill(Color.white.opacity(0.5))
                .frame(width: breathingCircleSize, height: breathingCircleSize)
                .animation(.easeInOut(duration: 4), value: currentPhase)
        }
    }

    private var breathingCircleSize: CGFloat {
        switch currentPhase {
        case .inhale: return 100
        case .hold: return 140
        case .exhale: return 80
        case .rest: return 100
        }
    }

    private var phaseText: some View {
        Text(currentPhase.rawValue)
            .font(.title)
            .fontWeight(.light)
            .foregroundColor(.white)
            .animation(.easeInOut, value: currentPhase)
    }

    private var controlButtons: some View {
        HStack(spacing: 20) {
            if isSessionActive {
                Button {
                    isSessionActive = false
                } label: {
                    Label("End", systemImage: "stop.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red.opacity(0.6))
                        .cornerRadius(12)
                }
            } else {
                Button {
                    startSession()
                } label: {
                    Label("Begin", systemImage: "play.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green.opacity(0.6))
                        .cornerRadius(12)
                }
            }
        }
    }

    private func startSession() {
        isSessionActive = true
        // Breathing cycle: 4s inhale, 4s hold, 6s exhale, 2s rest
        Timer.scheduledTimer(withTimeInterval: 4, repeats: true) { timer in
            if !isSessionActive {
                timer.invalidate()
                return
            }
            withAnimation {
                switch currentPhase {
                case .inhale: currentPhase = .hold
                case .hold: currentPhase = .exhale
                case .exhale: currentPhase = .rest
                case .rest: currentPhase = .inhale
                }
            }
        }
    }
}
