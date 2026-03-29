import Foundation
import MultipeerConnectivity

// MARK: - Accountability Partner

struct AccountabilityPartner: Identifiable, Codable, Equatable {
    let id: String
    var displayName: String
    var currentStreak: Int
    var todayCompleted: Bool
    var relationship: PartnerRelationship
    var lastCheckIn: Date?
    var mutedMode: Bool

    init(
        id: String = UUID().uuidString,
        displayName: String,
        currentStreak: Int = 0,
        todayCompleted: Bool = false,
        relationship: PartnerRelationship = .accountabilityBuddy,
        lastCheckIn: Date? = nil,
        mutedMode: Bool = false
    ) {
        self.id = id
        self.displayName = displayName
        self.currentStreak = currentStreak
        self.todayCompleted = todayCompleted
        self.relationship = relationship
        self.lastCheckIn = lastCheckIn
        self.mutedMode = mutedMode
    }
}

enum PartnerRelationship: String, Codable, CaseIterable {
    case accountabilityBuddy = "Accountability Buddy"
    case partner = "Partner"
    case familyMember = "Family Member"
    case child = "Child"

    var icon: String {
        switch self {
        case .accountabilityBuddy: return "person.2.fill"
        case .partner: return "heart.fill"
        case .familyMember: return "house.fill"
        case .child: return "figure.and.child.holdinghands"
        }
    }
}

// MARK: - Shared Ritual

struct SharedRitual: Identifiable, Codable {
    let id: String
    var title: String
    let hostId: String
    var participants: [String]
    let scheduledAt: Date
    let ritualType: SharedRitualType
    var completedBy: [String]
    var isActive: Bool

    init(
        id: String = UUID().uuidString,
        title: String,
        hostId: String,
        participants: [String] = [],
        scheduledAt: Date = Date(),
        ritualType: SharedRitualType = .synchronizedBreathing,
        completedBy: [String] = [],
        isActive: Bool = true
    ) {
        self.id = id
        self.title = title
        self.hostId = hostId
        self.participants = participants
        self.scheduledAt = scheduledAt
        self.ritualType = ritualType
        self.completedBy = completedBy
        self.isActive = isActive
    }
}

enum SharedRitualType: String, Codable, CaseIterable {
    case synchronizedBreathing = "Synchronized Breathing"
    case sharedIntentionSetting = "Shared Intention"
    case eveningCheckIn = "Evening Check-In"
    case familyBreathing = "Family Breathing"

    var icon: String {
        switch self {
        case .synchronizedBreathing: return "wind"
        case .sharedIntentionSetting: return "text.bubble.fill"
        case .eveningCheckIn: return "moon.stars.fill"
        case .familyBreathing: return "figure.2.and.child.holdinghands"
        }
    }

    var description: String {
        switch self {
        case .synchronizedBreathing: return "Breathe together in sync"
        case .sharedIntentionSetting: return "Set an intention with your partner"
        case .eveningCheckIn: return "Reflect on your day together"
        case .familyBreathing: return "Family breathing exercise"
        }
    }
}

// MARK: - Encouragement

struct Encouragement: Identifiable, Codable {
    let id: String
    let fromPartnerId: String
    let message: String
    let sentAt: Date

    init(id: String = UUID().uuidString, fromPartnerId: String, message: String, sentAt: Date = Date()) {
        self.id = id
        self.fromPartnerId = fromPartnerId
        self.message = message
        self.sentAt = sentAt
    }
}

// MARK: - Accountability Service

@MainActor
final class AccountabilityService: NSObject, ObservableObject {
    static let shared = AccountabilityService()

    // MARK: - Properties

    private let serviceType = "ritual-account"
    private var peerID: MCPeerID!
    private var session: MCSession!
    private var advertiser: MCNearbyServiceAdvertiser!
    private var browser: MCNearbyServiceBrowser!

    private(set) var partners: [AccountabilityPartner] = []
    private(set) var sharedRituals: [SharedRitual] = []
    private(set) var encouragements: [Encouragement] = []

    var onPartnerUpdated: ((AccountabilityPartner) -> Void)?
    var onRitualUpdated: ((SharedRitual) -> Void)?
    var onEncouragementReceived: ((Encouragement) -> Void)?

    private let userDefaultsKey = "accountability_partners"
    private let ritualsKey = "shared_rituals"
    private let encouragementsKey = "encouragements"

    // MARK: - Initialization

    private override init() {
        super.init()
        setupPeerConnectivity()
        loadPartners()
        loadRituals()
        loadEncouragements()
    }

