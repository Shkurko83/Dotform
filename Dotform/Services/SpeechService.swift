import AVFoundation
import Combine
import UIKit

@MainActor
final class SpeechService: NSObject, ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()
    @Published private(set) var isSpeaking = false

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ text: String, settings: AppSettings, completion: (() -> Void)? = nil) {
        stop()
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: settings.language.rawValue)
        utterance.rate = settings.speechRate
        utterance.volume = settings.auxiliarySoundVolume
        synthesizer.speak(utterance)
        if let completion {
            DispatchQueue.main.asyncAfter(deadline: .now() + estimatedDuration(for: text, rate: settings.speechRate)) {
                completion()
            }
        }
    }

    /// Короткая озвучка зоны — прерывает предыдущую фразу.
    func speakShort(_ text: String, settings: AppSettings) {
        stop()
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: settings.language.rawValue)
        utterance.rate = min(settings.speechRate + 0.12, 0.62)
        utterance.volume = settings.auxiliarySoundVolume
        utterance.preUtteranceDelay = 0
        utterance.postUtteranceDelay = 0
        synthesizer.speak(utterance)
    }

    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }

    private func estimatedDuration(for text: String, rate: Float) -> TimeInterval {
        let base = Double(text.count) * 0.08
        let adjusted = base / Double(max(rate, 0.1))
        return min(max(adjusted, 0.5), 8.0)
    }
}

extension SpeechService: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in isSpeaking = true }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in isSpeaking = false }
    }
}

@MainActor
final class AudioFeedbackEngine: FeedbackEngine {
    private let tones = TonePlayer.shared
    private let catalogPlayer = SensoryCatalogPlayer.shared

    func speak(_ text: String, settings: AppSettings) {
        SpeechService().speak(text, settings: settings)
    }

    func filledDotFeedback(settings: AppSettings) {
        play(role: .filledDot, tone: .filledDot, settings: settings)
    }

    func emptyDotFeedback(settings: AppSettings) {
        play(role: .emptyDot, tone: .emptyDot, settings: settings)
    }

    func successFeedback(settings: AppSettings) {
        play(role: .success, tone: .success, settings: settings)
    }

    func errorFeedback(settings: AppSettings) {
        play(role: .error, tone: .error, settings: settings)
    }

    func lessonStartFeedback(settings: AppSettings) {
        play(role: .lessonStart, tone: .lessonStart, settings: settings)
    }

    func shortSignal(settings: AppSettings) {
        play(role: .shortSignal, tone: .shortPulse, settings: settings)
    }

    func longSignal(settings: AppSettings) {
        play(role: .longSignal, tone: .longPulse, settings: settings)
    }

    func regionFeedback(_ region: SpatialRegion, settings: AppSettings) {
        let role = SensoryFeedbackRole.from(region)
        let tone: FeedbackTone
        switch region {
        case .left: tone = .regionLeft
        case .right: tone = .regionRight
        case .top: tone = .regionTop
        case .middle: tone = .regionMiddle
        case .bottom: tone = .regionBottom
        }
        play(role: role, tone: tone, settings: settings)
    }

    func softHaptic(settings: AppSettings) {}
    func strongHaptic(settings: AppSettings) {}

    func modelHandSequence(dots: [BrailleDot], settings: AppSettings, completion: @escaping () -> Void) {
        completion()
    }

    private func play(role: SensoryFeedbackRole, tone: FeedbackTone, settings: AppSettings) {
        if let itemID = settings.soundSelections[role.rawValue] {
            catalogPlayer.playSoundSelection(itemID, volume: settings.auxiliarySoundVolume)
            return
        }
        playTone(tone, settings: settings)
    }

    private func playTone(_ tone: FeedbackTone, settings: AppSettings) {
        tones.play(
            frequency: tone.frequency,
            duration: tone.duration * Double(settings.signalDuration + 0.7),
            volume: settings.auxiliarySoundVolume * tone.volumeMultiplier
        )
    }
}
