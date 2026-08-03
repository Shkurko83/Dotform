import Foundation

/// Обратная связь с учётом профиля: слепоглухой — только вибрация, незрячий слышащий — звук и вибрация.
@MainActor
final class BlindFeedback {
    private let speech: SpeechService
    private let tones = TonePlayer.shared
    private let haptic = HapticFeedbackEngine()

    init(speech: SpeechService) {
        self.speech = speech
    }

    func filledDot(context: FeedbackContext) {
        if context.usesAudio {
            tones.play(
                frequency: FeedbackTone.filledDot.frequency,
                duration: FeedbackTone.filledDot.duration * Double(context.settings.signalDuration + 0.5),
                volume: context.settings.auxiliarySoundVolume
            )
        }
        if context.usesHaptic {
            haptic.filledDotFeedback(settings: context.settings)
        }
        if context.usesSpeech, context.settings.spokenZoneFeedback {
            speech.speakShort("Точка", settings: context.settings)
        }
    }

    func emptyDot(context: FeedbackContext) {
        // Пустые поля в уроках с точками — полная тишина, без вибрации.
    }

    func success(context: FeedbackContext) {
        if context.usesAudio { playTone(.success, settings: context.settings) }
        if context.usesHaptic { haptic.successFeedback(settings: context.settings) }
        if context.usesSpeech { speech.speakShort("Верно", settings: context.settings) }
    }

    func error(context: FeedbackContext) {
        if context.usesAudio { playTone(.error, settings: context.settings) }
        if context.usesHaptic { haptic.errorFeedback(settings: context.settings) }
        if context.usesSpeech { speech.speakShort("Попробуй ещё", settings: context.settings) }
    }

    func lessonStart(context: FeedbackContext) {
        if context.usesAudio { playTone(.lessonStart, settings: context.settings) }
        if context.usesHaptic { haptic.lessonStartFeedback(settings: context.settings) }
    }

    func region(_ region: SpatialRegion, context: FeedbackContext) {
        if context.usesAudio {
            playTone(tone(for: region), settings: context.settings)
        }
        if context.usesHaptic {
            haptic.regionFeedback(region, settings: context.settings)
        }
        if context.usesSpeech, context.settings.spokenZoneFeedback {
            speech.speakShort(region.spokenName, settings: context.settings)
        }
    }

    func shortPulse(context: FeedbackContext) {
        if context.usesAudio { playTone(.shortPulse, settings: context.settings) }
        if context.usesHaptic { haptic.shortSignal(settings: context.settings) }
        if context.usesSpeech, context.settings.spokenZoneFeedback {
            speech.speakShort("Короткий", settings: context.settings)
        }
    }

    func longPulse(context: FeedbackContext) {
        if context.usesAudio { playTone(.longPulse, settings: context.settings) }
        if context.usesHaptic { haptic.longSignal(settings: context.settings) }
        if context.usesSpeech, context.settings.spokenZoneFeedback {
            speech.speakShort("Длинный", settings: context.settings)
        }
    }

    func softPulse(context: FeedbackContext) {
        if context.usesAudio { playTone(.regionTop, settings: context.settings) }
        if context.usesHaptic { haptic.regionFeedback(.top, settings: context.settings) }
        if context.usesSpeech, context.settings.spokenZoneFeedback {
            speech.speakShort("Мягко", settings: context.settings)
        }
    }

    func strongPulse(context: FeedbackContext) {
        if context.usesAudio { playTone(.regionBottom, settings: context.settings) }
        if context.usesHaptic { haptic.regionFeedback(.bottom, settings: context.settings) }
        if context.usesSpeech, context.settings.spokenZoneFeedback {
            speech.speakShort("Сильно", settings: context.settings)
        }
    }

    func speak(_ text: String, context: FeedbackContext, completion: (() -> Void)? = nil) {
        guard context.usesSpeech else {
            if context.usesHaptic { haptic.lessonStartFeedback(settings: context.settings) }
            completion?()
            return
        }
        speech.speak(text, settings: context.settings, completion: completion)
    }

    private func tone(for region: SpatialRegion) -> FeedbackTone {
        switch region {
        case .left: return .regionLeft
        case .right: return .regionRight
        case .top: return .regionTop
        case .middle: return .regionMiddle
        case .bottom: return .regionBottom
        }
    }

    private func playTone(_ tone: FeedbackTone, settings: AppSettings) {
        tones.play(
            frequency: tone.frequency,
            duration: tone.duration * Double(settings.signalDuration + 0.5),
            volume: settings.auxiliarySoundVolume * tone.volumeMultiplier
        )
    }
}
