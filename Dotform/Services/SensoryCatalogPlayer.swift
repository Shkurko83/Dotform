import AudioToolbox
import CoreHaptics
import UIKit

@MainActor
final class SensoryCatalogPlayer {
    static let shared = SensoryCatalogPlayer()

    private var impactGenerators: [String: UIImpactFeedbackGenerator] = [:]
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private var hapticEngine: CHHapticEngine?
    private var supportsCoreHaptics = false

    private init() {
        prepareCoreHaptics()
    }

    func play(_ item: SensoryCatalogItem, volume: Float = 0.8, hapticIntensity: Float = 1.0) {
        switch item.payload {
        case let .impact(style, intensity):
            playImpact(style: style, intensity: intensity, scale: hapticIntensity)
        case let .notification(type):
            playNotification(type: type)
        case .selection:
            selectionGenerator.prepare()
            selectionGenerator.selectionChanged()
        case let .systemVibrate(variant):
            playSystemVibrate(variant)
        case let .coreHaptic(pattern):
            playCoreHaptic(pattern, intensity: hapticIntensity)
        case let .appTone(toneID):
            let tone = FeedbackTone.from(catalogID: toneID)
            TonePlayer.shared.play(
                frequency: tone.frequency,
                duration: tone.duration,
                volume: volume * tone.volumeMultiplier
            )
        case let .synthesizedTone(frequency, duration):
            TonePlayer.shared.play(frequency: frequency, duration: duration, volume: volume)
        case let .systemSound(id, vibrate):
            if vibrate {
                AudioServicesPlayAlertSound(id)
            } else {
                AudioServicesPlaySystemSound(id)
            }
        }
    }

    func playHapticSelection(_ itemID: String?, volume: Float = 0.8, hapticIntensity: Float = 1.0) {
        guard let itemID, let item = SensoryCatalog.haptics.first(where: { $0.id == itemID }) else { return }
        play(item, volume: volume, hapticIntensity: hapticIntensity)
    }

    func playSoundSelection(_ itemID: String?, volume: Float = 0.8) {
        guard let itemID, let item = SensoryCatalog.sounds.first(where: { $0.id == itemID }) else { return }
        play(item, volume: volume)
    }

