import SwiftUI
import WatchKit

@main
struct RitualWatchApp: App {
    var body: some Scene {
        WindowGroup {
            WatchHomeView()
        }
    }
}

struct WatchHomeView: View {
    @State private var selectedPattern: BreathingPattern = .calm
    @State private var isBreathing = false
    @State private var currentPhase: BreathingPhase = .idle
    @State private var timeRemaining: Int = 3
    @State private var sessionComplete = false

    var body: some View {
        NavigationStack {
            if isBreathing {
                BreathingWatchView(
                    pattern: selectedPattern,
                    isBreathing: $isBreathing,
                    currentPhase: $currentPhase,
                    timeRemaining: $timeRemaining,
                    sessionComplete: $sessionComplete
                )
            } else if sessionComplete {
                SessionCompleteView(onDismiss: {
                    sessionComplete = false
                    WKInterfaceDevice.current().play(.success)
                })
            } else {
                patternSelectionView
            }
        }
    }

    private var patternSelectionView: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("Choose Your Breath")
                    .font(.headline)
                    .foregroundColor(.gold)

                ForEach(BreathingPattern.allCases.filter { $0 != .custom }, id: \.self) { pattern in
                    Button {
                        selectedPattern = pattern
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(pattern.rawValue)
                                    .font(.system(.callout, design: .rounded))
                                    .fontWeight(.medium)
                                Text(pattern.description)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if selectedPattern == pattern {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.gold)
                            }
                        }
                    }
                    .buttonStyle(.bordered)
                    .tint(selectedPattern == pattern ? .gold : .secondary)
                }

                Button {
                    startSession()
                } label: {
                    Label("Begin Session", systemImage: "wind")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .tint(.gold)
                .padding(.top, 8)
            }
            .padding()
        }
        .navigationTitle("Ritual")
    }

    private func startSession() {
        isBreathing = true
        currentPhase = .idle
        WKInterfaceDevice.current().play(.start)
    }
}

// MARK: - Breathing Watch View

struct BreathingWatchView: View {
    let pattern: BreathingPattern
    @Binding var isBreathing: Bool
    @Binding var currentPhase: BreathingPhase
    @Binding var timeRemaining: Int
    @Binding var sessionComplete: Bool

    @State private var isPaused = false
    @State private var loopCount = 0
    @State private var phaseIndex = 0
    @State private var timer: Timer?

    private let goldColor = Color(red: 0.788, green: 0.663, blue: 0.431)

    var body: some View {
        VStack(spacing: 8) {
            // Phase display
            Text(currentPhase.rawValue)
                .font(.system(.title3, design: .rounded))
                .fontWeight(.medium)
                .foregroundColor(goldColor)
                .animation(.easeInOut(duration: 0.3), value: currentPhase)

            // Circle animation
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 4)
                    .frame(width: 80, height: 80)

                Circle()
                    .trim(from: 0, to: circleScale)
                    .stroke(goldColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: circleScale)

                Text("\(timeRemaining)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }

            // Loop counter
            Text("Loop \(loopCount)")
                .font(.caption2)
                .foregroundColor(.secondary)

            // Controls
            HStack(spacing: 16) {
                Button {
                    if isPaused {
                        resumeSession()
                    } else {
                        pauseSession()
                    }
                } label: {
                    Image(systemName: isPaused ? "play.fill" : "pause.fill")
                }
                .buttonStyle(.bordered)

                Button {
                    stopSession()
                } label: {
                    Image(systemName: "stop.fill")
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
            .padding(.top, 4)
        }
        .padding()
        .onAppear {
            startPhaseLoop()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    private var circleScale: CGFloat {
        switch currentPhase {
        case .inhale: return 1.0
        case .holdIn: return 1.0
        case .exhale: return 0.5
        case .holdOut: return 0.5
        default: return 0.7
        }
    }

    private func startPhaseLoop() {
        runNextPhase()
    }

    private func runNextPhase() {
        guard !isPaused else { return }

        let phases = pattern.phases
        if phaseIndex >= phases.count {
            phaseIndex = 0
            loopCount += 1
        }

        let phase = phases[phaseIndex]

        // Determine BreathingPhase
        switch phase.name {
        case "Breathe In": currentPhase = .inhale
        case "Hold": currentPhase = phaseIndex == 1 ? .holdIn : .holdOut
        case "Breathe Out": currentPhase = .exhale
        default: currentPhase = .idle
        }

        // Play haptic
        WKInterfaceDevice.current().play(.click)
        playPhaseHaptic()

        // Countdown timer
        var remaining = Int(phase.duration)
        timeRemaining = remaining

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { t in
            remaining -= 1
            timeRemaining = remaining
            if remaining <= 0 {
                t.invalidate()
                phaseIndex += 1
                runNextPhase()
            }
        }
    }

    private func playPhaseHaptic() {
        switch currentPhase {
        case .inhale:
            WKInterfaceDevice.current().play(.click)
        case .exhale:
            WKInterfaceDevice.current().play(.click)
        case .holdIn, .holdOut:
            WKInterfaceDevice.current().play(.start)
        default:
            break
        }
    }

    private func pauseSession() {
        isPaused = true
        timer?.invalidate()
        WKInterfaceDevice.current().play(.pause)
    }

    private func resumeSession() {
        isPaused = false
        runNextPhase()
    }

    private func stopSession() {
        timer?.invalidate()
        isBreathing = false
        WKInterfaceDevice.current().play(.stop)
    }
}

// MARK: - Session Complete View

struct SessionCompleteView: View {
    let onDismiss: () -> Void

    private let goldColor = Color(red: 0.788, green: 0.663, blue: 0.431)

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(goldColor)

            Text("Session Complete")
                .font(.headline)
                .foregroundColor(.primary)

            Text("Well done.")
                .font(.caption)
                .foregroundColor(.secondary)

            Button {
                onDismiss()
            } label: {
                Text("Done")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .tint(goldColor)
        }
        .padding()
    }
}

// MARK: - Shared Models (duplicated for watchOS standalone)

enum BreathingPattern: String, Codable, CaseIterable {
    case box = "Box"
    case calm = "Calm"
    case energize = "Energize"
    case coherent = "Coherent"
    case extendedExhale = "Extended Exhale"
    case sleep = "Sleep"
    case custom = "Custom"

    var description: String {
        switch self {
        case .box: return "4-4-4-4"
        case .calm: return "4-7-8"
        case .energize: return "6-0-6-0"
        case .coherent: return "5-5"
        case .extendedExhale: return "4-8"
        case .sleep: return "4-7-8"
        case .custom: return "Personal"
        }
    }

    var phases: [(name: String, duration: Double)] {
        switch self {
        case .box:
            return [("Breathe In", 4), ("Hold", 4), ("Breathe Out", 4), ("Hold", 4)]
        case .calm:
            return [("Breathe In", 4), ("Hold", 7), ("Breathe Out", 8)]
        case .energize:
            return [("Breathe In", 6), ("Breathe Out", 6)]
        case .coherent:
            return [("Breathe In", 5), ("Breathe Out", 5)]
        case .extendedExhale:
            return [("Breathe In", 4), ("Breathe Out", 8)]
        case .sleep:
            return [("Breathe In", 4), ("Hold", 7), ("Breathe Out", 8)]
        case .custom:
            return [("Breathe In", 4), ("Hold", 4), ("Breathe Out", 4), ("Hold", 4)]
        }
    }
}

enum BreathingPhase: String {
    case inhale = "Breathe In"
    case holdIn = "Hold In"
    case exhale = "Breathe Out"
    case holdOut = "Hold Out"
    case paused = "Paused"
    case idle = "Ready"
}
