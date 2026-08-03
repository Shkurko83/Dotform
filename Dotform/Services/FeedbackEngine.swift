import Foundation

enum SpatialRegion {
    case left, right, top, middle, bottom
}

/// Протокол движка обратной связи — позволяет переключать audio-first и haptic-first режимы.
protocol FeedbackEngine: AnyObject {
    func filledDotFeedback(settings: AppSettings)
    func emptyDotFeedback(settings: AppSettings)
    func successFeedback(settings: AppSettings)
    func errorFeedback(settings: AppSettings)
    func lessonStartFeedback(settings: AppSettings)
    func shortSignal(settings: AppSettings)
    func longSignal(settings: AppSettings)
    func softHaptic(settings: AppSettings)
    func strongHaptic(settings: AppSettings)
    func regionFeedback(_ region: SpatialRegion, settings: AppSettings)
    func modelHandSequence(dots: [BrailleDot], settings: AppSettings, completion: @escaping () -> Void)
}

/// Заготовка для будущего Morse/sonification-кодирования.
protocol TemporalEncodingFeedback: AnyObject {
    func encodeDot(_ dot: BrailleDot, filled: Bool, settings: AppSettings)
    func encodeLetter(_ letter: BrailleLetter, settings: AppSettings)
}

@MainActor
final class CompositeFeedbackEngine: FeedbackEngine {
    private let audio: AudioFeedbackEngine
    private let haptic: HapticFeedbackEngine

    init(audio: AudioFeedbackEngine? = nil, haptic: HapticFeedbackEngine? = nil) {
        self.audio = audio ?? AudioFeedbackEngine()
        self.haptic = haptic ?? HapticFeedbackEngine()
    }

    func filledDotFeedback(settings: AppSettings) {
        switch settings.feedbackMode {
        case .audioFirst:
            audio.filledDotFeedback(settings: settings)
            if settings.hapticEnabled { haptic.filledDotFeedback(settings: settings) }
        case .hapticFirst:
            haptic.filledDotFeedback(settings: settings)
            if settings.parallelSoundForResidualHearing { audio.filledDotFeedback(settings: settings) }
        }
    }

    func emptyDotFeedback(settings: AppSettings) {
        switch settings.feedbackMode {
        case .audioFirst:
            audio.emptyDotFeedback(settings: settings)
            if settings.hapticEnabled { haptic.emptyDotFeedback(settings: settings) }
        case .hapticFirst:
            haptic.emptyDotFeedback(settings: settings)
            if settings.parallelSoundForResidualHearing { audio.emptyDotFeedback(settings: settings) }
        }
    }

    func successFeedback(settings: AppSettings) {
        switch settings.feedbackMode {
        case .audioFirst:
            audio.successFeedback(settings: settings)
            if settings.hapticEnabled { haptic.successFeedback(settings: settings) }
        case .hapticFirst:
            haptic.successFeedback(settings: settings)
            if settings.parallelSoundForResidualHearing { audio.successFeedback(settings: settings) }
        }
    }

    func errorFeedback(settings: AppSettings) {
        switch settings.feedbackMode {
        case .audioFirst:
            audio.errorFeedback(settings: settings)
            if settings.hapticEnabled { haptic.errorFeedback(settings: settings) }
        case .hapticFirst:
            if settings.errorSensitivity == .soft {
                haptic.emptyDotFeedback(settings: settings)
            } else {
                haptic.errorFeedback(settings: settings)
            }
            if settings.parallelSoundForResidualHearing { audio.errorFeedback(settings: settings) }
        }
    }

    func lessonStartFeedback(settings: AppSettings) {
        switch settings.feedbackMode {
        case .audioFirst:
            audio.lessonStartFeedback(settings: settings)
            if settings.hapticEnabled { haptic.lessonStartFeedback(settings: settings) }
        case .hapticFirst:
            haptic.lessonStartFeedback(settings: settings)
        }
    }

    func shortSignal(settings: AppSettings) {
        audio.shortSignal(settings: settings)
        if settings.hapticEnabled { haptic.shortSignal(settings: settings) }
    }

    func longSignal(settings: AppSettings) {
        audio.longSignal(settings: settings)
        if settings.hapticEnabled { haptic.longSignal(settings: settings) }
    }

    func softHaptic(settings: AppSettings) {
        if settings.feedbackMode == .hapticFirst || settings.hapticEnabled {
            haptic.softHaptic(settings: settings)
        }
    }

    func strongHaptic(settings: AppSettings) {
        if settings.feedbackMode == .hapticFirst || settings.hapticEnabled {
            haptic.strongHaptic(settings: settings)
        }
    }

    func regionFeedback(_ region: SpatialRegion, settings: AppSettings) {
        audio.regionFeedback(region, settings: settings)
        if settings.hapticEnabled {
            haptic.regionFeedback(region, settings: settings)
        }
    }

    func modelHandSequence(dots: [BrailleDot], settings: AppSettings, completion: @escaping () -> Void) {
        haptic.modelHandSequence(dots: dots, settings: settings, completion: completion)
    }
}