    private func setupPeerConnectivity() {
        peerID = MCPeerID(displayName: Host.current().localizedName ?? "RitualMac")
        session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self

        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: serviceType)
        advertiser.delegate = self

        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        browser.delegate = self
    }

    // MARK: - Partner Management

    func invitePartner(email: String) {
        // In a real implementation, this would send an email invitation
        // For now, we create a local partner entry as a placeholder
        let partner = AccountabilityPartner(
            displayName: email.components(separatedBy: "@").first ?? "Partner",
            relationship: .accountabilityBuddy
        )
        partners.append(partner)
        savePartners()
    }

    func getPartners() -> [AccountabilityPartner] {
        return partners
    }

    func removePartner(_ partner: AccountabilityPartner) {
        partners.removeAll { $0.id == partner.id }
        savePartners()
    }

    func updatePartner(_ partner: AccountabilityPartner) {
        if let index = partners.firstIndex(where: { $0.id == partner.id }) {
            partners[index] = partner
            savePartners()
            onPartnerUpdated?(partner)
        }
    }

    func toggleMutedMode(for partner: AccountabilityPartner) {
        var updated = partner
        updated.mutedMode.toggle()
        updatePartner(updated)
    }

    // MARK: - Check-Ins

    func sendCheckIn(ritualId: UUID, completed: Bool) {
        // Record the check-in locally
        let partnerId = "self"
        let _ = completed

        // Update streak data for partners
        for index in partners.indices {
            if partners[index].todayCompleted {
                partners[index].currentStreak += 1
            } else {
                partners[index].currentStreak = 0
            }
            partners[index].lastCheckIn = Date()
            partners[index].todayCompleted = completed
        }
        savePartners()
    }

    func markPartnerCompleted(_ partnerId: String) {
        if let index = partners.firstIndex(where: { $0.id == partnerId }) {
            partners[index].todayCompleted = true
            partners[index].lastCheckIn = Date()
            partners[index].currentStreak += 1
            savePartners()
            onPartnerUpdated?(partners[index])
        }
    }

    // MARK: - Shared Rituals

    func createSharedRitual(title: String, type: SharedRitualType, scheduledAt: Date = Date()) -> SharedRitual {
        let ritual = SharedRitual(
            title: title,
            hostId: peerID.displayName,
            scheduledAt: scheduledAt,
            ritualType: type
        )
        sharedRituals.append(ritual)
        saveRituals()
        return ritual
    }

    func joinRitual(_ ritual: SharedRitual) {
        if let index = sharedRituals.firstIndex(where: { $0.id == ritual.id }) {
            if !sharedRituals[index].participants.contains(peerID.displayName) {
                sharedRituals[index].participants.append(peerID.displayName)
                saveRituals()
                onRitualUpdated?(sharedRituals[index])
            }
        }
    }

    func completeRitual(_ ritualId: String) {
        if let index = sharedRituals.firstIndex(where: { $0.id == ritualId }) {
            if !sharedRituals[index].completedBy.contains(peerID.displayName) {
                sharedRituals[index].completedBy.append(peerID.displayName)
                saveRituals()
                onRitualUpdated?(sharedRituals[index])
            }
        }
    }

    func getActiveRituals() -> [SharedRitual] {
        return sharedRituals.filter { $0.isActive }
    }

    // MARK: - Encouragements

    func sendEncouragement(to partner: AccountabilityPartner, message: String) {
        let encouragement = Encouragement(
            fromPartnerId: peerID.displayName,
            message: message
        )
        encouragements.append(encouragement)
        saveEncouragements()
        onEncouragementReceived?(encouragement)
    }

    func sendQuickEncouragement(to partner: AccountabilityPartner) {
        let messages = [
            "You've got this! 🌟",
            "Keep going! 💪",
            "Proud of you! ✨",
            "Stay strong! 🔥",
            "Believe in yourself! 💛"
        ]
        let randomMessage = messages.randomElement() ?? "You've got this!"
        sendEncouragement(to: partner, message: randomMessage)
    }

    // MARK: - Family Rituals

    func createFamilyRitual(title: String, type: SharedRitualType = .familyBreathing) -> SharedRitual {
        return createSharedRitual(title: title, type: type)
    }

    func getFamilyRituals() -> [SharedRitual] {
        return sharedRituals.filter { $0.ritualType == .familyBreathing }
    }

    // MARK: - Persistence

    private func loadPartners() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let decoded = try? JSONDecoder().decode([AccountabilityPartner].self, from: data) else {
            return
        }
        partners = decoded
    }

    private func savePartners() {
        if let encoded = try? JSONEncoder().encode(partners) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }

    private func loadRituals() {
        guard let data = UserDefaults.standard.data(forKey: ritualsKey),
              let decoded = try? JSONDecoder().decode([SharedRitual].self, from: data) else {
            return
        }
        sharedRituals = decoded
    }

    private func saveRituals() {
        if let encoded = try? JSONEncoder().encode(sharedRituals) {
            UserDefaults.standard.set(encoded, forKey: ritualsKey)
        }
    }

    private func loadEncouragements() {
        guard let data = UserDefaults.standard.data(forKey: encouragementsKey),
              let decoded = try? JSONDecoder().decode([Encouragement].self, from: data) else {
            return
        }
        encouragements = decoded
    }

    private func saveEncouragements() {
        if let encoded = try? JSONEncoder().encode(encouragements) {
            UserDefaults.standard.set(encoded, forKey: encouragementsKey)
        }
    }

    // MARK: - Broadcasting

    func startBroadcasting() {
        advertiser.startAdvertisingPeer()
        browser.startBrowsingForPeers()
    }

    func stopBroadcasting() {
        advertiser.stopAdvertisingPeer()
        browser.stopBrowsingForPeers()
    }

    // MARK: - Data Export

    func exportWeeklySummary() -> String {
        let activePartners = partners.filter { $0.currentStreak > 0 }
        var summary = "📊 Weekly Accountability Summary\n\n"

        for partner in activePartners {
            summary += "\(partner.displayName): \(partner.currentStreak)-day streak\n"
            if let lastCheckIn = partner.lastCheckIn {
                let formatter = RelativeDateTimeFormatter()
                formatter.unitsStyle = .full
                let relative = formatter.localizedString(for: lastCheckIn, relativeTo: Date())
                summary += "Last check-in: \(relative)\n"
            }
            summary += "\n"
        }

        return summary
    }
}

