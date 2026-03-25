import SwiftUI

struct InsightCard: View {
    let insight: CategoryInsight

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            HStack(spacing: Theme.spacingS) {
                Image(systemName: insight.icon)
                    .font(.system(size: 20))
                    .foregroundColor(Theme.goldPrimary)
                    .frame(width: 40, height: 40)
                    .background(Theme.goldPrimary.opacity(0.1))
                    .cornerRadius(10)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(Int(insight.successRate))%")
                        .font(.system(size: 28, weight: .light, design: .serif))
                        .foregroundColor(Theme.textPrimary)
                }

                Spacer()

                if insight.isStrongest {
                    Image(systemName: "star.fill")
                        .foregroundColor(Theme.goldPrimary)
                        .font(.system(size: 16))
                } else if insight.isWeakest {
                    Image(systemName: "leaf.fill")
                        .foregroundColor(Theme.success)
                        .font(.system(size: 16))
                }
            }

            Text(insight.headline)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text(insight.subtext)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if !insight.trend.isEmpty {
                Text(insight.trend)
                    .font(.system(size: 13, weight: .regular, design: .serif))
                    .foregroundColor(Theme.goldMuted)
                    .italic()
            }
        }
        .padding(Theme.spacingM)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface)
        .cornerRadius(Theme.cardRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius)
                .stroke(Theme.goldMuted.opacity(0.3), lineWidth: 1)
        )
    }
}
