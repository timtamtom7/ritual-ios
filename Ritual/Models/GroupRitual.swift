import Foundation
import MultipeerConnectivity

// MARK: - Group Ritual Session

struct GroupRitual: Identifiable, Codable {
    let id: String
    var title: String
    var hostPeerId: String
    var participants: [Participant]
    var breathingPattern: BreathingPattern
    var durationMinutes: Int
    var scheduledAt: Date
    var isActive: Bool
    var createdAt: Date

    var participantCount: Int { participants.count }
    var hostDisplayName: String {
        participants.first { $0.peerId == hostPeerId }?.displayName ?? "Host"
    }

    init(
        id: String = UUID().uuidString,
        title: String,
        hostPeerId: String,
        participants: [Participant] = [],
        breathingPattern: BreathingPattern = .box,
        durationMinutes: Int = 5,
        scheduledAt: Date = Date(),
        isActive: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.hostPeerId = hostPeerId
        self.participants = participants
        self.breathingPattern = breathingPattern
        self.durationMinutes = durationMinutes
        self.scheduledAt = scheduledAt
        self.isActive = isActive
        self.createdAt = createdAt
    }
}

struct Participant: Identifiable, Codable, Hashable {
    let id: String
    let peerId: String
    let displayName: String
    var isConnected: Bool
    var joinedAt: Date
    var isHost: Bool

    init(
        id: String = UUID().uuidString,
        peerId: String,
        displayName: String,
        isConnected: Bool = true,
        joinedAt: Date = Date(),
        isHost: Bool = false
    ) {
        self.id = id
        self.peerId = peerId
        self.displayName = displayName
        self.isConnected = isConnected
        self.joinedAt = joinedAt
        self.isHost = isHost
    }
}

// MARK: - Group Session State

struct GroupBreathingState: Codable {
    var sessionId: String
    var hostPeerId: String
    var pattern: BreathingPattern
    var currentPhaseIndex: Int
    var phaseStartTime: Date
    var loopCount: Int
    var isRunning: Bool
    var participantCount: Int

    var currentPhase: String {
        let phases = pattern.phases
        guard currentPhaseIndex < phases.count else { return "Ready" }
        return phases[currentPhaseIndex].name
    }

    var timeRemainingInPhase: Int {
        guard currentPhaseIndex < pattern.phases.count else { return 0 }
        return max(0, Int(pattern.phases[currentPhaseIndex].duration) - Int(Date().timeIntervalSince(phaseStartTime)))
    }
}

// MARK: - Community Templates (shared by teachers)

struct SharedTemplate: Identifiable, Codable {
    let id: String
    let creatorId: String
    let creatorName: String
    var title: String
    var description: String
    var category: String
    var breathingPattern: BreathingPattern
    var suggestedDuration: Int
    var useCount: Int
    var rating: Double
    var isPublic: Bool
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        creatorId: String,
        creatorName: String,
        title: String,
        description: String,
        category: String,
        breathingPattern: BreathingPattern = .box,
        suggestedDuration: Int = 5,
        useCount: Int = 0,
        rating: Double = 5.0,
        isPublic: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.creatorId = creatorId
        self.creatorName = creatorName
        self.title = title
        self.description = description
        self.category = category
        self.breathingPattern = breathingPattern
        self.suggestedDuration = suggestedDuration
        self.useCount = useCount
        self.rating = rating
        self.isPublic = isPublic
        self.createdAt = createdAt
    }
}

// MARK: - Teacher Profile

struct TeacherProfile: Codable {
    let id: String
    var displayName: String
    var bio: String
    var sharedTemplates: [String] // template IDs
    var followerCount: Int
    var totalRitualsHosted: Int
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        displayName: String,
        bio: String = "",
        sharedTemplates: [String] = [],
        followerCount: Int = 0,
        totalRitualsHosted: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.displayName = displayName
        self.bio = bio
        self.sharedTemplates = sharedTemplates
        self.followerCount = followerCount
        self.totalRitualsHosted = totalRitualsHosted
        self.createdAt = createdAt
    }
}

// MARK: - Community Streak

struct CommunityStreak: Identifiable {
    let id: String
    let groupName: String
    var currentStreak: Int
    var longestStreak: Int
    var memberCount: Int
    var activeMembersToday: Int
    var totalSessionsCompleted: Int
    var lastSessionDate: Date?

    var streakEmoji: String {
        if currentStreak >= 30 { return "🏆" }
        if currentStreak >= 14 { return "⭐" }
        if currentStreak >= 7 { return "✨" }
        if currentStreak >= 3 { return "🌱" }
        return "💫"
    }

    var description: String {
        "\(streakEmoji) \(currentStreak)-day streak with \(memberCount) members"
    }
}
