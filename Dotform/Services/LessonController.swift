import Foundation
import Observation

@MainActor
@Observable
final class LessonController {
    let letter: BrailleLetter
    let profile: UserProfile
    var settings: AppSettings

    private(set) var phase: LessonPhase = .entry
    private(set) var selectedDots: Set<BrailleDot> = []
    private(set) var foundDots: Set<BrailleDot> = []
    private(set) var instructionText: String = ""
    private(set) var canAdvance = false

    private let blindFeedback: BlindFeedback
    private let legacyFeedback: CompositeFeedbackEngine
    private var phaseStartTime = Date()

    private var context: FeedbackContext {
        FeedbackContext(settings: settings, profile: settings.childProfile)
    }

    private var isDeafBlindMode: Bool {
        settings.childProfile.isDeafBlind
    }

    init(
        letter: BrailleLetter,
        profile: UserProfile,
        settings: AppSettings,
        blindFeedback: BlindFeedback,
        feedback: CompositeFeedbackEngine? = nil
    ) {
        self.letter = letter
        self.profile = profile
        self.settings = settings
        self.blindFeedback = blindFeedback
        self.legacyFeedback = feedback ?? CompositeFeedbackEngine()
    }

    func startLesson() {
        phase = .entry
        selectedDots = []
        foundDots = []
        canAdvance = false
        phaseStartTime = Date()

        blindFeedback.lessonStart(context: context)

        let entryText: String
        switch settings.childProfile {
        case .blindChild, .parentTeacher:
            entryText = "Буква \(letter.character). Веди пальцем по экрану. Отклик будет только на точках буквы."
        case .deafBlindChild:
            entryText = ""
            if settings.modelHandEnabled {
                phase = .modelHand
                instructionText = "Модельная рука."
                runModelHand()
                return
            }
        }

        instructionText = entryText
        if entryText.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + settings.instructionPauseDuration) { [weak self] in
                self?.beginExploration()
            }
        } else {
            blindFeedback.speak(entryText, context: context) { [weak self] in
                Task { @MainActor in self?.beginExploration() }
            }
        }
    }

    private func runModelHand() {
        let sortedDots = letter.dots.sorted { $0.rawValue < $1.rawValue }
        legacyFeedback.modelHandSequence(dots: sortedDots, settings: settings) { [weak self] in
            Task { @MainActor in self?.beginExploration() }
        }
    }

    func repeatInstruction() {
        guard !instructionText.isEmpty else { return }
        blindFeedback.speak(instructionText, context: context)
    }

    private func beginExploration() {
        phase = .exploration
        phaseStartTime = Date()
        instructionText = "Исследуй букву \(letter.character)."
        if isDeafBlindMode {
            blindFeedback.lessonStart(context: context)
        } else {
            blindFeedback.speak(instructionText, context: context)
        }
        canAdvance = true
    }

    func handleDotTouch(_ dot: BrailleDot, isExploration: Bool) {
        guard isExploration else { return }
        if letter.dots.contains(dot) {
            blindFeedback.filledDot(context: context)
        } else {
            blindFeedback.emptyDot(context: context)
        }
    }

    func handleDotSelection(_ dot: BrailleDot) {
        switch phase {
        case .exploration, .modelHand, .entry:
            handleDotTouch(dot, isExploration: true)
        case .reinforcement:
            handleReinforcementTouch(dot)
        case .test:
            toggleDot(dot)
        case .result:
            break
        }
    }

    private func handleReinforcementTouch(_ dot: BrailleDot) {
        guard letter.dots.contains(dot) else {
            blindFeedback.emptyDot(context: context)
            return
        }
        guard !foundDots.contains(dot) else { return }

        foundDots.insert(dot)
        blindFeedback.filledDot(context: context)

        if foundDots == letter.dots {
            proceedToTest()
        }
    }

    func advanceFromExploration() {
        guard phase == .exploration else { return }
        phase = .reinforcement
        phaseStartTime = Date()
        foundDots = []
        instructionText = "Найди все точки буквы \(letter.character)."
        if isDeafBlindMode {
            blindFeedback.lessonStart(context: context)
        } else {
            blindFeedback.speak(instructionText, context: context)
        }
    }

    private func proceedToTest() {
        DispatchQueue.main.asyncAfter(deadline: .now() + settings.instructionPauseDuration) { [weak self] in
            guard let self else { return }
            self.phase = .test
            self.phaseStartTime = Date()
            self.selectedDots = []
            self.instructionText = "Поставь букву \(self.letter.character)."
            if self.profile.isDeafBlind {
                self.blindFeedback.lessonStart(context: self.context)
            } else {
                self.blindFeedback.speak(self.instructionText, context: self.context)
            }
        }
    }

    private func toggleDot(_ dot: BrailleDot) {
        if selectedDots.contains(dot) {
            selectedDots.remove(dot)
            blindFeedback.emptyDot(context: context)
        } else {
            selectedDots.insert(dot)
            blindFeedback.filledDot(context: context)
        }
    }

    func submitAnswer() -> Bool {
        guard phase == .test else { return false }
        let success = letter.matches(selection: selectedDots)
        phase = .result(success: success)
        let duration = Date().timeIntervalSince(phaseStartTime)

        if success {
            blindFeedback.success(context: context)
            if context.usesSpeech {
                blindFeedback.speak("Буква \(letter.character) верна.", context: context)
            }
        } else {
            blindFeedback.error(context: context)
            DispatchQueue.main.asyncAfter(deadline: .now() + settings.instructionPauseDuration) { [weak self] in
                guard let self else { return }
                self.phase = .test
                self.selectedDots = []
                self.phaseStartTime = Date()
                if self.context.usesSpeech {
                    self.blindFeedback.speak("Поставь букву \(self.letter.character).", context: self.context)
                } else {
                    self.blindFeedback.lessonStart(context: self.context)
                }
            }
        }

        _ = duration
        return success
    }

    func phaseDuration() -> TimeInterval {
        Date().timeIntervalSince(phaseStartTime)
    }
}
