import Foundation

enum LessonCatalog {
    static func sensoryExercises() -> [SensoryExercise] {
        [
            SensoryExercise(
                id: "signal-short-long",
                title: "Короткий и длинный сигнал",
                instruction: "Прикоснись к левой части экрана — короткий сигнал. К правой — длинный.",
                level: .sensoryPrep,
                kind: .compareSignals(shortVsLong: true)
            ),
            SensoryExercise(
                id: "haptic-soft-strong",
                title: "Мягкая и сильная вибрация",
                instruction: "Верх экрана — мягкая вибрация. Низ — сильная.",
                level: .sensoryPrep,
                kind: .compareHaptic(softVsStrong: true)
            ),
            SensoryExercise(
                id: "position-left-right",
                title: "Левая и правая часть",
                instruction: "Исследуй левую и правую половины экрана.",
                level: .sensoryPrep,
                kind: .comparePosition(leftVsRight: true)
            ),
            SensoryExercise(
                id: "position-vertical",
                title: "Верх, середина, низ",
                instruction: "Исследуй верхнюю, среднюю и нижнюю зоны.",
                level: .sensoryPrep,
                kind: .compareVertical(topVsMiddleVsBottom: true)
            ),
        ]
    }

    static func spatialExercises() -> [SensoryExercise] {
        [
            SensoryExercise(
                id: "one-dot-left",
                title: "Одна точка слева",
                instruction: "Найди левую верхнюю точку.",
                level: .spatialBasics,
                kind: .singleDot(.dot1)
            ),
            SensoryExercise(
                id: "one-dot-right",
                title: "Одна точка справа",
                instruction: "Найди правую верхнюю точку.",
                level: .spatialBasics,
                kind: .singleDot(.dot4)
            ),
            SensoryExercise(
                id: "top-dot",
                title: "Верхняя точка",
                instruction: "Найди верхние точки ячейки.",
                level: .spatialBasics,
                kind: .twoDots([.dot1, .dot4])
            ),
            SensoryExercise(
                id: "bottom-dot",
                title: "Нижняя точка",
                instruction: "Найди нижние точки ячейки.",
                level: .spatialBasics,
                kind: .twoDots([.dot3, .dot6])
            ),
            SensoryExercise(
                id: "two-dots",
                title: "Две точки вместе",
                instruction: "Найди две точки слева — верхнюю и среднюю.",
                level: .spatialBasics,
                kind: .twoDots([.dot1, .dot2])
            ),
        ]
    }

    static func lessons(
        for level: LearningLevel,
        settings: AppSettings,
        progress: ProgressData
    ) -> [BrailleLetter] {
        switch level {
        case .sensoryPrep, .spatialBasics:
            return []
        case .firstLetters, .fullCell, .letterInContext, .review:
            let base = settings.activeLetters.filter { $0.level.rawValue <= level.rawValue }
            let enabled = base.filter { settings.isGlyphEnabled($0) }
            if level == .review {
                return progress.recommendedLetters(from: enabled, settings: settings)
            }
            return enabled
        }
    }
}
