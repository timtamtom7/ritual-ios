import SwiftUI

struct GroupRitualView: View {
    @StateObject private var groupService = GroupBreathingService.shared
    @StateObject private var teacherService = TeacherService.shared
    @State private var showHostSheet = false
    @State private var showJoinSheet = false
    @State private var showTeacherSetup = false
    @State private var activeSheet: ActiveSheet?

    enum ActiveSheet: Identifiable {
        case host, join, teacherSetup, groupBreathing

        var id: Int {
            switch self {
            case .host: return 0
            case .join: return 1
            case .teacherSetup: return 2
            case .groupBreathing: return 3
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.spacingL) {
                    // Teacher Mode Section
                    teacherSection

                    // Community Streaks
                    communityStreaksSection

                    // Group Breathing Section
                    groupBreathingSection
                }
                .padding(.horizontal, Theme.spacingM)
                .padding(.vertical, Theme.spacingS)
            }
            .background(Theme.background)
            .navigationTitle("Community")
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .host:
                    HostSessionView()
                case .join:
                    JoinSessionView()
                case .teacherSetup:
                    TeacherSetupView()
                case .groupBreathing:
                    if let session = groupService.session {
                        GroupBreathingView(session: session)
                    }
                }
            }
        }
    }

    // MARK: - Teacher Section

    private var teacherSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            sectionHeader("Teacher Mode", icon: "person.wave.2.fill", subtitle: "Share your ritual templates with others")

            if teacherService.isTeacher {
                teacherDashboard
            } else {
                becomeTeacherCard
            }
        }
    }

    private var teacherDashboard: some View {
        VStack(spacing: Theme.spacingS) {
            // Profile card
            if let profile = teacherService.profile {
                HStack(spacing: Theme.spacingM) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(Theme.goldPrimary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(profile.displayName)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(Theme.textPrimary)
                        Text("\(profile.followerCount) followers • \(profile.totalRitualsHosted) rituals hosted")
                            .font(.system(size: 13))
                            .foregroundColor(Theme.textMuted)
                    }

                    Spacer()

                    Button {
                        showTeacherSetup = true
                        activeSheet = .teacherSetup
                    } label: {
                        Image(systemName: "pencil")
                            .foregroundColor(Theme.goldPrimary)
                    }
                }
                .padding(Theme.spacingM)
                .background(Theme.surface)
                .cornerRadius(Theme.cardRadius)
            }

            // Shared templates
            if !teacherService.sharedTemplates.isEmpty {
                VStack(alignment: .leading, spacing: Theme.spacingXS) {
                    Text("My Templates")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.textMuted)

                    ForEach(teacherService.sharedTemplates) { template in
                        SharedTemplateCard(template: template)
                    }
                }
            }

            // Share current template button
            Button {
                showTeacherSetup = true
                activeSheet = .teacherSetup
            } label: {
                Label("Share a Template", systemImage: "plus.circle")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Theme.goldPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.spacingS)
            }
            .buttonStyle(.bordered)
            .tint(Theme.goldPrimary)
        }
    }

    private var becomeTeacherCard: some View {
        VStack(spacing: Theme.spacingM) {
            Image(systemName: "person.wave.2")
                .font(.system(size: 40))
                .foregroundColor(Theme.goldPrimary)

            Text("Become a Teacher")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(Theme.textPrimary)

            Text("Share your ritual templates with the community. Help others build better habits.")
                .font(.system(size: 14))
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                showTeacherSetup = true
                activeSheet = .teacherSetup
            } label: {
                Text("Set Up Teacher Profile")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(hex: "0D0B09"))
                    .padding(.horizontal, Theme.spacingL)
                    .padding(.vertical, Theme.spacingS)
                    .background(Theme.goldPrimary)
                    .cornerRadius(Theme.buttonRadius)
            }
        }
        .padding(Theme.spacingL)
        .frame(maxWidth: .infinity)
        .background(Theme.surface)
        .cornerRadius(Theme.cardRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius)
                .stroke(Theme.goldPrimary.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Community Streaks Section

    private var communityStreaksSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            sectionHeader("Community Streaks", icon: "flame.fill", subtitle: "Group momentum across shared rituals")

            ForEach(teacherService.communityGroups) { group in
                CommunityStreakCard(group: group)
            }
        }
    }

    // MARK: - Group Breathing Section

    private var groupBreathingSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            sectionHeader("Group Breathing", icon: "person.3.fill", subtitle: "Synchronized breath with others nearby")

            if groupService.session != nil {
                activeSessionCard
            } else {
                groupSessionActions
            }
        }
    }

    private var activeSessionCard: some View {
        VStack(spacing: Theme.spacingM) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(groupService.session?.title ?? "Group Session")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(Theme.textPrimary)

                    Text("\(groupService.participants.count) participant\(groupService.participants.count == 1 ? "" : "s")")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.textMuted)
                }

                Spacer()

                Circle()
                    .fill(Theme.success)
                    .frame(width: 10, height: 10)

                Text("Live")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Theme.success)
            }

            HStack(spacing: Theme.spacingM) {
                Button {
                    activeSheet = .groupBreathing
                } label: {
                    Label("Open Session", systemImage: "arrow.right.circle.fill")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(hex: "0D0B09"))
                        .padding(.horizontal, Theme.spacingM)
                        .padding(.vertical, Theme.spacingS)
                        .background(Theme.goldPrimary)
                        .cornerRadius(Theme.buttonRadius)
                }

                Button {
                    groupService.leaveSession()
                } label: {
                    Label("Leave", systemImage: "xmark.circle")
                        .font(.system(size: 15))
                        .foregroundColor(Theme.warning)
                }
                .buttonStyle(.bordered)
                .tint(Theme.warning)
            }
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(Theme.cardRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius)
                .stroke(Theme.goldPrimary.opacity(0.3), lineWidth: 1)
        )
    }

    private var groupSessionActions: some View {
        HStack(spacing: Theme.spacingM) {
            Button {
                activeSheet = .host
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "dot.radiowaves.left.and.right")
                        .font(.system(size: 28))
                    Text("Host")
                        .font(.system(size: 13, weight: .medium))
                    Text("Start a session")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.spacingM)
                .foregroundColor(Theme.goldPrimary)
                .background(Theme.surface)
                .cornerRadius(Theme.cardRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cardRadius)
                        .stroke(Theme.goldPrimary.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            Button {
                activeSheet = .join
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 28))
                    Text("Join")
                        .font(.system(size: 13, weight: .medium))
                    Text("Find nearby")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.spacingM)
                .foregroundColor(Theme.goldPrimary)
                .background(Theme.surface)
                .cornerRadius(Theme.cardRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cardRadius)
                        .stroke(Theme.goldPrimary.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String, icon: String, subtitle: String) -> some View {
        HStack(spacing: Theme.spacingS) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(Theme.goldPrimary)

            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textMuted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Shared Template Card

struct SharedTemplateCard: View {
    let template: SharedTemplate
    @StateObject private var teacherService = TeacherService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingXS) {
            HStack {
                Text(template.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Theme.textPrimary)

                Spacer()

                HStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                    Text(String(format: "%.1f", template.rating))
                        .font(.system(size: 12))
                }
                .foregroundColor(Theme.goldPrimary)
            }

            Text("by \(template.creatorName)")
                .font(.system(size: 12))
                .foregroundColor(Theme.textMuted)

            Text(template.description)
                .font(.system(size: 13))
                .foregroundColor(Theme.textSecondary)
                .lineLimit(2)

            HStack {
                Text(template.category)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Theme.goldPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Theme.goldPrimary.opacity(0.1))
                    .cornerRadius(8)

                Spacer()

                Text("\(template.useCount) uses")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textMuted)

                Button {
                    teacherService.unshareTemplate(id: template.id)
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.warning)
                }
            }
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(Theme.cardRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius)
                .stroke(Theme.goldMuted.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Community Streak Card

struct CommunityStreakCard: View {
    let group: CommunityStreak

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            HStack {
                Text(group.groupName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Theme.textPrimary)

                Spacer()

                Text("\(group.currentStreak) days")
                    .font(.system(size: 17, weight: .light, design: .serif))
                    .foregroundColor(Theme.goldPrimary)
            }

            Text(group.description)
                .font(.system(size: 13))
                .foregroundColor(Theme.textSecondary)

            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "person.3")
                        .font(.system(size: 12))
                    Text("\(group.memberCount) members")
                        .font(.system(size: 12))
                }
                .foregroundColor(Theme.textMuted)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 12))
                    Text("\(group.activeMembersToday) active today")
                        .font(.system(size: 12))
                }
                .foregroundColor(Theme.success)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "flame")
                        .font(.system(size: 12))
                    Text("Best: \(group.longestStreak)")
                        .font(.system(size: 12))
                }
                .foregroundColor(Theme.textMuted)
            }
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(Theme.cardRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius)
                .stroke(Theme.goldMuted.opacity(0.3), lineWidth: 1)
        )
    }
}
