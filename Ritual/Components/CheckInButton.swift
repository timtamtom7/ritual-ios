import SwiftUI

struct CheckInButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticFeedback.impact(.light)
            action()
        }) {
            Text(title)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(isSelected ? Theme.background : Theme.goldPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(isSelected ? Theme.goldPrimary : Color.clear)
                .cornerRadius(Theme.buttonRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.buttonRadius)
                        .stroke(Theme.goldPrimary, lineWidth: isSelected ? 0 : 1)
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var isEnabled: Bool = true

    var body: some View {
        Button(action: {
            HapticFeedback.impact(.medium)
            action()
        }) {
            Text(title)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(Theme.background)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(isEnabled ? Theme.goldPrimary : Theme.textMuted)
                .cornerRadius(Theme.buttonRadius)
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(!isEnabled)
    }
}
