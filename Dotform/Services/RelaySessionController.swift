import MultipeerConnectivity
import UIKit
import Combine

@MainActor
final class RelaySessionController: NSObject, ObservableObject {
    enum ConnectionState: Equatable {
        case idle
        case advertising
        case browsing
        case connecting
        case connected(peerName: String)
        case failed(String)
    }

    @Published private(set) var connectionState: ConnectionState = .idle
    @Published private(set) var lastIncoming: RelayEnvelope?
    @Published private(set) var lastError: String?
    @Published private(set) var pairingPayload: RelayPairingPayload?

    private let myPeerID: MCPeerID
    private var session: MCSession
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    private var sessionToken: String = UUID().uuidString
    private var expectedSessionToken: String?

    private let serviceType = RelayPairingPayload.bonjourService

    override init() {
        let name = UIDevice.current.name
        myPeerID = MCPeerID(displayName: String(name.prefix(20)))
        session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        super.init()
        session.delegate = self
    }

    var isConnected: Bool {
        if case .connected = connectionState { return true }
        return false
    }

    func startAsReceiver(displayName: String) {
        stop()
        sessionToken = UUID().uuidString
        pairingPayload = RelayPairingPayload(
            session: sessionToken,
            peer: displayName,
            service: serviceType
        )
        let discovery: [String: String] = ["session": sessionToken]
        advertiser = MCNearbyServiceAdvertiser(
            peer: myPeerID,
            discoveryInfo: discovery,
            serviceType: serviceType
        )
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
        connectionState = .advertising
    }

    func startAsWriter(pairing: RelayPairingPayload) {
        stop()
        expectedSessionToken = pairing.session
        pairingPayload = pairing
        browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: pairing.service)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
        connectionState = .browsing
    }

    func stop() {
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
        browser?.stopBrowsingForPeers()
        browser = nil
        session.disconnect()
        reconnectSession()
        connectionState = .idle
        pairingPayload = nil
        expectedSessionToken = nil
    }

    func send(_ envelope: RelayEnvelope) {
        guard !session.connectedPeers.isEmpty, let data = envelope.encoded() else {
            lastError = "Нет подключённого устройства"
            return
        }
        do {
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
        } catch {
            lastError = error.localizedDescription
            connectionState = .failed(error.localizedDescription)
        }
    }

    private func reconnectSession() {
        session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
    }

    private func handleIncoming(_ data: Data) {
        guard let envelope = RelayEnvelope.decode(from: data) else { return }
        lastIncoming = envelope
    }
}

extension RelaySessionController: MCSessionDelegate {
    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        Task { @MainActor in
            switch state {
            case .connected:
                connectionState = .connected(peerName: peerID.displayName)
                advertiser?.stopAdvertisingPeer()
                browser?.stopBrowsingForPeers()
            case .connecting:
                connectionState = .connecting
            case .notConnected:
                if case .connected = connectionState {
                    connectionState = .failed("Соединение разорвано")
                }
            @unknown default:
                break
            }
        }
    }

    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        Task { @MainActor in
            handleIncoming(data)
        }
    }

    nonisolated func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    nonisolated func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    nonisolated func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

extension RelaySessionController: MCNearbyServiceAdvertiserDelegate {
    nonisolated func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?,
        invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {
        Task { @MainActor in
            invitationHandler(true, self.session)
        }
    }

    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        Task { @MainActor in
            lastError = error.localizedDescription
            connectionState = .failed(error.localizedDescription)
        }
    }
}

extension RelaySessionController: MCNearbyServiceBrowserDelegate {
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        Task { @MainActor in
            guard let expected = expectedSessionToken else { return }
            guard info?["session"] == expected else { return }
            connectionState = .connecting
            browser.invitePeer(peerID, to: session, withContext: nil, timeout: 20)
        }
    }

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        Task { @MainActor in
            lastError = error.localizedDescription
            connectionState = .failed(error.localizedDescription)
        }
    }
}
