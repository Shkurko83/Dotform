import Foundation

enum UserProfile: String, CaseIterable, Codable, Identifiable {
    case blindChild
    case deafBlindChild
    case parentTeacher

    var id: String { rawValue }

    var title: String {
        switch self {
        case .blindChild: return "Незрячий ребёнок"
        case .deafBlindChild: return "Слепоглухой ребёнок"
        case .parentTeacher: return "Родитель / педагог"
        }
    }

    var accessibilityHint: String {
        switch self {
        case .blindChild:
            return "Режим с голосовыми инструкциями, звуком и тактильной обратной связью"
        case .deafBlindChild:
            return "Режим с вибрацией как основным каналом обратной связи"
        case .parentTeacher:
            return "Полный доступ к настройкам, прогрессу и управлению обучением"
        }
    }

    var isChildProfile: Bool {
        self == .blindChild || self == .deafBlindChild
    }

    var feedbackMode: FeedbackMode {
        switch self {
        case .blindChild: return .audioFirst
        case .deafBlindChild: return .hapticFirst
        case .parentTeacher: return .audioFirst
        }
    }
}

enum FeedbackMode: String, Codable, CaseIterable {
    case audioFirst
    case hapticFirst

    var title: String {
        switch self {
        case .audioFirst: return "Звук и тактильность"
        case .hapticFirst: return "Вибрация"
        }
    }
}
