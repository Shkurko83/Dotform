import SwiftUI

struct LessonView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    let letter: BrailleLetter

    @State private var controller: LessonController?
    @State private var showCompletion = false

    var body: some View {
        VStack(spacing: 0) {
            cardContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            lessonControlsBar
        }
        .cardScreenChrome()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Повторить") {
                    controller?.repeatInstruction()
                }
                .accessibilityLabel("Повторить инструкцию")
            }
        }
        .onAppear { startLesson() }
        .onChange(of: appState.settings.childProfile) { _, _ in
            controller?.settings = appState.settings
        }
        .onChange(of: appState.settings.parallelSoundForResidualHearing) { _, _ in
            controller?.settings = appState.settings
        }
        .alert("Урок завершён", isPresented: $showCompletion) {
            Button("Далее") { dismiss() }
        } message: {
            Text("Буква \(letter.character) изучена.")
        }
    }

    @ViewBuilder
    private var cardContent: some View {
        if let controller {
            BrailleCellView(
                letter: cellLetter(for: controller),
                mode: cellMode(for: controller.phase),
                selectedDots: controller.selectedDots,
                foundDots: controller.foundDots,
                showFilledDots: appState.settings.showDotsVisually && shouldShowLetterDots(for: controller),
                onDotTouch: { dot in
                    controller.handleDotSelection(dot)
                }
            )
        } else {
            Color(.systemBackground)
        }
    }

    @ViewBuilder
    private var lessonControlsBar: some View {
        if let controller {
            switch controller.phase {
            case .exploration:
                blindButton("Далее", hint: "Перейти к закреплению") {
                    controller.advanceFromExploration()
                }
            case .test:
                blindButton("Проверить", hint: "Проверить собранную букву") {
                    submitTest(controller)
                }
            case .result(let success):
                if success {
                    blindButton("Завершить", hint: "Выйти из урока") { dismiss() }
                } else {
                    blindButton("Снова", hint: "Начать урок заново") {
                        controller.startLesson()
                    }
                }
            default:
                EmptyView()
            }
        }
    }

    private func blindButton(_ title: String, hint: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.title3.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
        }
        .buttonStyle(.borderedProminent)
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
        .accessibilityLabel(title)
        .accessibilityHint(hint)
    }

    private func startLesson() {
        guard controller == nil else { return }
        let profile = appState.settings.childProfile
        let lesson = LessonController(
            letter: letter,
            profile: profile,
            settings: appState.settings,
            blindFeedback: appState.blindFeedback
        )
        controller = lesson
        lesson.startLesson()
    }

    private func submitTest(_ controller: LessonController) {
        let success = controller.submitAnswer()
        if success {
            appState.store.recordLessonResult(
                letter: letter,
                succeeded: true,
                phase: .test,
                duration: controller.phaseDuration()
            )
            if appState.settings.autoAdvanceOnSuccess {
                showCompletion = true
            }
        } else {
            appState.store.recordLessonResult(
                letter: letter,
                succeeded: false,
                phase: .test,
                duration: controller.phaseDuration()
            )
        }
    }

    private func shouldShowLetterDots(for controller: LessonController) -> Bool {
        switch controller.phase {
        case .exploration, .modelHand, .entry, .test:
            return true
        case .reinforcement, .result:
            return false
        }
    }

    private func cellLetter(for controller: LessonController) -> BrailleLetter? {
        switch controller.phase {
        case .exploration, .modelHand, .entry:
            return letter
        case .reinforcement, .test, .result:
            return nil
        }
    }

    private func cellMode(for phase: LessonPhase) -> BrailleCellMode {
        switch phase {
        case .exploration, .modelHand, .entry:
            return .explore
        case .reinforcement:
            return .findDots
        case .test, .result:
            return .build
        }
    }
}

#Preview {
    NavigationStack {
        LessonView(letter: BrailleAlphabet.mvpLetters[0])
            .environmentObject(AppState())
    }
}
