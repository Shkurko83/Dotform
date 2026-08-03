import Combine
import Foundation
import WatchConnectivity

@MainActor
final class WatchConnectivityBridge: NSObject, ObservableObject {
    static let shared = WatchConnectivityBridge()

    @Published private(set) var isWatchReachable = false

    private override init() {
        super.init()
        activate()
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    func sendGlyph(_ glyph: BrailleGlyph, settings: AppSettings, playDotsInSequence: Bool) {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated else { return }

        let custom = settings.customHapticByRole[SensoryFeedbackRole.relayGlyph.rawValue]
            ?? settings.customHapticByRole[SensoryFeedbackRole.filledDot.rawValue]
            ?? CustomHapticDefinition()

        let payload = WatchGlyphPayload(
            glyphID: glyph.id,
            display: glyph.display,
            dots: glyph.dots.map(\.rawValue).sorted(),
            intensity: custom.intensity * settings.hapticIntensity,
            sharpness: custom.sharpness,
            duration: custom.kind == .continuous ? custom.duration : 0.12,
            kind: custom.kind.rawValue,
            playDotsInSequence: playDotsInSequence
        )

        guard let data = try? JSONEncoder().encode(payload),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return }

        let message: [String: Any] = ["type": "glyph", "payload": json]

        if session.isReachable {
            session.sendMessage(message, replyHandler: nil) { _ in
                try? session.updateApplicationContext(message)
            }
        } else {
            try? session.updateApplicationContext(message)
        }
    }

    func sendErrorPulse() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated, session.isReachable else { return }
        session.sendMessage(["type": "error"], replyHandler: nil, errorHandler: nil)
    }
}

extension WatchConnectivityBridge: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor in
            isWatchReachable = session.isReachable
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            isWatchReachable = session.isReachable
        }
    }

    #if os(iOS)
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif
}
