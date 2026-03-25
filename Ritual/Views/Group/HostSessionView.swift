import SwiftUI
import MultipeerConnectivity

struct HostSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var groupService = GroupBreathingService.shared

    @State private var sessionTitle = ""
    @State private var selectedPattern: BreathingPattern = .box
    @State private var selectedDuration: Int = 5
    @State private var isHosting = false

    let durations = [3, 5, 7, 10, 15]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.spacingL) {
                    // Session Title
                    VStack(alignment: .leading, spacing: Theme.spacingS) {
                        Text("Session Name")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Theme.textMuted)

                        TextField("e.g., Morning Breath Together", text: $sessionTitle)
                            .font(.system(size: 17))
                            .padding(Theme.spacingM)
                            .background(Theme.surface)
                            .cornerRadius(Theme.cardRadius)
                            .foregroundColor(Theme.textPrimary)
                    }

                    // Breathing Pattern
                    VStack(alignment: .leading, spacing: Theme.spacingS) {
                        Text("Breathing Pattern")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Theme.textMuted)

                        ForEach([BreathingPattern.box, .calm, .coherent, .energize], id: \.self) { pattern in
                            Button {
                                selectedPattern = pattern
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(pattern.rawValue)
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(Theme.textPrimary)
                                        Text(pattern.description)
                                            .font(.system(size: 13))
                                            .foregroundColor(Theme.textMuted)
                                    }

                                    Spacer()

                                    if selectedPattern == pattern {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(Theme.goldPrimary)
                                    }
                                }
                                .padding(Theme.spacingM)
                                .background(selectedPattern == pattern ? Theme.goldPrimary.opacity(0.1) : Theme.surface)
                                .cornerRadius(Theme.cardRadius)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.cardRadius)
                                        .stroke(selectedPattern == pattern ? Theme.goldPrimary.opacity(0.5) : Color.clear, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Duration
                    VStack(alignment: .leading, spacing: Theme.spacingS) {
                        Text("Duration")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Theme.textMuted)

                        HStack(spacing: Theme.spacingS) {
                            ForEach(durations, id: \.self) { duration in
                                Button {
                                    selectedDuration = duration
                                } label: {
                                    Text("\(duration) min")
                                        .font(.system(size: 14, weight: selectedDuration == duration ? .semibold : .regular))
                                        .foregroundColor(selectedDuration == duration ? Color(hex: "0D0B09") : Theme.textPrimary)
                                        .padding(.horizontal, Theme.spacingM)
                                        .padding(.vertical, Theme.spacingS)
                                        .background(selectedDuration == duration ? Theme.goldPrimary : Theme.surface)
                                        .cornerRadius(Theme.buttonRadius)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Spacer()

                    // Host Button
                    Button {
                        hostSession()
                    } label: {
                        if isHosting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "0D0B09")))
                        } else {
                            Label("Start Hosting", systemImage: "dot.radiowaves.left.and.right")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(Color(hex: "0D0B09"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Theme.spacingM)
                                .background(Theme.goldPrimary)
                                .cornerRadius(Theme.buttonRadius)
                        }
                    }
                    .disabled(sessionTitle.isEmpty || isHosting)
                    .opacity(sessionTitle.isEmpty ? 0.5 : 1)
                }
                .padding(Theme.spacingM)
            }
            .background(Theme.background)
            .navigationTitle("Host a Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Theme.goldPrimary)
                }
            }
        }
    }

    private func hostSession() {
        isHosting = true
        Task {
            let session = await groupService.hostSession(
                title: sessionTitle,
                pattern: selectedPattern,
                duration: selectedDuration
            )
            await MainActor.run {
                isHosting = false
                if session != nil {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Join Session View

struct JoinSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var groupService = GroupBreathingService.shared
    @State private var isJoining = false
    @State private var selectedSession: GroupRitual?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.spacingL) {
                    if groupService.nearbySessions.isEmpty {
                        emptyState
                    } else {
                        sessionList
                    }
                }
                .padding(Theme.spacingM)
            }
            .background(Theme.background)
            .navigationTitle("Find Nearby Sessions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        groupService.stopBrowsing()
                        dismiss()
                    }
                    .foregroundColor(Theme.goldPrimary)
                }
            }
            .onAppear {
                groupService.startBrowsing()
            }
            .onDisappear {
                groupService.stopBrowsing()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: Theme.spacingM) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Theme.goldPrimary))
                .scaleEffect(1.2)

            Text("Searching for nearby sessions...")
                .font(.system(size: 15))
                .foregroundColor(Theme.textMuted)

            Text("Make sure the host has started a session nearby")
                .font(.system(size: 13))
                .foregroundColor(Theme.textMuted)
                .multilineTextAlignment(.center)

            Button {
                groupService.startBrowsing()
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.goldPrimary)
            }
            .buttonStyle(.bordered)
            .padding(.top, Theme.spacingS)
        }
        .padding(Theme.spacingL)
    }

    private var sessionList: some View {
        VStack(spacing: Theme.spacingS) {
            Text("\(groupService.nearbySessions.count) session\(groupService.nearbySessions.count == 1 ? "" : "s") found")
                .font(.system(size: 13))
                .foregroundColor(Theme.textMuted)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(groupService.nearbySessions) { session in
                Button {
                    joinSession(session)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(session.title)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Theme.textPrimary)

                            Text("Host: \(session.hostPeerId) • \(session.durationMinutes) min")
                                .font(.system(size: 13))
                                .foregroundColor(Theme.textMuted)

                            HStack(spacing: 4) {
                                Image(systemName: "wind")
                                    .font(.system(size: 11))
                                Text(session.breathingPattern.rawValue)
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(Theme.goldMuted)
                        }

                        Spacer()

                        if isJoining && selectedSession?.id == session.id {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Theme.goldPrimary))
                        } else {
                            Image(systemName: "chevron.right")
                                .foregroundColor(Theme.textMuted)
                        }
                    }
                    .padding(Theme.spacingM)
                    .background(Theme.surface)
                    .cornerRadius(Theme.cardRadius)
                }
                .buttonStyle(.plain)
                .disabled(isJoining)
            }
        }
    }

    private func joinSession(_ session: GroupRitual) {
        selectedSession = session
        isJoining = true
        // In a real implementation, we'd get the MCPeerID from the browser
        // For now, this is a simplified version
        Task {
            let success = await groupService.joinSession(session, hostPeerId: MCPeerID(displayName: session.hostPeerId))
            await MainActor.run {
                isJoining = false
                if success {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Teacher Setup View

struct TeacherSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var teacherService = TeacherService.shared

    @State private var displayName: String = ""
    @State private var bio: String = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.spacingL) {
                    if teacherService.isTeacher {
                        // Edit existing profile
                        existingProfile
                    } else {
                        // Create new profile
                        createProfile
                    }
                }
                .padding(Theme.spacingM)
            }
            .background(Theme.background)
            .navigationTitle("Teacher Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Theme.goldPrimary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveProfile()
                    }
                    .foregroundColor(Theme.goldPrimary)
                    .disabled(displayName.isEmpty)
                }
            }
            .onAppear {
                if let profile = teacherService.profile {
                    displayName = profile.displayName
                    bio = profile.bio
                }
            }
        }
    }

    private var createProfile: some View {
        VStack(alignment: .leading, spacing: Theme.spacingL) {
            // Header illustration
            VStack(spacing: Theme.spacingS) {
                Image(systemName: "person.wave.2.fill")
                    .font(.system(size: 48))
                    .foregroundColor(Theme.goldPrimary)

                Text("Become a Teacher")
                    .font(.system(size: 20, weight: .light, design: .serif))
                    .foregroundColor(Theme.textPrimary)

                Text("Share your ritual wisdom with others. Your templates and practice can help people build better habits.")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.spacingM)

            VStack(alignment: .leading, spacing: Theme.spacingS) {
                Text("Display Name")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Theme.textMuted)

                TextField("Your name", text: $displayName)
                    .font(.system(size: 17))
                    .padding(Theme.spacingM)
                    .background(Theme.surface)
                    .cornerRadius(Theme.cardRadius)
                    .foregroundColor(Theme.textPrimary)
            }

            VStack(alignment: .leading, spacing: Theme.spacingS) {
                Text("Bio (optional)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Theme.textMuted)

                TextField("What inspires your practice?", text: $bio, axis: .vertical)
                    .font(.system(size: 17))
                    .lineLimit(3...6)
                    .padding(Theme.spacingM)
                    .background(Theme.surface)
                    .cornerRadius(Theme.cardRadius)
                    .foregroundColor(Theme.textPrimary)
            }
        }
    }

    private var existingProfile: some View {
        VStack(alignment: .leading, spacing: Theme.spacingL) {
            VStack(alignment: .leading, spacing: Theme.spacingS) {
                Text("Display Name")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Theme.textMuted)

                TextField("Your name", text: $displayName)
                    .font(.system(size: 17))
                    .padding(Theme.spacingM)
                    .background(Theme.surface)
                    .cornerRadius(Theme.cardRadius)
                    .foregroundColor(Theme.textPrimary)
            }

            VStack(alignment: .leading, spacing: Theme.spacingS) {
                Text("Bio")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Theme.textMuted)

                TextField("What inspires your practice?", text: $bio, axis: .vertical)
                    .font(.system(size: 17))
                    .lineLimit(3...6)
                    .padding(Theme.spacingM)
                    .background(Theme.surface)
                    .cornerRadius(Theme.cardRadius)
                    .foregroundColor(Theme.textPrimary)
            }

            if let profile = teacherService.profile {
                VStack(alignment: .leading, spacing: Theme.spacingS) {
                    Text("Stats")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.textMuted)

                    HStack(spacing: Theme.spacingL) {
                        VStack {
                            Text("\(profile.followerCount)")
                                .font(.system(size: 22, weight: .light, design: .serif))
                                .foregroundColor(Theme.textPrimary)
                            Text("Followers")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.textMuted)
                        }
                        VStack {
                            Text("\(profile.totalRitualsHosted)")
                                .font(.system(size: 22, weight: .light, design: .serif))
                                .foregroundColor(Theme.textPrimary)
                            Text("Hosted")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.textMuted)
                        }
                        VStack {
                            Text("\(profile.sharedTemplates.count)")
                                .font(.system(size: 22, weight: .light, design: .serif))
                                .foregroundColor(Theme.textPrimary)
                            Text("Templates")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.textMuted)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(Theme.spacingM)
                    .background(Theme.surface)
                    .cornerRadius(Theme.cardRadius)
                }
            }
        }
    }

    private func saveProfile() {
        if teacherService.isTeacher {
            teacherService.updateProfile(displayName: displayName, bio: bio)
        } else {
            teacherService.createProfile(displayName: displayName, bio: bio)
        }
        dismiss()
    }
}

