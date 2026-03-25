import Foundation
import MultipeerConnectivity

enum GroupRole {
    case host
    case participant
}

@MainActor
final class GroupBreathingService: NSObject, ObservableObject {
    static let shared = GroupBreathingService()

    @Published private(set) var role: GroupRole?
    @Published private(set) var session: GroupRitual?
    @Published private(set) var participants: [Participant] = []
    @Published private(set) var breathingState: GroupBreathingState?
    @Published private(set) var isConnected: Bool = false
    @Published private(set) var nearbySessions: [GroupRitual] = []
    @Published private(set) var error: String?

    private var peerId: MCPeerID!
    private nonisolated(unsafe) var mcSession: MCSession!
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?

    private let serviceType = "ritual-group"
    private let database = DatabaseService.shared

    private var stateTimer: Timer?
    private var phaseIndex: Int = 0
    private var loopCount: Int = 0

    private override init() {
        super.init()
        setupPeerId()
    }

    private func setupPeerId() {
        let deviceName = UIDevice.current.name
        peerId = MCPeerID(displayName: deviceName)
        mcSession = MCSession(peer: peerId, securityIdentity: nil, encryptionPreference: .required)
        mcSession.delegate = self
    }

    // MARK: - Host a Session

    func hostSession(title: String, pattern: BreathingPattern, duration: Int) async -> GroupRitual? {
        stopAll()

        let sessionId = UUID().uuidString
        let participant = Participant(
            peerId: peerId.displayName,
            displayName: peerId.displayName,
            isConnected: true,
            isHost: true
        )

        let newSession = GroupRitual(
            id: sessionId,
            title: title,
            hostPeerId: peerId.displayName,
            participants: [participant],
            breathingPattern: pattern,
            durationMinutes: duration
        )

        session = newSession
        participants = [participant]
        role = .host

        advertiser = MCNearbyServiceAdvertiser(peer: peerId, discoveryInfo: [
            "sessionId": sessionId,
            "title": title,
            "pattern": pattern.rawValue,
            "duration": "\(duration)"
        ], serviceType: serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()

        isConnected = true
        return newSession
    }

    // MARK: - Browse Nearby Sessions

    func startBrowsing() {
        stopBrowsing()

        browser = MCNearbyServiceBrowser(peer: peerId, serviceType: serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
    }

    func stopBrowsing() {
        browser?.stopBrowsingForPeers()
        browser = nil
        nearbySessions = []
    }

    // MARK: - Join a Session

    func joinSession(_ groupSession: GroupRitual, hostPeerId: MCPeerID) async -> Bool {
        stopAll()

        role = .participant

        guard let mcSession = mcSession else { return false }

        browser?.invitePeer(hostPeerId, to: mcSession, withContext: groupSession.id.data(using: .utf8), timeout: 30)

        // Optimistically set the session
        var joinedSession = groupSession
        let selfParticipant = Participant(
            peerId: peerId.displayName,
            displayName: peerId.displayName,
            isHost: false
        )
        joinedSession = GroupRitual(
            id: groupSession.id,
            title: groupSession.title,
            hostPeerId: groupSession.hostPeerId,
            participants: groupSession.participants + [selfParticipant],
            breathingPattern: groupSession.breathingPattern,
            durationMinutes: groupSession.durationMinutes,
            scheduledAt: groupSession.scheduledAt,
            isActive: groupSession.isActive,
            createdAt: groupSession.createdAt
        )
        session = joinedSession
        isConnected = true
        return true
    }

    // MARK: - Leave Session

    func leaveSession() {
        sendMessage(["type": "leave", "peerId": peerId.displayName])
        stopAll()
    }

    private func stopAll() {
        stopBrowsing()
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
        mcSession.disconnect()
        session = nil
        participants = []
        role = nil
        isConnected = false
        breathingState = nil
        stopStateTimer()
    }

    // MARK: - Start Group Breathing

    func startBreathing() {
        guard role == .host else { return }

        phaseIndex = 0
        loopCount = 0
        let now = Date()

        breathingState = GroupBreathingState(
            sessionId: session?.id ?? "",
            hostPeerId: peerId.displayName,
            pattern: session?.breathingPattern ?? .box,
            currentPhaseIndex: 0,
            phaseStartTime: now,
            loopCount: 0,
            isRunning: true,
            participantCount: participants.count
        )

        broadcastState()
        startStateTimer()
    }

    func stopBreathing() {
        stopStateTimer()
        breathingState?.isRunning = false
        broadcastState()
    }

    private func startStateTimer() {
        stateTimer?.invalidate()
        stateTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tickState()
            }
        }
    }

    private func stopStateTimer() {
        stateTimer?.invalidate()
        stateTimer = nil
    }

