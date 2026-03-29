import SwiftUI

struct SharedRitualsView: View {
    @StateObject private var accountabilityService = AccountabilityService.shared
    @State private var showingInviteSheet = false
    @State private var showingCreateRitualSheet = false
    @State private var selectedTab = 0
    @State private var inviteEmail = ""

    var body: some View {
        VStack(spacing: 0) {
            // Tab selector
            HStack(spacing: 0) {
                TabButton(title: "Partners", isSelected: selectedTab == 0) {
                    selectedTab = 0
                }
                TabButton(title: "Shared Rituals", isSelected: selectedTab == 1) {
                    selectedTab = 1
                }
                TabButton(title: "Family", isSelected: selectedTab == 2) {
                    selectedTab = 2
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            Divider()
                .background(Color(hex: "8B7355").opacity(0.3))
                .padding(.top, 12)

            ScrollView {
                VStack(spacing: 24) {
                    switch selectedTab {
                    case 0:
                        partnersTab
                    case 1:
                        sharedRitualsTab
                    case 2:
                        familyRitualsTab
                    default:
                        partnersTab
                    }
                }
                .padding(24)
            }
        }
        .background(Color(hex: "0D0B09"))
        .sheet(isPresented: $showingInviteSheet) {
            InvitePartnerSheet(email: $inviteEmail, onInvite: {
                accountabilityService.invitePartner(email: inviteEmail)
                inviteEmail = ""
                showingInviteSheet = false
            })
        }
        .sheet(isPresented: $showingCreateRitualSheet) {
            CreateSharedRitualSheet(onCreate: { title, type in
                _ = accountabilityService.createSharedRitual(title: title, type: type)
                showingCreateRitualSheet = false
            })
        }
    }

    // MARK: - Partners Tab

    private var partnersTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with invite button
            HStack {
                Text("Accountability Partners")
                    .font(.system(size: 20, weight: .light, design: .serif))
                    .foregroundColor(Color(hex: "F5F0E8"))

                Spacer()

                Button {
                    showingInviteSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .medium))
                        Text("Invite")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(Color(hex: "0D0B09"))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color(hex: "C9A96E"))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }

            if accountabilityService.partners.isEmpty {
                emptyPartnersView
            } else {
                ForEach(accountabilityService.partners) { partner in
                    PartnerCard(partner: partner)
                }
            }

