import Combine
import Foundation
import WatchConnectivity
import WatchKit

@MainActor
final class WatchRelayReceiver: NSObject, ObservableObject {
    @Published var currentDisplay: String?
    @Published var currentDots: Set<Int> = []

    override init() {
        super.init()
        activate()
    }

    private func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    private func handle(message: [String: Any]) {
        let type = message["type"] as? String
        if type == "error" {
            WKInterfaceDevice.current().play(.failure)
            return
        }

        guard type == "glyph",
              let payload = message["payload"] as? [String: Any]
        else { return }

        let display = payload["display"] as? String ?? "?"
        let dots = Set((payload["dots"] as? [Int]) ?? [])
        let intensity = payload["intensity"] as? Float ?? 0.8
        let duration = payload["duration"] as? Float ?? 0.12
        let kind = payload["kind"] as? String ?? "transient"
        let sequence = payload["playDotsInSequence"] as? Bool ?? false

        currentDisplay = display
        currentDots = dots

        if sequence, !dots.isEmpty {
            playSequence(dots: dots.sorted())
        } else {
            playHaptic(kind: kind, intensity: intensity, duration: duration)
        }
    }

    private func playHaptic(kind: String, intensity: Float, duration: Float) {
        let type: WKHapticType
        if kind == "continuous" || duration > 0.2 {
            type = intensity > 0.7 ? .notification : .click
        } else if intensity < 0.4 {
            type = .click
        } else if intensity > 0.85 {
            type = .directionUp
        } else {
            type = .success
        }
        WKInterfaceDevice.current().play(type)
    }

    private func playSequence(dots: [Int]) {
        for (index, _) in dots.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.35) {
                WKInterfaceDevice.current().play(.click)
            }
        }
    }
}

extension WatchRelayReceiver: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {}

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            handle(message: message)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor in
            handle(message: applicationContext)
        }
    }
}
