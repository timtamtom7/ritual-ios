import SwiftUI

struct SettingsView: View {
    @StateObject private var subscriptionService = SubscriptionService.shared
    @State private var showExportSheet = false
    @State private var exportURL: URL?
    @State private var showPaywall = false
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.spacingL) {
                    // Subscription Section
                    subscriptionSection

                    // Data Section
                    dataSection

                    // About Section
                    aboutSection

                    // Danger Zone
                    dangerZone
                }
                .padding(Theme.spacingM)
            }
            .background(Theme.background)
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showExportSheet) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                }
            }
            .alert("Delete All Data", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    deleteAllData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all your intentions, check-ins, and breathing sessions. This action cannot be undone.")
            }
        }
    }

    // MARK: - Subscription Section

    private var subscriptionSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            sectionHeader("Subscription")

            VStack(spacing: Theme.spacingS) {
                // Current plan
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current Plan")
                            .font(.system(size: 13))
                            .foregroundColor(Theme.textMuted)

                        HStack(spacing: 6) {
                            Text(subscriptionService.currentTier.displayName)
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(Theme.textPrimary)

                            if subscriptionService.currentTier != .free {
                                Text(subscriptionService.isYearly ? "Yearly" : "Monthly")
                                    .font(.system(size: 12))
                                    .foregroundColor(Theme.goldPrimary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Theme.goldPrimary.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                    }

                    Spacer()

                    if subscriptionService.currentTier != .free {
                        if let exp = subscriptionService.expirationDate {
                            Text("Renews \(exp.formatted(date: .abbreviated, time: .omitted))")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.textMuted)
                        }
                    }
                }

                if subscriptionService.currentTier == .free {
                    Divider()
                        .background(Theme.goldMuted.opacity(0.3))

                    Button {
                        showPaywall = true
                    } label: {
                        Label("Upgrade to Pro", systemImage: "crown.fill")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color(hex: "0D0B09"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.spacingS)
                            .background(Theme.goldPrimary)
                            .cornerRadius(Theme.buttonRadius)
                    }

                    Button {
                        showPaywall = true
                    } label: {
                        Label("Become a Teacher", systemImage: "person.wave.2")
                            .font(.system(size: 15))
                            .foregroundColor(Theme.goldPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.spacingS)
                    }
                    .buttonStyle(.bordered)
                    .tint(Theme.goldPrimary)
                }
            }
            .padding(Theme.spacingM)
            .background(Theme.surface)
            .cornerRadius(Theme.cardRadius)
        }
    }

    // MARK: - Data Section

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            sectionHeader("Data")

            VStack(spacing: 0) {
                // Export Data
                Button {
                    exportData()
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(Theme.goldPrimary)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Export My Data")
                                .font(.system(size: 15))
                                .foregroundColor(Theme.textPrimary)
                            Text("Download all your ritual history as Markdown")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.textMuted)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(Theme.textMuted)
                    }
                    .padding(Theme.spacingM)
                }
                .disabled(subscriptionService.currentTier == .free)

                if subscriptionService.currentTier == .free {
                    Text("Pro or Teacher required")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.goldPrimary)
                        .padding(.horizontal, Theme.spacingM)
                        .padding(.bottom, Theme.spacingS)
                }

                Divider()
                    .background(Theme.goldMuted.opacity(0.2))

                // Notification Settings
                NavigationLink {
                    NotificationSettingsView()
                } label: {
                    HStack {
                        Image(systemName: "bell")
                            .foregroundColor(Theme.goldPrimary)
                            .frame(width: 24)

                        Text("Notifications")
                            .font(.system(size: 15))
                            .foregroundColor(Theme.textPrimary)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(Theme.textMuted)
                    }
                    .padding(Theme.spacingM)
                }
            }
            .background(Theme.surface)
            .cornerRadius(Theme.cardRadius)
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            sectionHeader("About")

            VStack(spacing: 0) {
                HStack {
                    Text("Version")
                        .font(.system(size: 15))
                        .foregroundColor(Theme.textPrimary)
                    Spacer()
                    Text("1.0.0")
                        .font(.system(size: 15))
                        .foregroundColor(Theme.textMuted)
                }
                .padding(Theme.spacingM)

                Divider()
                    .background(Theme.goldMuted.opacity(0.2))

                Button {
                    // Rate app
                } label: {
                    HStack {
                        Text("Rate Ritual")
                            .font(.system(size: 15))
                            .foregroundColor(Theme.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(Theme.textMuted)
                    }
                    .padding(Theme.spacingM)
                }

                Divider()
                    .background(Theme.goldMuted.opacity(0.2))

                Button {
                    // Contact support
                } label: {
                    HStack {
                        Text("Contact Support")
                            .font(.system(size: 15))
                            .foregroundColor(Theme.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(Theme.textMuted)
                    }
                    .padding(Theme.spacingM)
                }

                Divider()
                    .background(Theme.goldMuted.opacity(0.2))

                Button {
                    // Privacy policy
                } label: {
                    HStack {
                        Text("Privacy Policy")
                            .font(.system(size: 15))
                            .foregroundColor(Theme.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(Theme.textMuted)
                    }
                    .padding(Theme.spacingM)
                }
            }
            .background(Theme.surface)
            .cornerRadius(Theme.cardRadius)
        }
    }

    // MARK: - Danger Zone

    private var dangerZone: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            sectionHeader("Danger Zone")

            VStack(spacing: 0) {
                Button {
                    showDeleteConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .frame(width: 24)

                        Text("Delete All Data")
                            .font(.system(size: 15))
                            .foregroundColor(.red)

                        Spacer()
                    }
                    .padding(Theme.spacingM)
                }
            }
            .background(Theme.surface)
            .cornerRadius(Theme.cardRadius)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cardRadius)
                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
            )
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(Theme.textMuted)
            .textCase(.uppercase)
            .tracking(1)
    }

    private func exportData() {
        if let url = DataExportService.exportAllData() {
            exportURL = url
            showExportSheet = true
        }
    }

    private func deleteAllData() {
        // Would call DatabaseService to wipe all data
    }
}

