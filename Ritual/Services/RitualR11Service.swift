import Foundation

// R11: Group Sessions, Community, Video for Ritual
@MainActor
final class RitualR11Service: ObservableObject {
    static let shared = RitualR11Service()

    @Published var groupSessions: [GroupSession] = []
    @Published var communityFeed: [CommunityMoment] = []

    private init() {}

    // MARK: - Group Sessions

    struct GroupSession: Identifiable {
        let id: UUID
        let title: String
        let hostName: String
        let scheduledAt: Date
        let participantCount: Int
        let maxParticipants: Int
        let technique: String
    }

    func scheduleSession(title: String, technique: String, at date: Date, maxParticipants: Int) -> GroupSession {
        GroupSession(
            id: UUID(),
            title: title,
            hostName: "You",
            scheduledAt: date,
            participantCount: 1,
            maxParticipants: maxParticipants,
            technique: technique
        )
    }

    // MARK: - Community

    struct CommunityMoment: Identifiable {
        let id = UUID()
        let content: String
        let authorName: String
        let timestamp: Date
        let reactions: [Reaction]

        struct Reaction {
            let emoji: String
            var count: Int
        }
    }

    func postMoment(content: String) -> CommunityMoment {
        CommunityMoment(
            content: content,
            authorName: "Anonymous",
            timestamp: Date(),
            reactions: []
        )
    }

    // MARK: - Video

    struct VideoMoment: Identifiable {
        let id = UUID()
        let videoURL: URL
        let caption: String
        let duration: TimeInterval
        let createdAt: Date
    }

    func recordMoment(caption: String) async -> VideoMoment {
        VideoMoment(
            videoURL: URL(string: "file://temp")!,
            caption: caption,
            duration: 0,
            createdAt: Date()
        )
    }
}