    func playCustomHaptic(_ definition: CustomHapticDefinition, scale: Float = 1.0) {
        guard supportsCoreHaptics, let engine = hapticEngine else {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            return
        }

        let events = customHapticEvents(from: definition, scale: scale)
        guard !events.isEmpty else { return }

        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        }
    }

    // MARK: - UIKit

    private func playSystemVibrate(_ variant: SensoryCatalogItem.SensoryPayload.SystemVibrateVariant) {
        switch variant {
        case .standardPlaySystemSound:
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        case .standardPlayAlertSound:
            AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
        case .smsVibrate1011:
            AudioServicesPlaySystemSound(1011)
        case .smsVibrate1311:
            AudioServicesPlaySystemSound(1311)
        case .vibrateAlways1352:
            AudioServicesPlaySystemSound(1352)
        }
    }

    private func playImpact(
        style: SensoryCatalogItem.SensoryPayload.ImpactStyle,
        intensity: Float?,
        scale: Float
    ) {
        let key = style.rawValue
        let generator: UIImpactFeedbackGenerator
        if let cached = impactGenerators[key] {
            generator = cached
        } else {
            let created = UIImpactFeedbackGenerator(style: uiImpactStyle(style))
            impactGenerators[key] = created
            generator = created
        }

        generator.prepare()
        if let intensity {
            let scaled = CGFloat(min(max(intensity * scale, 0.1), 1))
            generator.impactOccurred(intensity: scaled)
        } else {
            generator.impactOccurred()
        }
    }

    private func playNotification(type: SensoryCatalogItem.SensoryPayload.NotificationType) {
        notificationGenerator.prepare()
        switch type {
        case .success: notificationGenerator.notificationOccurred(.success)
        case .warning: notificationGenerator.notificationOccurred(.warning)
        case .error: notificationGenerator.notificationOccurred(.error)
        }
    }

    private func uiImpactStyle(_ style: SensoryCatalogItem.SensoryPayload.ImpactStyle) -> UIImpactFeedbackGenerator.FeedbackStyle {
        switch style {
        case .light: return .light
        case .medium: return .medium
        case .heavy: return .heavy
        case .soft: return .soft
        case .rigid: return .rigid
        }
    }

    // MARK: - Core Haptics

    private func prepareCoreHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            let engine = try CHHapticEngine()
            engine.resetHandler = { [weak self] in
                try? self?.hapticEngine?.start()
            }
            engine.stoppedHandler = { _ in }
            try engine.start()
            hapticEngine = engine
            supportsCoreHaptics = true
        } catch {
            supportsCoreHaptics = false
        }
    }

    private func playCoreHaptic(_ pattern: SensoryCatalogItem.SensoryPayload.CoreHapticPatternID, intensity: Float) {
        guard supportsCoreHaptics, let engine = hapticEngine else {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            return
        }

        guard let events = coreHapticEvents(for: pattern, scale: intensity) else { return }

        do {
            let hapticPattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: hapticPattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        }
    }

    private func customHapticEvents(from definition: CustomHapticDefinition, scale: Float) -> [CHHapticEvent] {
        let i = Double(min(max(scale * definition.intensity, 0.1), 1))
        let sharpness = Double(definition.sharpness)
        let count = max(definition.repeatCount, 1)

        switch definition.kind {
        case .transient:
            return (0..<count).map { index in
                let time = Double(index) * Double(definition.repeatInterval)
                return transient(intensity: i, sharpness: sharpness, at: time)
            }
        case .continuous:
            let attack = min(Double(definition.attack), Double(definition.duration) * 0.45)
            let decay = min(Double(definition.decay), Double(definition.duration) * 0.45)
            return [
                continuous(
                    intensity: i,
                    sharpness: sharpness,
                    at: 0,
                    duration: Double(definition.duration),
                    attack: attack,
                    release: decay
                )
            ]
        }
    }

    private func coreHapticEvents(
        for pattern: SensoryCatalogItem.SensoryPayload.CoreHapticPatternID,
        scale: Float
    ) -> [CHHapticEvent]? {
        let i = Double(min(max(scale, 0.15), 1))

        switch pattern {
        case .sharpTap:
            return [transient(intensity: 1.0 * i, sharpness: 1.0, at: 0)]
        case .softTap:
            return [transient(intensity: 0.35 * i, sharpness: 0.2, at: 0)]
        case .doubleTap:
            return [
                transient(intensity: 0.9 * i, sharpness: 0.8, at: 0),
                transient(intensity: 0.9 * i, sharpness: 0.8, at: 0.12)
            ]
        case .tripleTap:
            return [
                transient(intensity: 0.85 * i, sharpness: 0.75, at: 0),
                transient(intensity: 0.85 * i, sharpness: 0.75, at: 0.1),
                transient(intensity: 0.85 * i, sharpness: 0.75, at: 0.2)
            ]
        case .shortBuzz:
            return [continuous(intensity: 0.7 * i, sharpness: 0.3, at: 0, duration: 0.08)]
        case .mediumBuzz:
            return [continuous(intensity: 0.75 * i, sharpness: 0.35, at: 0, duration: 0.25)]
        case .longBuzz:
            return [continuous(intensity: 0.8 * i, sharpness: 0.4, at: 0, duration: 0.55)]
        case .heartbeat:
            return [
                transient(intensity: 0.95 * i, sharpness: 0.6, at: 0),
                transient(intensity: 0.7 * i, sharpness: 0.4, at: 0.14),
                transient(intensity: 0.95 * i, sharpness: 0.6, at: 0.45),
                transient(intensity: 0.7 * i, sharpness: 0.4, at: 0.58)
            ]
        case .crescendo:
            return (0..<5).map { index in
                let step = Double(index) * 0.08
                let level = 0.3 + Double(index) * 0.15
                return transient(intensity: level * i, sharpness: 0.5 + Double(index) * 0.1, at: step)
            }
        case .decrescendo:
            return (0..<5).map { index in
                let step = Double(index) * 0.08
                let level = 1.0 - Double(index) * 0.15
                return transient(intensity: level * i, sharpness: 0.9 - Double(index) * 0.1, at: step)
            }
        case .rampUp:
            return [continuous(intensity: 0.9 * i, sharpness: 0.5, at: 0, duration: 0.4, attack: 0.35, release: 0.05)]
        case .rampDown:
            return [continuous(intensity: 0.9 * i, sharpness: 0.5, at: 0, duration: 0.4, attack: 0.05, release: 0.35)]
        case .staccato:
            return (0..<6).map { index in
                transient(intensity: 0.8 * i, sharpness: 0.85, at: Double(index) * 0.07)
            }
        case .wave:
            return (0..<8).map { index in
                let level = 0.35 + abs(sin(Double(index) * .pi / 4)) * 0.55
                return transient(intensity: level * i, sharpness: 0.45, at: Double(index) * 0.09)
            }
        case .sosMorse:
            let dot = 0.08
            let dash = 0.22
            let gap = 0.08
            var time = 0.0
            var events: [CHHapticEvent] = []
            func addDot() {
                events.append(transient(intensity: 0.9 * i, sharpness: 0.8, at: time))
                time += dot + gap
            }
            func addDash() {
                events.append(continuous(intensity: 0.85 * i, sharpness: 0.6, at: time, duration: dash))
                time += dash + gap
            }
            // S
            addDot(); addDot(); addDot()
            time += gap
            // O
            addDash(); addDash(); addDash()
            time += gap
            // S
            addDot(); addDot(); addDot()
            return events
        }
    }

    private func transient(intensity: Double, sharpness: Double, at time: TimeInterval) -> CHHapticEvent {
        CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(intensity)),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: Float(sharpness))
            ],
            relativeTime: time
        )
    }

    private func continuous(
        intensity: Double,
        sharpness: Double,
        at time: TimeInterval,
        duration: TimeInterval,
        attack: TimeInterval = 0.02,
        release: TimeInterval = 0.02
    ) -> CHHapticEvent {
        CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(intensity)),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: Float(sharpness)),
                CHHapticEventParameter(parameterID: .attackTime, value: Float(attack)),
                CHHapticEventParameter(parameterID: .decayTime, value: Float(release))
            ],
            relativeTime: time,
            duration: duration
        )
    }
}
