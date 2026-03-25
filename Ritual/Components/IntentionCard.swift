import SwiftUI

struct IntentionCard: View {
    let intention: Intention
    var isHighlighted: Bool = false
    var showCategory: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            if showCategory, let category = intention.category {
                HStack(spacing: 6) {
                    Image(systemName: IntentionCategory(rawValue: category)?.icon ?? "sparkle")
                        .font(.system(size: 12))
                    Text(category)
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(Theme.goldMuted)
            }

            Text(intention.text)
                .font(.system(size: 20, weight: .regular, design: .serif))
                .foregroundColor(Theme.textPrimary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Theme.spacingM)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface)
        .cornerRadius(Theme.cardRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius)
                .stroke(
                    isHighlighted ? Theme.goldPrimary : Theme.goldMuted.opacity(0.3),
                    lineWidth: isHighlighted ? 2 : 1
                )
        )
        .shadow(color: isHighlighted ? Theme.goldPrimary.opacity(0.1) : .clear, radius: 8, x: 0, y: 4)
    }
}
