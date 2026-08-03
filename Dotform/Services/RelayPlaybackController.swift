import Foundation
import Combine

@MainActor
final class RelayPlaybackController: ObservableObject {
    @Published private(set) var currentGlyph: BrailleGlyph?
    @Published private(set) var isPlaying = false
    @Published private(set) var progressIndex = 0
    @Published private(set) var totalCount = 0
    @Published var statusMessage: String?

    private var queue: [RelayToken] = []
    private var cancelled = false
    private let watchBridge = WatchConnectivityBridge.shared

    func stop() {
        cancelled = true
        isPlaying = false
        currentGlyph = nil
        queue = []
    }

    func play(
        text: String,
        scriptID: BrailleScriptID,
        settings: AppSettings,
        feedback: CompositeFeedbackEngine
    ) {
        stop()
        cancelled = false
        let tokens = TextToHapticEncoder.tokenize(text, scriptID: scriptID)
        queue = tokens
        totalCount = tokens.count
        progressIndex = 0
        isPlaying = true
        statusMessage = nil
        playNext(settings: settings, feedback: feedback)
    }

    private func playNext(settings: AppSettings, feedback: CompositeFeedbackEngine) {
        guard !cancelled else { return }
        guard progressIndex < queue.count else {
            isPlaying = false
            currentGlyph = nil
            statusMessage = "Готово"
            return
        }

        let token = queue[progressIndex]
        progressIndex += 1

        switch token {
        case .space:
            currentGlyph = nil
            scheduleAfter(settings.instructionPauseDuration * 0.5, settings: settings, feedback: feedback)

        case .unknown:
            currentGlyph = nil
            feedback.errorFeedback(settings: settings)
            watchBridge.sendErrorPulse()
            scheduleAfter(0.35, settings: settings, feedback: feedback)

        case .glyph(let glyph):
            currentGlyph = glyph
            deliver(glyph: glyph, settings: settings, feedback: feedback)
        }
    }

    private func deliver(glyph: BrailleGlyph, settings: AppSettings, feedback: CompositeFeedbackEngine) {
        let pause = max(settings.instructionPauseDuration * 0.35, 0.4)

        if glyph.kind == .space || glyph.dots.isEmpty {
            scheduleAfter(pause, settings: settings, feedback: feedback)
            return
        }

        watchBridge.sendGlyph(
            glyph,
            settings: settings,
            playDotsInSequence: settings.relayPlayDotsInSequence
        )

        if settings.relayPlayDotsInSequence, !glyph.dots.isEmpty {
            feedback.modelHandSequence(dots: Array(glyph.dots).sorted { $0.rawValue < $1.rawValue }, settings: settings) { [weak self] in
                Task { @MainActor in
                    self?.playRelayAck(settings: settings, feedback: feedback)
                    self?.scheduleAfter(pause, settings: settings, feedback: feedback)
                }
            }
        } else {
            playRelayAck(settings: settings, feedback: feedback)
            scheduleAfter(pause, settings: settings, feedback: feedback)
        }
    }

    private func playRelayAck(settings: AppSettings, feedback: CompositeFeedbackEngine) {
        if settings.hapticSelections[SensoryFeedbackRole.relayGlyph.rawValue] != nil
            || settings.customHapticByRole[SensoryFeedbackRole.relayGlyph.rawValue] != nil {
            let itemID = settings.hapticSelections[SensoryFeedbackRole.relayGlyph.rawValue]
            if itemID == CustomHapticDefinition.catalogItemID,
               let custom = settings.customHapticByRole[SensoryFeedbackRole.relayGlyph.rawValue] {
                SensoryCatalogPlayer.shared.playCustomHaptic(custom, scale: settings.hapticIntensity)
            } else {
                SensoryCatalogPlayer.shared.playHapticSelection(itemID, hapticIntensity: settings.hapticIntensity)
            }
        } else {
            feedback.filledDotFeedback(settings: settings)
        }
    }

    private func scheduleAfter(_ delay: TimeInterval, settings: AppSettings, feedback: CompositeFeedbackEngine) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.playNext(settings: settings, feedback: feedback)
        }
    }
}
