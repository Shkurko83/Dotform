import UIKit

@MainActor
final class HapticFeedbackEngine: FeedbackEngine {
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let catalogPlayer = SensoryCatalogPlayer.shared

    init() {
        mediumImpact.prepare()
    }

    func filledDotFeedback(settings: AppSettings) {
        playCatalog(role: .filledDot, settings: settings) {
            pulse(intensity: 1.0, settings: settings)
        }
    }

    func emptyDotFeedback(settings: AppSettings) {}

    func successFeedback(settings: AppSettings) {
        playCatalog(role: .success, settings: settings) {
            pulse(intensity: 1.0, settings: settings)
        }
    }

    func errorFeedback(settings: AppSettings) {
        playCatalog(role: .error, settings: settings) {
            pulse(intensity: 0.45, settings: settings)
        }
    }

    func lessonStartFeedback(settings: AppSettings) {
        playCatalog(role: .lessonStart, settings: settings) {
            pulse(intensity: 0.7, settings: settings)
        }
    }

    func shortSignal(settings: AppSettings) {
        playCatalog(role: .shortSignal, settings: settings) {
            pulse(intensity: 0.55, settings: settings)
        }
    }

    func longSignal(settings: AppSettings) {
        playCatalog(role: .longSignal, settings: settings) {
            pulse(intensity: 1.0, settings: settings)
        }
    }

    func softHaptic(settings: AppSettings) {
        regionFeedback(.top, settings: settings)
    }

    func strongHaptic(settings: AppSettings) {
        regionFeedback(.bottom, settings: settings)
    }

    func regionFeedback(_ region: SpatialRegion, settings: AppSettings) {
        let role = SensoryFeedbackRole.from(region)
        playCatalog(role: role, settings: settings) {
            let intensity: Float
            switch region {
            case .left: intensity = 0.6
            case .right: intensity = 1.0
            case .top: intensity = 0.3
            case .middle: intensity = 0.6
            case .bottom: intensity = 1.0
            }
            pulse(intensity: intensity, settings: settings)
        }
    }

    func modelHandSequence(dots: [BrailleDot], settings: AppSettings, completion: @escaping () -> Void) {
        guard settings.hapticEnabled, !dots.isEmpty else {
            completion()
            return
        }

        let sortedDots = dots.sorted { $0.rawValue < $1.rawValue }
        let pause: TimeInterval = 0.6 + settings.instructionPauseDuration * 0.2

        func vibrate(at index: Int) {
            guard index < sortedDots.count else {
                completion()
                return
            }
            pulse(intensity: 1.0, settings: settings)
            DispatchQueue.main.asyncAfter(deadline: .now() + pause) {
                vibrate(at: index + 1)
            }
        }
        vibrate(at: 0)
    }

    private func pulse(intensity: Float, settings: AppSettings) {
        guard settings.hapticEnabled else { return }
        let scaled = settings.hapticIntensity * intensity
        mediumImpact.prepare()
        mediumImpact.impactOccurred(intensity: CGFloat(min(max(scaled, 0.15), 1)))
    }

    private func playCatalog(role: SensoryFeedbackRole, settings: AppSettings, fallback: () -> Void) {
        guard settings.hapticEnabled else { return }
        if let itemID = settings.hapticSelections[role.rawValue] {
            if itemID == CustomHapticDefinition.catalogItemID,
               let custom = settings.customHapticByRole[role.rawValue] {
                catalogPlayer.playCustomHaptic(custom, scale: settings.hapticIntensity)
            } else {
                catalogPlayer.playHapticSelection(itemID, hapticIntensity: settings.hapticIntensity)
            }
        } else {
            fallback()
        }
    }
}
