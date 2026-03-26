import Foundation
import SwiftUI

/// R15: Internationalization for Ritual
/// Full i18n with wellness terminology
@MainActor
final class LocalizationService: ObservableObject {
    static let shared = LocalizationService()

    @Published var currentLanguage: AppLanguage = .english

    enum AppLanguage: String, CaseIterable, Codable, Identifiable {
        case english = "en"
        case german = "de"
        case french = "fr"
        case spanish = "es"
        case italian = "it"
        case portuguese = "pt"
        case japanese = "ja"
        case korean = "ko"
        case simplifiedChinese = "zh-Hans"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .english: return "English"
            case .german: return "Deutsch"
            case .french: return "Français"
            case .spanish: return "Español"
            case .italian: return "Italiano"
            case .portuguese: return "Português"
            case .japanese: return "日本語"
            case .korean: return "한국어"
            case .simplifiedChinese: return "简体中文"
            }
        }

        var flag: String {
            switch self {
            case .english: return "🇺🇸"
            case .german: return "🇩🇪"
            case .french: return "🇫🇷"
            case .spanish: return "🇪🇸"
            case .italian: return "🇮🇹"
            case .portuguese: return "🇵🇹"
            case .japanese: return "🇯🇵"
            case .korean: return "🇰🇷"
            case .simplifiedChinese: return "🇨🇳"
            }
        }
    }

    private let languageKey = "ritual_language"

    init() {
        loadLanguage()
    }

    func loadLanguage() {
        if let saved = UserDefaults.standard.string(forKey: languageKey),
           let lang = AppLanguage(rawValue: saved) {
            currentLanguage = lang
        } else if let systemLang = Locale.current.language.languageCode?.identifier {
            currentLanguage = AppLanguage(rawValue: systemLang) ?? .english
        }
    }

    func setLanguage(_ language: AppLanguage) {
        currentLanguage = language
        UserDefaults.standard.set(language.rawValue, forKey: languageKey)
    }

    func t(_ key: String) -> String {
        currentLanguage.translations[key] ?? key
    }
}

extension LocalizationService.AppLanguage {
    var translations: [String: String] {
        switch self {
        case .english:
            return Self.englishStrings
        case .german:
            return Self.germanStrings
        case .french:
            return Self.frenchStrings
        case .spanish:
            return Self.spanishStrings
        case .italian:
            return Self.italianStrings
        case .portuguese:
            return Self.portugueseStrings
        case .japanese:
            return Self.japaneseStrings
        case .korean:
            return Self.koreanStrings
        case .simplifiedChinese:
            return Self.chineseStrings
        }
    }

    private static let englishStrings: [String: String] = [
        "today": "Today",
        "breathing": "Breathing",
        "insights": "Insights",
        "community": "Community",
        "settings": "Settings",
        "intention": "Intention",
        "session": "Session",
        "insight": "Insight",
        "breathe": "Breathe",
        "ritual": "Ritual"
    ]

    private static let germanStrings: [String: String] = [
        "today": "Heute",
        "breathing": "Atmen",
        "insights": "Erkenntnisse",
        "community": "Gemeinschaft",
        "settings": "Einstellungen",
        "intention": "Absicht",
        "session": "Sitzung",
        "insight": "Erkenntnis",
        "breathe": "Atmen",
        "ritual": "Ritual"
    ]

    private static let frenchStrings: [String: String] = [
        "today": "Aujourd'hui",
        "breathing": "Respiration",
        "insights": "Aperçus",
        "community": "Communauté",
        "settings": "Paramètres",
        "intention": "Intention",
        "session": "Session",
        "insight": "Aperçu",
        "breathe": "Respirer",
        "ritual": "Rituel"
    ]

    private static let spanishStrings: [String: String] = [
        "today": "Hoy",
        "breathing": "Respiración",
        "insights": "Perspectivas",
        "community": "Comunidad",
        "settings": "Configuración",
        "intention": "Intención",
        "session": "Sesión",
        "insight": "Perspectiva",
        "breathe": "Respirar",
        "ritual": "Ritual"
    ]

    private static let italianStrings: [String: String] = [
        "today": "Oggi",
        "breathing": "Respirazione",
        "insights": "Approfondimenti",
        "community": "Comunità",
        "settings": "Impostazioni",
        "intention": "Intenzione",
        "session": "Sessione",
        "insight": "Approfondimento",
        "breathe": "Respirare",
        "ritual": "Rituale"
    ]

    private static let portugueseStrings: [String: String] = [
        "today": "Hoje",
        "breathing": "Respiração",
        "insights": "Insights",
        "community": "Comunidade",
        "settings": "Configurações",
        "intention": "Intenção",
        "session": "Sessão",
        "insight": "Insight",
        "breathe": "Respirar",
        "ritual": "Ritual"
    ]

    private static let japaneseStrings: [String: String] = [
        "today": "今日",
        "breathing": "呼吸",
        "insights": "洞察",
        "community": "コミュニティ",
        "settings": "設定",
        "intention": "意図",
        "session": "セッション",
        "insight": "洞察",
        "breathe": "呼吸",
        "ritual": "儀式"
    ]

    private static let koreanStrings: [String: String] = [
        "today": "오늘",
        "breathing": "호흡",
        "insights": "통찰",
        "community": "커뮤니티",
        "settings": "설정",
        "intention": "의도",
        "session": "세션",
        "insight": "통찰",
        "breathe": "호흡",
        "ritual": "의식"
    ]

    private static let chineseStrings: [String: String] = [
        "today": "今天",
        "breathing": "呼吸",
        "insights": "洞察",
        "community": "社区",
        "settings": "设置",
        "intention": "意图",
        "session": "会议",
        "insight": "洞察",
        "breathe": "呼吸",
        "ritual": "仪式"
    ]
}
