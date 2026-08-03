import Foundation

enum AppLanguage: String, Codable, CaseIterable, Identifiable {
    case russian = "ru-RU"
    case english = "en-US"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .russian: return "Русский"
        case .english: return "English"
        }
    }
}

enum DifficultyLevel: String, Codable, CaseIterable, Identifiable {
    case easy, normal, advanced

    var id: String { rawValue }

    var title: String {
        switch self {
        case .easy: return "Лёгкий"
        case .normal: return "Обычный"
        case .advanced: return "Продвинутый"
        }
    }
}

enum ErrorSensitivity: String, Codable, CaseIterable, Identifiable {
    case soft, strict

    var id: String { rawValue }

    var title: String {
        switch self {
        case .soft: return "Мягкий режим"
        case .strict: return "Строгий режим"
        }
    }
}

struct AppSettings: Codable, Equatable {
    var language: AppLanguage = .russian
    var speechRate: Float = 0.45
    var auxiliarySoundVolume: Float = 0.8
    var hapticEnabled: Bool = true
    var hapticIntensity: Float = 1.0
    var signalDuration: Float = 0.3
    var autoAdvanceOnSuccess: Bool = true
    var difficulty: DifficultyLevel = .normal

    // Deaf-blind settings
    var vibrationPrimaryChannel: Bool = true
    var parallelSoundForResidualHearing: Bool = false
    var instructionPauseDuration: TimeInterval = 2.0
    var errorSensitivity: ErrorSensitivity = .soft
    var modelHandEnabled: Bool = true
    var useAlternativeHapticPatterns: Bool = false

    // Parent settings
    var childProfile: UserProfile = .blindChild
    var activeScript: BrailleScriptID = .russian
    /// ID глифов для уроков; пустой набор = все буквы активного скрипта.
    var enabledGlyphIDs: Set<String> = []
    var sessionLengthLimitMinutes: Int? = nil
    var repeatLearnedLetters: Bool = true
    var showDotsVisually: Bool = true
    var spokenZoneFeedback: Bool = true

    /// В релее: проигрывать точки символа по очереди (модельная рука).
    var relayPlayDotsInSequence: Bool = false

    /// Выбранные вибрации из каталога: ключ — SensoryFeedbackRole.rawValue.
    var hapticSelections: [String: String] = [:]
    /// Выбранные звуки из каталога: ключ — SensoryFeedbackRole.rawValue.
    var soundSelections: [String: String] = [:]
    /// Параметры своей вибрации по ролям (при hapticSelections == custom.haptic).
    var customHapticByRole: [String: CustomHapticDefinition] = [:]

    var feedbackMode: FeedbackMode {
        childProfile.feedbackMode
    }

    var activeLetters: [BrailleGlyph] {
        BrailleCatalog.letters(for: activeScript)
    }

    func isGlyphEnabled(_ glyph: BrailleGlyph) -> Bool {
        enabledGlyphIDs.isEmpty || enabledGlyphIDs.contains(glyph.id)
    }

    /// Миграция со старого `enabledLetterCharacters` (декодирование вручную в ProgressStore).
    mutating func migrateEnabledLettersIfNeeded(legacyCharacters: Set<String>?) {
        guard enabledGlyphIDs.isEmpty, let legacy = legacyCharacters, !legacy.isEmpty else { return }
        let script = BrailleCatalog.script(activeScript)
        enabledGlyphIDs = Set(script.letters.filter { legacy.contains($0.display) }.map(\.id))
    }
}
