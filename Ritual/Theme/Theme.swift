import SwiftUI

enum Theme {
    // MARK: - Colors
    static let background = Color(hex: "0D0B09")
    static let surface = Color(hex: "1A1714")
    static let goldPrimary = Color(hex: "C9A96E")
    static let goldMuted = Color(hex: "8B7355")
    static let goldGlow = Color(hex: "E8D5A3")
    static let textPrimary = Color(hex: "F5F0E8")
    static let textSecondary = Color(hex: "9C9285")
    static let textMuted = Color(hex: "5C544A")
    static let success = Color(hex: "7A9E7A")
    static let warning = Color(hex: "C4956A")

    // MARK: - Typography
    static let displayFont = SwiftUI.Font.custom("NewYork-Regular", size: 48, relativeTo: .largeTitle)
    static let titleFont = SwiftUI.Font.custom("NewYork-Regular", size: 28, relativeTo: .title)
    static let headingFont = SwiftUI.Font.system(size: 20, weight: .medium, design: .serif)
    static let bodyFont = SwiftUI.Font.system(size: 17, weight: .regular)
    static let captionFont = SwiftUI.Font.system(size: 13, weight: .regular)

    // MARK: - Spacing
    static let spacingXS: CGFloat = 8
    static let spacingS: CGFloat = 16
    static let spacingM: CGFloat = 24
    static let spacingL: CGFloat = 32
    static let spacingXL: CGFloat = 48

    // MARK: - Corner Radius
    static let cardRadius: CGFloat = 16
    static let buttonRadius: CGFloat = 12
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
