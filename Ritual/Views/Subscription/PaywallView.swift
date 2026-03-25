import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionService = SubscriptionService.shared
    @State private var selectedTier: SubscriptionTier = .pro
    @State private var isYearly = true
    @State private var isPurchasing = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    header

                    // Tier Selection
                    tierSelector

                    // Features
                    featuresSection

                    // Purchase Button
                    purchaseButton

                    // Restore & Terms
                    footerLinks
                }
                .padding(Theme.spacingM)
            }
            .background(Theme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Theme.textMuted)
                            .font(.system(size: 24))
                    }
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: Theme.spacingS) {
            Image(systemName: "crown.fill")
                .font(.system(size: 48))
                .foregroundColor(Theme.goldPrimary)

            Text("Upgrade Your Ritual")
                .font(.system(size: 28, weight: .light, design: .serif))
                .foregroundColor(Theme.textPrimary)

            Text("Unlock the full practice with Pro or Teacher plans")
                .font(.system(size: 15))
                .foregroundColor(Theme.textMuted)
                .multilineTextAlignment(.center)
        }
        .padding(.top, Theme.spacingL)
    }

    private var tierSelector: some View {
        VStack(spacing: Theme.spacingS) {
            // Yearly toggle
            HStack {
                Text("Yearly")
                    .font(.system(size: 15, weight: selectedTier == .pro ? .medium : .regular))
                    .foregroundColor(isYearly ? Theme.textPrimary : Theme.textMuted)

                Toggle("", isOn: $isYearly)
                    .labelsHidden()
                    .tint(Theme.goldPrimary)

                Text("Monthly")
                    .font(.system(size: 15, weight: !isYearly ? .medium : .regular))
                    .foregroundColor(!isYearly ? Theme.textPrimary : Theme.textMuted)

                Spacer()

                if isYearly, let savings = selectedTier.yearlySavings {
                    Text(savings)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.success)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.success.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding(Theme.spacingM)
            .background(Theme.surface)
            .cornerRadius(Theme.cardRadius)

            // Tier cards
            VStack(spacing: Theme.spacingS) {
                ForEach([SubscriptionTier.pro, .teacher], id: \.self) { tier in
                    TierCard(
                        tier: tier,
                        isYearly: isYearly,
                        isSelected: selectedTier == tier,
                        onSelect: { selectedTier = tier }
                    )
                }
            }
        }
    }

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            Text("Everything in \(selectedTier.displayName)")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Theme.textMuted)
                .textCase(.uppercase)
                .tracking(1)

            VStack(spacing: Theme.spacingXS) {
                ForEach(selectedTier.features, id: \.self) { feature in
                    HStack(spacing: Theme.spacingS) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Theme.success)

                        Text(feature)
                            .font(.system(size: 15))
                            .foregroundColor(Theme.textPrimary)

                        Spacer()
                    }
                }
            }
            .padding(Theme.spacingM)
            .background(Theme.surface)
            .cornerRadius(Theme.cardRadius)
        }
    }

    private var purchaseButton: some View {
        VStack(spacing: Theme.spacingS) {
            Button {
                purchase()
            } label: {
                if isPurchasing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "0D0B09")))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.spacingM)
                        .background(Theme.goldPrimary)
                        .cornerRadius(Theme.buttonRadius)
                } else {
                    Text("Continue")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color(hex: "0D0B09"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.spacingM)
                        .background(Theme.goldPrimary)
                        .cornerRadius(Theme.buttonRadius)
                }
            }
            .disabled(isPurchasing)

            Text("Auto-renews until cancelled")
                .font(.system(size: 12))
                .foregroundColor(Theme.textMuted)

            // Apple subscription notice
            Text("Subscriptions automatically renew unless cancelled at least 24 hours before the end of the current period. Manage your subscription in your Apple account settings.")
                .font(.system(size: 11))
                .foregroundColor(Theme.textMuted)
                .multilineTextAlignment(.center)
        }
    }

    private var footerLinks: some View {
        HStack(spacing: Theme.spacingM) {
            Button {
                Task {
                    _ = await subscriptionService.restorePurchases()
                }
            } label: {
                Text("Restore Purchases")
                    .font(.system(size: 13))
                    .foregroundColor(Theme.goldPrimary)
            }

            Spacer()

            Button {
                // Show terms
            } label: {
                Text("Terms")
                    .font(.system(size: 13))
                    .foregroundColor(Theme.textMuted)
            }

            Button {
                // Show privacy
            } label: {
                Text("Privacy")
                    .font(.system(size: 13))
                    .foregroundColor(Theme.textMuted)
            }
        }
        .padding(.horizontal, Theme.spacingM)
    }

    private func purchase() {
        isPurchasing = true
        Task {
            let success = await subscriptionService.purchase(selectedTier, yearly: isYearly)
            await MainActor.run {
                isPurchasing = false
                if success {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Tier Card

struct TierCard: View {
    let tier: SubscriptionTier
    let isYearly: Bool
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(tier.displayName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)

                    Text(isYearly ? tier.yearlyPrice : tier.monthlyPrice)
                        .font(.system(size: 15, weight: .light, design: .serif))
                        .foregroundColor(Theme.goldPrimary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Theme.goldPrimary)
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 22))
                        .foregroundColor(Theme.textMuted)
                }
            }
            .padding(Theme.spacingM)
            .background(isSelected ? Theme.goldPrimary.opacity(0.1) : Theme.surface)
            .cornerRadius(Theme.cardRadius)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cardRadius)
                    .stroke(isSelected ? Theme.goldPrimary.opacity(0.5) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
