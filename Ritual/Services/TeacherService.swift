import Foundation

@MainActor
final class TeacherService: ObservableObject {
    static let shared = TeacherService()

    @Published private(set) var profile: TeacherProfile?
    @Published private(set) var sharedTemplates: [SharedTemplate] = []
    @Published private(set) var communityTemplates: [SharedTemplate] = []
    @Published private(set) var communityGroups: [CommunityStreak] = []

    private let database = DatabaseService.shared
    private let userDefaults = UserDefaults.standard
    private let profileKey = "teacher_profile"
    private let templatesKey = "shared_templates"

    private init() {
        loadProfile()
        loadLocalTemplates()
        loadMockCommunityData()
    }

    // MARK: - Teacher Profile

    func createProfile(displayName: String, bio: String = "") {
        let newProfile = TeacherProfile(
            displayName: displayName,
            bio: bio
        )
        profile = newProfile
        saveProfile()
    }

    func updateProfile(displayName: String, bio: String) {
        profile?.displayName = displayName
        profile?.bio = bio
        saveProfile()
    }

    var isTeacher: Bool { profile != nil }

    private func saveProfile() {
        guard let profile = profile,
              let data = try? JSONEncoder().encode(profile) else { return }
        userDefaults.set(data, forKey: profileKey)
    }

    private func loadProfile() {
        guard let data = userDefaults.data(forKey: profileKey),
              let loadedProfile = try? JSONDecoder().decode(TeacherProfile.self, from: data) else { return }
        profile = loadedProfile
    }

    // MARK: - Share Template

    func shareTemplate(_ template: SharedTemplate) {
        var mutableTemplate = template
        mutableTemplate = SharedTemplate(
            id: UUID().uuidString,
            creatorId: profile?.id ?? "anonymous",
            creatorName: profile?.displayName ?? "Anonymous",
            title: template.title,
            description: template.description,
            category: template.category,
            breathingPattern: template.breathingPattern,
            suggestedDuration: template.suggestedDuration,
            useCount: 0,
            rating: 5.0,
            isPublic: true
        )
        sharedTemplates.append(mutableTemplate)
        profile?.sharedTemplates.append(mutableTemplate.id)
        profile?.totalRitualsHosted += 1
        saveSharedTemplates()
        saveProfile()
    }

    func createTemplateFromIntention(_ intention: Intention) -> SharedTemplate {
        SharedTemplate(
            creatorId: profile?.id ?? "anonymous",
            creatorName: profile?.displayName ?? "Anonymous",
            title: intention.text,
            description: "A ritual intention: \(intention.text ?? "")",
            category: intention.category ?? "General",
            breathingPattern: .box,
            suggestedDuration: 5
        )
    }

    func createTemplateFromCustom(_ custom: CustomTemplate) -> SharedTemplate {
        SharedTemplate(
            creatorId: profile?.id ?? "anonymous",
            creatorName: profile?.displayName ?? "Anonymous",
            title: custom.title,
            description: custom.description,
            category: custom.category,
            breathingPattern: .box,
            suggestedDuration: 5
        )
    }

    func unshareTemplate(id: String) {
        sharedTemplates.removeAll { $0.id == id }
        profile?.sharedTemplates.removeAll { $0 == id }
        saveSharedTemplates()
        saveProfile()
    }

    private func saveSharedTemplates() {
        guard let data = try? JSONEncoder().encode(sharedTemplates) else { return }
        userDefaults.set(data, forKey: templatesKey)
    }

    private func loadLocalTemplates() {
        guard let data = userDefaults.data(forKey: templatesKey),
              let templates = try? JSONDecoder().decode([SharedTemplate].self, from: data) else { return }
        sharedTemplates = templates
    }

    // MARK: - Community Templates

    func browseCommunityTemplates(category: String? = nil) {
        // In a real app, this would fetch from a server
        // For now, we use mock data filtered by category
        if let cat = category {
            communityTemplates = mockCommunityTemplates.filter { $0.category == cat }
        } else {
            communityTemplates = mockCommunityTemplates
        }
    }

    func adoptTemplate(_ template: SharedTemplate) {
        // Adopt a community template as a personal template
        // This increments the use count
        if let index = communityTemplates.firstIndex(where: { $0.id == template.id }) {
            communityTemplates[index] = SharedTemplate(
                id: template.id,
                creatorId: template.creatorId,
                creatorName: template.creatorName,
                title: template.title,
                description: template.description,
                category: template.category,
                breathingPattern: template.breathingPattern,
                suggestedDuration: template.suggestedDuration,
                useCount: template.useCount + 1,
                rating: template.rating,
                isPublic: template.isPublic,
                createdAt: template.createdAt
            )
        }
    }