            // Weekly summary
            if !accountabilityService.partners.isEmpty {
                weeklySummaryCard
            }
        }
    }

    private var emptyPartnersView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 40))
                .foregroundColor(Color(hex: "8B7355"))

            Text("No Partners Yet")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(Color(hex: "F5F0E8"))

            Text("Invite someone to hold you accountable on your ritual journey.")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "9C9285"))
                .multilineTextAlignment(.center)

            Button {
                showingInviteSheet = true
            } label: {
                Text("Invite a Partner")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "0D0B09"))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color(hex: "C9A96E"))
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color(hex: "1A1714"))
        .cornerRadius(16)
    }

    private var weeklySummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.doc.horizontal")
                    .foregroundColor(Color(hex: "C9A96E"))
                Text("Weekly Summary")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "F5F0E8"))
            }

            Text(accountabilityService.exportWeeklySummary())
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "9C9285"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(hex: "1A1714"))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "8B7355").opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Shared Rituals Tab

    private var sharedRitualsTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with create button
            HStack {
                Text("Shared Rituals")
                    .font(.system(size: 20, weight: .light, design: .serif))
                    .foregroundColor(Color(hex: "F5F0E8"))

                Spacer()

                Button {
                    showingCreateRitualSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .medium))
                        Text("Create")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(Color(hex: "0D0B09"))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color(hex: "C9A96E"))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }

            // Ritual type selector
            HStack(spacing: 12) {
                ForEach(SharedRitualType.allCases.filter { $0 != .familyBreathing }, id: \.self) { type in
                    RitualTypePill(type: type, isSelected: false) {
                        showingCreateRitualSheet = true
                    }
                }
            }

            if accountabilityService.sharedRituals.isEmpty {
                emptySharedRitualsView
            } else {
                ForEach(accountabilityService.sharedRituals) { ritual in
                    SharedRitualCard(ritual: ritual, onComplete: {
                        accountabilityService.completeRitual(ritual.id)
                    })
                }
            }
        }
    }

    private var emptySharedRitualsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.circle")
                .font(.system(size: 40))
                .foregroundColor(Color(hex: "8B7355"))

            Text("No Shared Rituals")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(Color(hex: "F5F0E8"))

            Text("Create a ritual to share with your accountability partner.")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "9C9285"))
                .multilineTextAlignment(.center)

            Button {
                showingCreateRitualSheet = true
            } label: {
                Text("Create Shared Ritual")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "0D0B09"))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color(hex: "C9A96E"))
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color(hex: "1A1714"))
        .cornerRadius(16)
    }

    // MARK: - Family Rituals Tab

    private var familyRitualsTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Family Rituals")
                    .font(.system(size: 20, weight: .light, design: .serif))
                    .foregroundColor(Color(hex: "F5F0E8"))

                Spacer()
            }

            Text("Create and track rituals for your household")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "9C9285"))

            // Family ritual templates
            VStack(spacing: 12) {
                FamilyRitualTemplate(
                    title: "Morning Family Breathing",
                    description: "Start the day together with a short breathing exercise",
                    icon: "sunrise.fill",
                    duration: "3 minutes"
                )

                FamilyRitualTemplate(
                    title: "Evening Wind-Down",
                    description: "End the day with gratitude sharing",
                    icon: "moon.stars.fill",
                    duration: "5 minutes"
                )

                FamilyRitualTemplate(
                    title: "Weekly Family Check-In",
                    description: "Sunday reflection on the week's intentions",
                    icon: "calendar",
                    duration: "15 minutes"
                )
            }

            // Family streak
            FamilyStreakCard()
        }
    }
}

// MARK: - Supporting Views

struct PartnerCard: View {
    let partner: AccountabilityPartner
    @ObservedObject var service = AccountabilityService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Avatar
                Circle()
                    .fill(Color(hex: "C9A96E").opacity(0.2))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(String(partner.displayName.prefix(1)).uppercased())
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Color(hex: "C9A96E"))
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(partner.displayName)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(hex: "F5F0E8"))

                    HStack(spacing: 4) {
                        Image(systemName: partner.relationship.icon)
                            .font(.system(size: 11))
                        Text(partner.relationship.rawValue)
                            .font(.system(size: 12))
                    }
                    .foregroundColor(Color(hex: "9C9285"))
                }

                Spacer()

                // Streak badge
                AccountabilityStreakBadge(streak: partner.currentStreak)
            }

            Divider()
                .background(Color(hex: "8B7355").opacity(0.2))

            HStack {
                // Today's status
                HStack(spacing: 6) {
                    Image(systemName: partner.todayCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 14))
                        .foregroundColor(partner.todayCompleted ? Color(hex: "7A9E7A") : Color(hex: "8B7355"))

                    Text(partner.todayCompleted ? "Completed today" : "Pending today")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "9C9285"))
                }

                Spacer()

                // Quick encouragement
                Button {
                    service.sendQuickEncouragement(to: partner)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "hand.wave.fill")
                            .font(.system(size: 11))
                        Text("Encourage")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(Color(hex: "C9A96E"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(hex: "C9A96E").opacity(0.15))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .disabled(partner.mutedMode)

                // Mute toggle
                Button {
                    service.toggleMutedMode(for: partner)
                } label: {
                    Image(systemName: partner.mutedMode ? "bell.slash.fill" : "bell.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "9C9285"))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(Color(hex: "1A1714"))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "8B7355").opacity(0.3), lineWidth: 1)
        )
    }
}

struct AccountabilityStreakBadge: View {
    let streak: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .font(.system(size: 12))
                .foregroundColor(streak > 0 ? Color(hex: "C4956A") : Color(hex: "5C544A"))

