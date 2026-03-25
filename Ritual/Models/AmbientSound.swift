import Foundation

enum AmbientSound: String, CaseIterable, Identifiable {
    case none = "None"
    case rain = "Rain"
    case forest = "Forest"
    case ocean = "Ocean"
    case fire = "Fire"
    case wind = "Wind"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .none: return "speaker.slash"
        case .rain: return "cloud.rain"
        case .forest: return "leaf"
        case .ocean: return "water.waves"
        case .fire: return "flame"
        case .wind: return "wind"
        }
    }

    var description: String {
        switch self {
        case .none: return "No sound"
        case .rain: return "Gentle rainfall"
        case .forest: return "Birds & rustling leaves"
        case .ocean: return "Waves on the shore"
        case .fire: return "Crackling fireplace"
        case .wind: return "Soft breeze"
        }
    }

    // Frequency data for synthesized ambient sounds (44000 Hz sample rate)
    // Each tuple is (baseFrequency, amplitude, modulation)
    var soundProfile: [(freq: Double, amp: Double, mod: Double)] {
        switch self {
        case .none:
            return []
        case .rain:
            // White noise + low-pass filtered noise
            return [(200, 0.15, 0), (400, 0.1, 0), (800, 0.05, 0)]
        case .forest:
            // Layered harmonic tones
            return [(220, 0.08, 0.3), (330, 0.06, 0.5), (440, 0.04, 0.7)]
        case .ocean:
            // Slow wave modulation
            return [(110, 0.12, 0.1), (165, 0.08, 0.15), (220, 0.05, 0.2)]
        case .fire:
            // Crackling mid-range noise
            return [(180, 0.10, 0), (360, 0.08, 0), (720, 0.06, 0)]
        case .wind:
            // Low rumbling with slow modulation
            return [(80, 0.10, 0.05), (160, 0.07, 0.1), (320, 0.04, 0.15)]
        }
    }
}