// MARK: - Notification Settings

struct NotificationSettingsView: View {
    @State private var morningReminder = true
    @State private var eveningReminder = false
    @State private var streakReminder = true
    @State private var groupReminder = true

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.spacingL) {
                VStack(alignment: .leading, spacing: Theme.spacingS) {
                    Text("Reminders")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.textMuted)
                        .textCase(.uppercase)
                        .tracking(1)

                    VStack(spacing: 0) {
                        Toggle(isOn: $morningReminder) {
                            HStack {
                                Image(systemName: "sunrise")
                                    .foregroundColor(Theme.goldPrimary)
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Morning Reminder")
                                        .font(.system(size: 15))
                                    Text("Remind to set daily intention")
                                        .font(.system(size: 12))
                                        .foregroundColor(Theme.textMuted)
                                }
                            }
                        }
                        .tint(Theme.goldPrimary)
                        .padding(Theme.spacingM)

                        Divider().background(Theme.goldMuted.opacity(0.2))

                        Toggle(isOn: $eveningReminder) {
                            HStack {
                                Image(systemName: "sunset")
                                    .foregroundColor(Theme.goldPrimary)
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Evening Check-in")
                                        .font(.system(size: 15))
                                    Text("Remind to check in on intention")
                                        .font(.system(size: 12))
                                        .foregroundColor(Theme.textMuted)
                                }
                            }
                        }
                        .tint(Theme.goldPrimary)
                        .padding(Theme.spacingM)

                        Divider().background(Theme.goldMuted.opacity(0.2))

                        Toggle(isOn: $streakReminder) {
                            HStack {
                                Image(systemName: "flame")
                                    .foregroundColor(Theme.goldPrimary)
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Streak at Risk")
                                        .font(.system(size: 15))
                                    Text("Alert when streak might break")
                                        .font(.system(size: 12))
                                        .foregroundColor(Theme.textMuted)
                                }
                            }
                        }
                        .tint(Theme.goldPrimary)
                        .padding(Theme.spacingM)

                        Divider().background(Theme.goldMuted.opacity(0.2))

                        Toggle(isOn: $groupReminder) {
                            HStack {
                                Image(systemName: "person.3")
                                    .foregroundColor(Theme.goldPrimary)
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Group Sessions")
                                        .font(.system(size: 15))
                                    Text("Notify when group rituals start")
                                        .font(.system(size: 12))
                                        .foregroundColor(Theme.textMuted)
                                }
                            }
                        }
                        .tint(Theme.goldPrimary)
                        .padding(Theme.spacingM)
                    }
                    .background(Theme.surface)
                    .cornerRadius(Theme.cardRadius)
                }
            }
            .padding(Theme.spacingM)
        }
        .background(Theme.background)
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}
