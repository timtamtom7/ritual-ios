import SwiftUI

// MARK: - Warm Theme for RitualMac (Light, Intentional Living Aesthetic)
// Note: Uses Color.init(hex:) from Ritual/Theme/Theme.swift

enum MacTheme {
    // MARK: - Colors (Warm, Light)
    static let warmAmber = Color(hex: "D97706")
    static let deepBrown = Color(hex: "3D2C1E")
    static let cream = Color(hex: "FEF3C7")
    static let sage = Color(hex: "6B8E6B")
    static let surface = Color(hex: "FAF8F5")
    static let cardBg = Color(hex: "FFFFFF")
    
    // MARK: - Semantic Colors
    static let background = cream
    static let primaryText = deepBrown
    static let secondaryText = Color(hex: "7A6452")
    static let mutedText = Color(hex: "A39380")
    static let success = sage
    static let accent = warmAmber
    
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
    static let cardShadow = Color(hex: "3D2C1E").opacity(0.08)
    
    // MARK: - Gradients
    static let amberGradient = LinearGradient(
        colors: [warmAmber, Color(hex: "B45309")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let warmGradient = LinearGradient(
        colors: [Color(hex: "FEF3C7"), Color(hex: "FDE68A").opacity(0.5)],
        startPoint: .top,
        endPoint: .bottom
    )
}