    private func loadMockCommunityData() {
        communityTemplates = mockCommunityTemplates
        communityGroups = mockCommunityGroups
    }

    // MARK: - Groups / Community Streaks

    func createGroup(name: String, memberCount: Int = 1) -> CommunityStreak {
        let group = CommunityStreak(
            id: UUID().uuidString,
            groupName: name,
            currentStreak: 0,
            longestStreak: 0,
            memberCount: memberCount,
            activeMembersToday: memberCount,
            totalSessionsCompleted: 0
        )
        communityGroups.append(group)
        return group
    }

    func recordGroupSession(groupId: String) {
        guard let index = communityGroups.firstIndex(where: { $0.id == groupId }) else { return }
        var group = communityGroups[index]
        group.totalSessionsCompleted += 1
        group.lastSessionDate = Date()

        // Simple streak logic: if last session was yesterday or today, increment
        if let lastDate = group.lastSessionDate {
            let calendar = Calendar.current
            if calendar.isDateInToday(lastDate) || calendar.isDateInYesterday(lastDate) {
                group.currentStreak += 1
            } else {
                group.currentStreak = 1
            }
        } else {
            group.currentStreak = 1
        }

        if group.currentStreak > group.longestStreak {
            group.longestStreak = group.currentStreak
        }

        communityGroups[index] = group
    }

    // MARK: - Mock Data

    private var mockCommunityTemplates: [SharedTemplate] {
        [
            SharedTemplate(
                id: "ct1",
                creatorId: "teacher1",
                creatorName: "Sarah M.",
                title: "Morning Clarity Ritual",
                description: "Start your day with intention and focus",
                category: "Morning",
                breathingPattern: .coherent,
                suggestedDuration: 5,
                useCount: 234,
                rating: 4.8
            ),
            SharedTemplate(
                id: "ct2",
                creatorId: "teacher2",
                creatorName: "James K.",
                title: "Pre-Presentation Calm",
                description: "Use before important moments to center yourself",
                category: "Performance",
                breathingPattern: .box,
                suggestedDuration: 3,
                useCount: 156,
                rating: 4.9
            ),
            SharedTemplate(
                id: "ct3",
                creatorId: "teacher1",
                creatorName: "Sarah M.",
                title: "Evening Wind-Down",
                description: "Transition from work to rest with gentle breath",
                category: "Evening",
                breathingPattern: .sleep,
                suggestedDuration: 7,
                useCount: 412,
                rating: 4.7
            ),
            SharedTemplate(
                id: "ct4",
                creatorId: "teacher3",
                creatorName: "Priya R.",
                title: "Creative Flow State",
                description: "Open the channels of creativity before artistic work",
                category: "Creativity",
                breathingPattern: .energize,
                suggestedDuration: 5,
                useCount: 189,
                rating: 4.6
            ),
            SharedTemplate(
                id: "ct5",
                creatorId: "teacher4",
                creatorName: "David L.",
                title: "Conflict De-escalation",
                description: "A brief practice to return to calm during tense moments",
                category: "Relationships",
                breathingPattern: .extendedExhale,
                suggestedDuration: 3,
                useCount: 98,
                rating: 4.5
            ),
            SharedTemplate(
                id: "ct6",
                creatorId: "teacher5",
                creatorName: "Emma W.",
                title: "Study Focus Session",
                description: "Deep concentration breathing for learning",
                category: "Work",
                breathingPattern: .coherent,
                suggestedDuration: 10,
                useCount: 321,
                rating: 4.8
            )
        ]
    }

    private var mockCommunityGroups: [CommunityStreak] {
        [
            CommunityStreak(
                id: "cg1",
                groupName: "Morning Ritual Circle",
                currentStreak: 14,
                longestStreak: 28,
                memberCount: 8,
                activeMembersToday: 6,
                totalSessionsCompleted: 142
            ),
            CommunityStreak(
                id: "cg2",
                groupName: "Sleep Hygiene Practice",
                currentStreak: 7,
                longestStreak: 14,
                memberCount: 12,
                activeMembersToday: 9,
                totalSessionsCompleted: 89
            ),
            CommunityStreak(
                id: "cg3",
                groupName: "Pre-Meeting Mindfulness",
                currentStreak: 21,
                longestStreak: 35,
                memberCount: 5,
                activeMembersToday: 4,
                totalSessionsCompleted: 203
            )
        ]
    }
}
