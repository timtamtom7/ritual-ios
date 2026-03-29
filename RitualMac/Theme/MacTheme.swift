import SwiftUI

// MARK: - Theme for RitualMac (Dark, Ceremonial Aesthetic)
// Note: Uses Color.init(hex:) from Ritual/Theme/Theme.swift

enum MacTheme {
    // MARK: - Dark Palette Colors (Primary — matches SPEC.md & implementation)
    // Backgrounds
    static let darkBackground = Color(hex: "0D0B09")
    static let darkSurface    = Color(hex: "1A1714")

    // Gold Accent
    static let goldPrimary    = Color(hex: "C9A96E")
    static let goldMuted      = Color(hex: "8B7355")
    static let goldGlow       = Color(hex: "E8D5A3")

    // Text
    static let textPrimary    = Color(hex: "F5F0E8")
    static let textSecondary  = Color(hex: "9C9285")
    static let textMuted      = Color(hex: "5C544A")

    // Status
    static let success        = Color(hex: "7A9E7A")
    static let warning        = Color(hex: "C4956A")

    // MARK: - Legacy Light Palette (unused in current implementation)
    static let warmAmber = Color(hex: "D97706")
    static let deepBrown = Color(hex: "3D2C1E")
    static let cream = Color(hex: "FEF3C7")
    static let sage = Color(hex: "6B8E6B")
    static let surface = Color(hex: "FAF8F5")
    static let cardBg = Color(hex: "FFFFFF")

    // MARK: - Semantic Aliases (dark — primary mode)
    static let background     = darkBackground
    static let surfaceColor   = darkSurface
    static let accent        = goldPrimary
    static let border        = goldMuted

    // Text aliases (used throughout views)
    static let primaryText    = textPrimary
    static let secondaryText  = textSecondary
    static let mutedText      = textMuted

    // MARK: - Typography
    static let displayFont = Font.system(size: 32, weight: .light, design: .serif)
    static let titleFont = Font.system(size: 24, weight: .light, design: .serif)
    static let headingFont = Font.system(size: 18, weight: .medium, design: .serif)
    static let bodyFont = Font.system(size: 15, weight: .regular)
    static let captionFont = Font.system(size: 12, weight: .regular)

    // MARK: - Spacing
    static let spacingXS: CGFloat = 4
    static let spacingS: CGFloat = 8
    static let spacingM: CGFloat = 16
    static let spacingL: CGFloat = 24
    static let spacingXL: CGFloat = 32

    // MARK: - Corner Radius
    static let cardRadius: CGFloat = 16
    static let buttonRadius: CGFloat = 12
    static let smallRadius: CGFloat = 8

    // MARK: - Shadows
    static let cardShadow = darkBackground.opacity(0.08)

    // MARK: - Gradients
    static let amberGradient = LinearGradient(
        colors: [goldPrimary, goldMuted],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let warmGradient = LinearGradient(
        colors: [darkSurface, darkBackground],
        startPoint: .top,
        endPoint: .bottom
    )
}
