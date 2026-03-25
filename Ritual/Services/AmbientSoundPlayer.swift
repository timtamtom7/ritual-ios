import Foundation
import AVFoundation
import Accelerate

final class AmbientSoundPlayer: @unchecked Sendable {
    static let shared = AmbientSoundPlayer()

    private var audioEngine: AVAudioEngine?
    private var sourceNode: AVAudioSourceNode?
    private var currentSound: AmbientSound = .none
    private var isPlaying: Bool = false

    // Phase accumulator for modulation
    private var phase: Double = 0
    private let sampleRate: Double = 44100
    private let lock = NSLock()

    private init() {
        setupAudioSession()
    }

    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("Audio session setup error: \(error)")
        }
    }

    func play(sound: AmbientSound) {
        stop()

        guard sound != .none else { return }

        currentSound = sound
        isPlaying = true

        audioEngine = AVAudioEngine()
        guard let engine = audioEngine else { return }

        let outputFormat = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
        let bufferSize: AVAudioFrameCount = 1024

        sourceNode = AVAudioSourceNode(format: outputFormat) { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self = self else { return noErr }

            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)

            for frame in 0..<Int(frameCount) {
                let sample = self.generateSample()
                let monoSample = Float(sample)

                for buffer in ablPointer {
                    let buf: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(buffer)
                    buf[frame] = monoSample
                }
            }

            return noErr
        }

        guard let source = sourceNode else { return }
        engine.attach(source)
        engine.connect(source, to: engine.mainMixerNode, format: outputFormat)

        // Add reverb for ambient feel
        let reverb = AVAudioUnitReverb()
        reverb.loadFactoryPreset(.mediumHall)
        reverb.wetDryMix = 30
        engine.attach(reverb)
        engine.connect(engine.mainMixerNode, to: reverb, format: outputFormat)
        engine.connect(reverb, to: engine.outputNode, format: outputFormat)

        do {
            try engine.start()
        } catch {
            print("Audio engine start error: \(error)")
            isPlaying = false
        }
    }

    private func generateSample() -> Double {
        phase += 1.0 / sampleRate

        let profile = currentSound.soundProfile
        guard !profile.isEmpty else { return 0 }

        var sample: Double = 0

        for (index, component) in profile.enumerated() {
            let modulatedPhase = phase * (1.0 + component.mod * sin(phase * 0.5 + Double(index)))
            let value = sin(2.0 * .pi * component.freq * modulatedPhase) * component.amp

            // Add subtle noise component based on sound type
            let noise: Double
            switch currentSound {
            case .rain:
                noise = Double.random(in: -0.03...0.03)
            case .fire:
                noise = Double.random(in: -0.02...0.02) * (0.5 + 0.5 * sin(phase * 20))
            case .ocean:
                noise = Double.random(in: -0.02...0.02) * (0.5 + 0.5 * sin(phase * 0.3))
            case .wind:
                noise = Double.random(in: -0.015...0.015) * (0.5 + 0.5 * sin(phase * 0.8))
            case .forest:
                noise = Double.random(in: -0.01...0.01)
            default:
                noise = Double.random(in: -0.01...0.01)
            }

            sample += value + noise
        }

        // Normalize
        sample = sample / Double(max(1, profile.count))

        // Apply slow amplitude modulation for natural feel
        let ampMod = 0.85 + 0.15 * sin(phase * 0.2)
        sample *= ampMod

        return sample * 0.6 // Master volume
    }

    func stop() {
        isPlaying = false
        audioEngine?.stop()
        sourceNode = nil
        audioEngine = nil
        phase = 0
    }

    func fadeOut(duration: TimeInterval = 1.0) {
        // Simple fade out by scheduling stop
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.stop()
        }
    }
}