// MARK: - Group Breathing View

struct GroupBreathingView: View {
    let session: GroupRitual
    @StateObject private var groupService = GroupBreathingService.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(spacing: Theme.spacingL) {
                    // Participants
                    participantsBar

                    Spacer()

                    // Breathing animation
                    breathingAnimation

                    Spacer()

                    // Controls
                    if groupService.role == .host {
                        hostControls
                    } else {
                        participantStatus
                    }

                    // Participants list
                    participantsList
                }
                .padding(Theme.spacingM)
            }
            .navigationTitle(session.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Leave") {
                        groupService.leaveSession()
                        dismiss()
                    }
                    .foregroundColor(Theme.warning)
                }
            }
        }
    }

    private var participantsBar: some View {
        HStack {
            HStack(spacing: -8) {
                ForEach(Array(groupService.participants.prefix(5).enumerated()), id: \.element.id) { index, participant in
                    Circle()
                        .fill(Theme.goldPrimary.opacity(0.3 + Double(index) * 0.15))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text(String(participant.displayName.prefix(1)).uppercased())
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Theme.textPrimary)
                        )
                        .overlay(
                            Circle()
                                .stroke(Theme.background, lineWidth: 2)
                        )
                }

                if groupService.participants.count > 5 {
                    Circle()
                        .fill(Theme.surface)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text("+\(groupService.participants.count - 5)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Theme.textMuted)
                        )
                        .overlay(
                            Circle()
                                .stroke(Theme.background, lineWidth: 2)
                        )
                }
            }

            Spacer()

            Text("\(groupService.participants.count) joined")
                .font(.system(size: 13))
                .foregroundColor(Theme.textMuted)
        }
        .padding(.horizontal, Theme.spacingM)
    }

    private var breathingAnimation: some View {
        ZStack {
            Circle()
                .stroke(Theme.goldMuted.opacity(0.3), lineWidth: 4)
                .frame(width: 200, height: 200)

            Circle()
                .fill(Theme.goldPrimary.opacity(0.15))
                .frame(width: circleSize, height: circleSize)
                .animation(.easeInOut(duration: 1), value: circleSize)

            VStack(spacing: 4) {
                Text(phaseText)
                    .font(.system(size: 20, weight: .medium, design: .serif))
                    .foregroundColor(Theme.goldGlow)

                if let state = groupService.breathingState, state.isRunning {
                    Text("\(state.timeRemainingInPhase)")
                        .font(.system(size: 48, weight: .light, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                }

                if let state = groupService.breathingState {
                    Text("Loop \(state.loopCount + 1)")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.textMuted)
                }
            }
        }
    }

    private var circleSize: CGFloat {
        guard let state = groupService.breathingState, state.isRunning else { return 120 }
        switch state.currentPhase {
        case "Breathe In": return 180
        case "Hold": return 180
        case "Breathe Out": return 100
        default: return 140
        }
    }

    private var phaseText: String {
        guard let state = groupService.breathingState else {
            return "Ready"
        }
        if !state.isRunning {
            return "Paused"
        }
        return state.currentPhase
    }

    private var hostControls: some View {
        HStack(spacing: Theme.spacingM) {
            Button {
                if groupService.breathingState?.isRunning == true {
                    groupService.stopBreathing()
                } else {
                    groupService.startBreathing()
                }
            } label: {
                Label(
                    groupService.breathingState?.isRunning == true ? "Stop" : "Start",
                    systemImage: groupService.breathingState?.isRunning == true ? "stop.fill" : "play.fill"
                )
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Color(hex: "0D0B09"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.spacingM)
                .background(Theme.goldPrimary)
                .cornerRadius(Theme.buttonRadius)
            }
        }
    }

    private var participantStatus: some View {
        VStack(spacing: Theme.spacingS) {
            if groupService.breathingState?.isRunning == true {
                HStack {
                    Image(systemName: "waveform")
                        .foregroundColor(Theme.goldPrimary)
                    Text("Breathing in sync with the group")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.textSecondary)
                }
            } else {
                HStack {
                    Image(systemName: "pause.circle")
                        .foregroundColor(Theme.textMuted)
                    Text("Waiting for host to start...")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.textMuted)
                }
            }
        }
        .padding(Theme.spacingM)
        .frame(maxWidth: .infinity)
        .background(Theme.surface)
        .cornerRadius(Theme.cardRadius)
    }

    private var participantsList: some View {
        VStack(alignment: .leading, spacing: Theme.spacingXS) {
            Text("Participants")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Theme.textMuted)

            ForEach(groupService.participants) { participant in
                HStack {
                    Circle()
                        .fill(participant.isConnected ? Theme.success : Theme.textMuted)
                        .frame(width: 8, height: 8)

                    Text(participant.displayName)
                        .font(.system(size: 14))
                        .foregroundColor(Theme.textPrimary)

                    if participant.isHost {
                        Text("Host")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Theme.goldPrimary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.goldPrimary.opacity(0.1))
                            .cornerRadius(4)
                    }

                    Spacer()
                }
            }
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(Theme.cardRadius)
    }
}
