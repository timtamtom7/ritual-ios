import Foundation
import CoreHaptics
import Combine

@MainActor
final class BreathingService: ObservableObject {
    static let shared = BreathingService()

    private var engine: CHHapticEngine?
    private var player: CHHapticAdvancedPatternPlayer?

    @Published var currentPhase: BreathingPhase = .idle
    @Published var isRunning: Bool = false
    @Published var isPaused: Bool = false

    private var phaseTimer: Timer?
    private var currentPattern: BreathingPattern = .box
    private var hapticEnabled: Bool = true

    var onPhaseChanged: ((BreathingPhase) -> Void)?

    private init() {
        setupEngine()
    }

    private func setupEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            engine?.playsHapticsOnly = true
            engine?.stoppedHandler = { [weak self] reason in
                DispatchQueue.main.async {
                    self?.isRunning = false
                }
            }
            engine?.resetHandler = { [weak self] in
                try? self?.engine?.start()
            }
        } catch {
            print("Haptic engine creation error: \(error)")
        }
    }

    func startSession(pattern: BreathingPattern, durationMinutes: Int, hapticEnabled: Bool = true) {
        self.currentPattern = pattern
        self.hapticEnabled = hapticEnabled
        self.isRunning = true
        self.isPaused = false

        try? engine?.start()

        let phases = pattern.phases
        var delay: TimeInterval = 0

        for (index, phase) in phases.enumerated() {
            let nextPhase: BreathingPhase
            switch phase.name {
            case "Breathe In": nextPhase = .inhale
            case "Hold": nextPhase = index == 1 ? .holdIn : .holdOut
            case "Breathe Out": nextPhase = .exhale
            default: nextPhase = .idle
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard self?.isRunning == true, self?.isPaused == false else { return }
                self?.currentPhase = nextPhase
                self?.onPhaseChanged?(nextPhase)
                if self?.hapticEnabled == true {
                    self?.playHaptic(for: nextPhase, duration: phase.duration)
                }
            }

            delay += phase.duration
        }

        // Schedule loop
        phaseTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: true) { [weak self] _ in
            guard let self = self, self.isRunning, !self.isPaused else { return }
            self.startPhaseLoop()
        }

        // Auto-stop after duration
        let totalDuration = TimeInterval(durationMinutes * 60)
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) { [weak self] in
            self?.stopSession()
        }
    }

    private func startPhaseLoop() {
        let phases = currentPattern.phases
        var delay: TimeInterval = 0

        for (index, phase) in phases.enumerated() {
            let nextPhase: BreathingPhase
            switch phase.name {
            case "Breathe In": nextPhase = .inhale
            case "Hold": nextPhase = index == 1 ? .holdIn : .holdOut
            case "Breathe Out": nextPhase = .exhale
            default: nextPhase = .idle
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard self?.isRunning == true, self?.isPaused == false else { return }
                self?.currentPhase = nextPhase
                self?.onPhaseChanged?(nextPhase)
                if self?.hapticEnabled == true {
                    self?.playHaptic(for: nextPhase, duration: phase.duration)
                }
            }

            delay += phase.duration
        }
    }

    func pauseSession() {
        isPaused = true
        currentPhase = .paused
        stopHaptic()
    }

    func resumeSession() {
        isPaused = false
        startPhaseLoop()
    }

    func stopSession() {
        isRunning = false
        isPaused = false
        currentPhase = .idle
        phaseTimer?.invalidate()
        phaseTimer = nil
        stopHaptic()
    }

    private func playHaptic(for phase: BreathingPhase, duration: Double) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics, let engine = engine else { return }

        var events: [CHHapticEvent] = []

        switch phase {
        case .inhale:
            // Gentle increasing pulses
            let pulseCount = 3
            let interval = duration / Double(pulseCount)
            for i in 0..<pulseCount {
                let intensity = Float(0.3 + 0.4 * Double(i) / Double(pulseCount - 1))
                let sharpness = Float(0.2 + 0.3 * Double(i) / Double(pulseCount - 1))
                let event = CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
                    ],
                    relativeTime: interval * Double(i)
                )
                events.append(event)
            }

        case .exhale:
            // Decreasing pulses
            let pulseCount = 3
            let interval = duration / Double(pulseCount)
            for i in 0..<pulseCount {
                let intensity = Float(0.7 - 0.4 * Double(i) / Double(pulseCount - 1))
                let sharpness = Float(0.5 - 0.3 * Double(i) / Double(pulseCount - 1))
                let event = CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
                    ],
                    relativeTime: interval * Double(i)
                )
                events.append(event)
            }

        case .holdIn, .holdOut:
            // Single sustained soft pulse
            let event = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1)
                ],
                relativeTime: 0,
                duration: duration
            )
            events.append(event)

        default:
            break
        }

        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            player = try engine.makeAdvancedPlayer(with: pattern)
            try player?.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("Haptic playback error: \(error)")
        }
    }

    private func stopHaptic() {
        try? player?.stop(atTime: CHHapticTimeImmediate)
        player = nil
    }
}
