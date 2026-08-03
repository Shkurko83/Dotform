import SwiftUI

struct SensoryExerciseView: View {
    @EnvironmentObject private var appState: AppState
    let exercise: SensoryExercise

    private var context: FeedbackContext { appState.feedbackContext }

    var body: some View {
        cardContent
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .cardScreenChrome()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Повторить") {
                        appState.blindFeedback.speak(exercise.instruction, context: context)
                    }
                    .accessibilityLabel("Повторить инструкцию")
                }
            }
            .onAppear {
                appState.blindFeedback.speak(exercise.instruction, context: context)
            }
    }

    @ViewBuilder
    private var cardContent: some View {
        if isBrailleExercise {
            brailleExerciseView
        } else {
            regionExerciseView
        }
    }

    private var isBrailleExercise: Bool {
        switch exercise.kind {
        case .singleDot, .twoDots: return true
        default: return false
        }
    }

    @ViewBuilder
    private var brailleExerciseView: some View {
        switch exercise.kind {
        case .singleDot(let target):
            BrailleCellView(
                letter: BrailleGlyph(
                    id: "exercise.single.\(target.rawValue)",
                    display: "·",
                    dots: appState.settings.showDotsVisually ? [target] : [],
                    kind: .letter,
                    level: .spatialBasics,
                    contextWord: nil
                ),
                mode: .sensory,
                selectedDots: [],
                foundDots: [],
                showFilledDots: appState.settings.showDotsVisually,
                onDotTouch: { dot in
                    if dot == target {
                        appState.blindFeedback.success(context: context)
                    } else {
                        appState.blindFeedback.emptyDot(context: context)
                    }
                }
            )
        case .twoDots(let targets):
            BrailleCellView(
                letter: BrailleGlyph(
                    id: "exercise.two.\(targets.map(\.rawValue).sorted().map(String.init).joined())",
                    display: "·",
                    dots: appState.settings.showDotsVisually ? targets : [],
                    kind: .letter,
                    level: .spatialBasics,
                    contextWord: nil
                ),
                mode: .sensory,
                selectedDots: [],
                foundDots: [],
                showFilledDots: appState.settings.showDotsVisually,
                onDotTouch: { dot in
                    if targets.contains(dot) {
                        appState.blindFeedback.filledDot(context: context)
                    } else {
                        appState.blindFeedback.emptyDot(context: context)
                    }
                }
            )
        default:
            EmptyView()
        }
    }

    private var regionExerciseView: some View {
        ZStack {
            regionBackground
            TouchSurfaceView(layout: touchLayout) { zoneIndex in
                handleRegionZone(zoneIndex)
            }
        }
    }

    @ViewBuilder
    private var regionBackground: some View {
        switch exercise.kind {
        case .compareSignals, .comparePosition:
            HStack(spacing: 0) {
                zonePanel.accessibilityHidden(true)
                zonePanel.accessibilityHidden(true)
            }
        case .compareHaptic:
            VStack(spacing: 0) {
                zonePanel.accessibilityHidden(true)
                zonePanel.accessibilityHidden(true)
            }
        case .compareVertical:
            VStack(spacing: 0) {
                zonePanel.accessibilityHidden(true)
                zonePanel.accessibilityHidden(true)
                zonePanel.accessibilityHidden(true)
            }
        default:
            Color(.systemBackground)
        }
    }

    private var zonePanel: some View {
        Color(.secondarySystemBackground)
            .overlay { Rectangle().strokeBorder(Color.primary.opacity(0.08), lineWidth: 1) }
    }

    private var touchLayout: TouchLayout {
        switch exercise.kind {
        case .compareSignals, .comparePosition: return .leftRight
        case .compareHaptic: return .topBottom
        case .compareVertical: return .topMiddleBottom
        default: return .leftRight
        }
    }

    private func handleRegionZone(_ zoneIndex: Int) {
        let feedback = appState.blindFeedback

        switch exercise.kind {
        case .compareSignals:
            zoneIndex == 0
                ? feedback.shortPulse(context: context)
                : feedback.longPulse(context: context)
        case .compareHaptic:
            zoneIndex == 0
                ? feedback.softPulse(context: context)
                : feedback.strongPulse(context: context)
        case .comparePosition, .compareVertical:
            guard let region = SpatialRegion.from(zoneIndex: zoneIndex, layout: touchLayout) else { return }
            feedback.region(region, context: context)
        default:
            break
        }
    }
}