            Text("\(streak)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(streak > 0 ? Color(hex: "F5F0E8") : Color(hex: "5C544A"))

            Text("days")
                .font(.system(size: 11))
                .foregroundColor(Color(hex: "9C9285"))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(hex: "1A1714"))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(hex: "8B7355").opacity(streak > 0 ? 0.5 : 0.2), lineWidth: 1)
        )
    }
}

struct SharedRitualCard: View {
    let ritual: SharedRitual
    let onComplete: () -> Void
    @State private var isCompleted: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: ritual.ritualType.icon)
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: "C9A96E"))
                    .frame(width: 36, height: 36)
                    .background(Color(hex: "C9A96E").opacity(0.15))
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 2) {
                    Text(ritual.title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(hex: "F5F0E8"))

                    Text(ritual.ritualType.description)
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "9C9285"))
                }

                Spacer()

                if ritual.completedBy.count > 0 {
                    Text("\(ritual.completedBy.count)/\(ritual.participants.count + 1)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(hex: "7A9E7A"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: "7A9E7A").opacity(0.15))
                        .cornerRadius(6)
                }
            }

            if !ritual.participants.isEmpty {
                // Participants
                HStack(spacing: -8) {
                    ForEach(ritual.participants, id: \.self) { participant in
                        Circle()
                            .fill(Color(hex: "8B7355"))
                            .frame(width: 28, height: 28)
                            .overlay(
                                Text(String(participant.prefix(1)).uppercased())
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(Color(hex: "F5F0E8"))
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color(hex: "1A1714"), lineWidth: 2)
                            )
                    }
                }
            }

            Button {
                isCompleted = true
                onComplete()
            } label: {
                HStack {
                    Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 14))
                    Text(isCompleted ? "Completed" : "Mark as Done")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(isCompleted ? Color(hex: "7A9E7A") : Color(hex: "C9A96E"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isCompleted ? Color(hex: "7A9E7A").opacity(0.15) : Color(hex: "C9A96E").opacity(0.15))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .disabled(isCompleted)
        }
        .padding(16)
        .background(Color(hex: "1A1714"))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "8B7355").opacity(0.3), lineWidth: 1)
        )
    }
}

struct FamilyRitualTemplate: View {
    let title: String
    let description: String
    let icon: String
    let duration: String

    @State private var isStarted: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Color(hex: "C9A96E"))
                .frame(width: 44, height: 44)
                .background(Color(hex: "C9A96E").opacity(0.15))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "F5F0E8"))

                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "9C9285"))

                Text(duration)
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "8B7355"))
            }

            Spacer()

            Button {
                isStarted.toggle()
            } label: {
                Text(isStarted ? "Active" : "Start")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "0D0B09"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(isStarted ? Color(hex: "7A9E7A") : Color(hex: "C9A96E"))
                    .cornerRadius(6)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(Color(hex: "1A1714"))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "8B7355").opacity(0.3), lineWidth: 1)
        )
    }
}

struct FamilyStreakCard: View {
    // Placeholder family streak - in real app would come from service
    @State private var familyStreak = 7

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "figure.2.and.child.holdinghands")
                    .foregroundColor(Color(hex: "C9A96E"))
                Text("Family Consistency")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "F5F0E8"))

                Spacer()

                Text("We completed \(familyStreak) days in a row")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "7A9E7A"))
            }

            // Week dots
            HStack(spacing: 6) {
                ForEach(0..<7, id: \.self) { dayIndex in
                    VStack(spacing: 4) {
                        Circle()
                            .fill(dayIndex < familyStreak % 7 || familyStreak >= 7 ? Color(hex: "C9A96E") : Color(hex: "1A1714"))
                            .frame(width: 10, height: 10)
                            .overlay(
                                Circle()
                                    .stroke(Color(hex: "8B7355").opacity(0.5), lineWidth: 1)
                            )

                        Text(["M", "T", "W", "T", "F", "S", "S"][dayIndex])
                            .font(.system(size: 9))
                            .foregroundColor(Color(hex: "9C9285"))
                    }
                }
            }
        }
        .padding(16)
        .background(Color(hex: "1A1714"))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "8B7355").opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Supporting Components

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .medium : .regular))
                    .foregroundColor(isSelected ? Color(hex: "F5F0E8") : Color(hex: "9C9285"))

                Rectangle()
                    .fill(isSelected ? Color(hex: "C9A96E") : Color.clear)
                    .frame(height: 2)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
}