// MARK: - MCSessionDelegate

extension AccountabilityService: MCSessionDelegate {
    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        let peerName = peerID.displayName
        Task { @MainActor in
            switch state {
            case .connected:
                print("Connected to: \(peerName)")
            case .connecting:
                print("Connecting to: \(peerName)")
            case .notConnected:
                print("Disconnected from: \(peerName)")
            @unknown default:
                break
            }
        }
    }

    nonisolated func session(_ session: MCSession, didReceive data: Data?, fromPeer peerID: MCPeerID) {
        guard let data = data else { return }
        let peerName = peerID.displayName
        Task { @MainActor in
            // Handle received data (check-in updates, ritual completions, encouragements)
            if let update = try? JSONDecoder().decode(PartnerUpdateMessage.self, from: data) {
                handlePartnerUpdate(update, from: peerName)
            }
        }
    }

    nonisolated func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}

    nonisolated func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}

    nonisolated func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension AccountabilityService: MCNearbyServiceAdvertiserDelegate {
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // Auto-accept invitations for now
        invitationHandler(true, nil)
    }

    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("Failed to advertise: \(error.localizedDescription)")
    }
}

// MARK: - MCNearbyServiceBrowserDelegate

extension AccountabilityService: MCNearbyServiceBrowserDelegate {
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        // Peer discovered - invite will be handled via startBroadcasting session
        print("Found peer: \(peerID.displayName)")
    }

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        let peerName = peerID.displayName
        print("Lost peer: \(peerName)")
    }

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("Failed to browse: \(error.localizedDescription)")
    }
}

// MARK: - Message Types

private struct PartnerUpdateMessage: Codable {
    let type: UpdateType
    let partnerId: String
    let streak: Int
    let completedToday: Bool
    let timestamp: Date

    enum UpdateType: String, Codable {
        case checkIn
        case encouragement
        case ritualCompletion
    }
}

extension AccountabilityService {
    private func handlePartnerUpdate(_ update: PartnerUpdateMessage, from peerName: String) {
        switch update.type {
        case .checkIn:
            if let index = partners.firstIndex(where: { $0.displayName == peerName }) {
                partners[index].currentStreak = update.streak
                partners[index].todayCompleted = update.completedToday
                partners[index].lastCheckIn = update.timestamp
                savePartners()
                onPartnerUpdated?(partners[index])
            }
        case .encouragement:
            break // Handled separately
        case .ritualCompletion:
            break // Handled separately
        }
    }
}
