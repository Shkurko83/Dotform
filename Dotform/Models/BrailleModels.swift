import Foundation

/// Позиции точек в шеститочечной ячейке Брайля (стандартная нумерация).
/// ```
/// 1  4
/// 2  5
/// 3  6
/// ```
enum BrailleDot: Int, CaseIterable, Codable, Hashable, Identifiable {
    case dot1 = 1
    case dot2 = 2
    case dot3 = 3
    case dot4 = 4
    case dot5 = 5
    case dot6 = 6

    var id: Int { rawValue }

    var accessibilityName: String {
        switch self {
        case .dot1: return "Левая верхняя точка"
        case .dot2: return "Левая средняя точка"
        case .dot3: return "Левая нижняя точка"
        case .dot4: return "Правая верхняя точка"
        case .dot5: return "Правая средняя точка"
        case .dot6: return "Правая нижняя точка"
        }
    }

    var column: Int { rawValue <= 3 ? 0 : 1 }
    var row: Int { rawValue <= 3 ? rawValue - 1 : rawValue - 4 }
}

enum LearningLevel: Int, CaseIterable, Codable, Identifiable {
    case sensoryPrep = 0
    case spatialBasics = 1
    case firstLetters = 2
    case fullCell = 3
    case letterInContext = 4
    case review = 5

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .sensoryPrep: return "Уровень 0. Сенсорная подготовка"
        case .spatialBasics: return "Уровень 1. Пространственные различия"
        case .firstLetters: return "Уровень 2. Первые буквы"
        case .fullCell: return "Уровень 3. Полная ячейка"
        case .letterInContext: return "Уровень 4. Буква в контексте"
        case .review: return "Уровень 5. Закрепление"
        }
    }

    var accessibilityDescription: String { title }
}

enum LessonPhase: Equatable {
    case entry
    case modelHand
    case exploration
    case reinforcement
    case test
    case result(success: Bool)
}

enum LessonMode {
    case explore
    case findDots
    case build
    case distinguish
}

struct SensoryExercise: Identifiable {
    let id: String
    let title: String
    let instruction: String
    let level: LearningLevel
    let kind: SensoryExerciseKind
}

enum SensoryExerciseKind {
    case compareSignals(shortVsLong: Bool)
    case compareHaptic(softVsStrong: Bool)
    case comparePosition(leftVsRight: Bool)
    case compareVertical(topVsMiddleVsBottom: Bool)
    case singleDot(BrailleDot)
    case twoDots(Set<BrailleDot>)
}