    private func tickState() {
        guard var state = breathingState, state.isRunning else { return }

        let elapsed = Date().timeIntervalSince(state.phaseStartTime)
        let phases = state.pattern.phases
        let currentPhaseDuration = phases.isEmpty ? 4.0 : phases[state.currentPhaseIndex].duration

        if elapsed >= currentPhaseDuration {
            // Advance to next phase
            phaseIndex += 1
            if phaseIndex >= phases.count {
                phaseIndex = 0
                loopCount += 1
            }

            state.currentPhaseIndex = phaseIndex
            state.phaseStartTime = Date()
            state.loopCount = loopCount
            breathingState = state

            broadcastState()
        }
    }

    // MARK: - Network Messaging

    private func broadcastState() {
        guard let state = breathingState,
              let data = try? JSONEncoder().encode(state) else { return }

        let message: [String: Any] = [
            "type": "breathingState",
            "state": data
        ]
        sendMessage(message)
    }

    private func sendMessage(_ message: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: message),
              !mcSession.connectedPeers.isEmpty else { return }

        do {
            try mcSession.send(data, toPeers: mcSession.connectedPeers, with: .reliable)
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func handleMessage(_ data: Data, from peer: MCPeerID) {
        guard let message = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = message["type"] as? String else { return }

        switch type {
        case "breathingState":
            if let stateData = message["state"] as? Data,
               let state = try? JSONDecoder().decode(GroupBreathingState.self, from: stateData) {
                breathingState = state
            }

        case "participantJoin":
            if let participantData = message["participant"] as? Data,
               let participant = try? JSONDecoder().decode(Participant.self, from: participantData) {
                if !participants.contains(where: { $0.peerId == participant.peerId }) {
                    participants.append(participant)
                    session?.participants = participants
                }
            }

        case "participantLeave":
            if let peerId = message["peerId"] as? String {
                participants.removeAll { $0.peerId == peerId }
                session?.participants = participants
            }

        case "sessionUpdate":
            if let sessionData = message["session"] as? Data,
               let updatedSession = try? JSONDecoder().decode(GroupRitual.self, from: sessionData) {
                session = updatedSession
            }

        default:
            break
        }
    }
}

// MARK: - MCSessionDelegate

extension GroupBreathingService: MCSessionDelegate {
    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        let peerName = peerID.displayName
        Task { @MainActor in
            switch state {
            case .connected:
                isConnected = true
                // Send participant join message
                let selfParticipant = Participant(peerId: peerId.displayName, displayName: peerId.displayName, isHost: role == .host)
                if let data = try? JSONEncoder().encode(selfParticipant) {
                    sendMessage(["type": "participantJoin", "participant": data])
                }

            case .notConnected:
                // Remove participant
                participants.removeAll { $0.peerId == peerName }
                if participants.isEmpty && role == .participant {
                    leaveSession()
                }

            case .connecting:
                break

            @unknown default:
                break
            }
        }
    }

    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        let capturedData = data
        let peerName = peerID.displayName
        Task { @MainActor in
            handleMessage(capturedData, from: MCPeerID(displayName: peerName))
        }
    }

    nonisolated func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}

    nonisolated func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}

    nonisolated func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension GroupBreathingService: MCNearbyServiceAdvertiserDelegate {
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        let capturedSession = mcSession
        // Accept the invitation synchronously on the current thread
        invitationHandler(true, capturedSession)
    }

    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        Task { @MainActor in
            self.error = "Failed to advertise: \(error.localizedDescription)"
        }
    }
}

// MARK: - MCNearbyServiceBrowserDelegate

extension GroupBreathingService: MCNearbyServiceBrowserDelegate {
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        let sessionId = info?["sessionId"] ?? UUID().uuidString
        let title = info?["title"] ?? peerID.displayName
        let patternRaw = info?["pattern"] ?? "Box"
        let duration = Int(info?["duration"] ?? "5") ?? 5
        let hostPeerName = peerID.displayName

        Task { @MainActor in
            let pattern = BreathingPattern(rawValue: patternRaw) ?? .box

            let nearbySession = GroupRitual(
                id: sessionId,
                title: title,
                hostPeerId: hostPeerName,
                participants: [],
                breathingPattern: pattern,
                durationMinutes: duration
            )

            if !nearbySessions.contains(where: { $0.id == sessionId }) {
                nearbySessions.append(nearbySession)
            }
        }
    }

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        let peerName = peerID.displayName
        Task { @MainActor in
            nearbySessions.removeAll { $0.hostPeerId == peerName }
        }
    }

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        Task { @MainActor in
            self.error = "Failed to browse: \(error.localizedDescription)"
        }
    }
}