struct RitualTypePill: View {
    let type: SharedRitualType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: type.icon)
                    .font(.system(size: 11))
                Text(type.rawValue)
                    .font(.system(size: 12))
            }
            .foregroundColor(isSelected ? Color(hex: "0D0B09") : Color(hex: "9C9285"))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color(hex: "C9A96E") : Color(hex: "1A1714"))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(hex: "8B7355").opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Sheets

struct InvitePartnerSheet: View {
    @Binding var email: String
    let onInvite: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Text("Invite a Partner")
                .font(.system(size: 20, weight: .light, design: .serif))
                .foregroundColor(Color(hex: "F5F0E8"))

            VStack(alignment: .leading, spacing: 8) {
                Text("Email Address")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "9C9285"))

                TextField("partner@email.com", text: $email)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "F5F0E8"))
                    .padding(12)
                    .background(Color(hex: "1A1714"))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(hex: "8B7355").opacity(0.5), lineWidth: 1)
                    )
            }

            Button {
                onInvite()
            } label: {
                Text("Send Invitation")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "0D0B09"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(hex: "C9A96E"))
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .disabled(email.isEmpty)

            Button("Cancel") {
                dismiss()
            }
            .font(.system(size: 13))
            .foregroundColor(Color(hex: "9C9285"))
        }
        .padding(24)
        .background(Color(hex: "0D0B09"))
    }
}

struct CreateSharedRitualSheet: View {
    let onCreate: (String, SharedRitualType) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var selectedType: SharedRitualType = .synchronizedBreathing

    var body: some View {
        VStack(spacing: 24) {
            Text("Create Shared Ritual")
                .font(.system(size: 20, weight: .light, design: .serif))
                .foregroundColor(Color(hex: "F5F0E8"))

            VStack(alignment: .leading, spacing: 8) {
                Text("Ritual Name")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "9C9285"))

                TextField("Morning mindfulness with Sarah", text: $title)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "F5F0E8"))
                    .padding(12)
                    .background(Color(hex: "1A1714"))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(hex: "8B7355").opacity(0.5), lineWidth: 1)
                    )
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Ritual Type")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "9C9285"))

                ForEach(SharedRitualType.allCases.filter { $0 != .familyBreathing }, id: \.self) { type in
                    Button {
                        selectedType = type
                    } label: {
                        HStack {
                            Image(systemName: type.icon)
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "C9A96E"))
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(type.rawValue)
                                    .font(.system(size: 13, weight: .medium))
                                Text(type.description)
                                    .font(.system(size: 11))
                                    .foregroundColor(Color(hex: "9C9285"))
                            }

                            Spacer()

                            if selectedType == type {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color(hex: "C9A96E"))
                            }
                        }
                        .foregroundColor(Color(hex: "F5F0E8"))
                        .padding(12)
                        .background(Color(hex: "1A1714"))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(selectedType == type ? Color(hex: "C9A96E").opacity(0.5) : Color(hex: "8B7355").opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            Button {
                onCreate(title, selectedType)
            } label: {
                Text("Create Ritual")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "0D0B09"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(hex: "C9A96E"))
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .disabled(title.isEmpty)

            Button("Cancel") {
                dismiss()
            }
            .font(.system(size: 13))
            .foregroundColor(Color(hex: "9C9285"))
        }
        .padding(24)
        .background(Color(hex: "0D0B09"))
    }
}

#Preview {
    SharedRitualsView()
        .frame(width: 500, height: 700)
}
