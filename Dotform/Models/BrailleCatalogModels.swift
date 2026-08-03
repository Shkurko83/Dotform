import Foundation

enum BrailleScriptID: String, Codable, CaseIterable, Identifiable {
    case russian
    case englishGrade1

    var id: String { rawValue }

    var title: String {
        switch self {
        case .russian: return "Русский"
        case .englishGrade1: return "English (Grade 1)"
        }
    }

    var shortTitle: String {
        switch self {
        case .russian: return "RU"
        case .englishGrade1: return "EN"
        }
    }
}

enum GlyphKind: String, Codable, CaseIterable, Identifiable {
    case letter
    case digit
    case punctuation
    case indicator
    case space

    var id: String { rawValue }
}

/// Универсальный символ Брайля (буква, цифра, знак, индикатор).
struct BrailleGlyph: Identifiable, Codable, Hashable {
    let id: String
    let display: String
    let dots: Set<BrailleDot>
    let kind: GlyphKind
    let level: LearningLevel
    let contextWord: String?

    /// Совместимость с уроками / прогрессом.
    var character: String { display }

    var dotCount: Int { dots.count }

    func matches(selection: Set<BrailleDot>) -> Bool {
        dots == selection
    }

    static func letter(
        scriptPrefix: String,
        character: String,
        dots: Set<BrailleDot>,
        level: LearningLevel,
        contextWord: String? = nil
    ) -> BrailleGlyph {
        BrailleGlyph(
            id: "\(scriptPrefix).\(character)",
            display: character,
            dots: dots,
            kind: .letter,
            level: level,
            contextWord: contextWord
        )
    }
}

/// Историческое имя для уроков — тот же тип, что и glyph.
typealias BrailleLetter = BrailleGlyph

struct BrailleScript {
    let id: BrailleScriptID
    let title: String
    let glyphs: [BrailleGlyph]

    var letters: [BrailleGlyph] {
        glyphs.filter { $0.kind == .letter }
    }

    func glyph(forDisplay display: String) -> BrailleGlyph? {
        glyphs.first { $0.display == display }
    }

    func glyph(id: String) -> BrailleGlyph? {
        glyphs.first { $0.id == id }
    }

    func letter(for character: String) -> BrailleGlyph? {
        letters.first { $0.display.caseInsensitiveCompare(character) == .orderedSame }
    }
}

enum BrailleCatalog {
    static var allScripts: [BrailleScript] {
        [russian, englishGrade1]
    }

    static func script(_ id: BrailleScriptID) -> BrailleScript {
        switch id {
        case .russian: return russian
        case .englishGrade1: return englishGrade1
        }
    }

    static func letters(for id: BrailleScriptID) -> [BrailleGlyph] {
        script(id).letters
    }

    static let russian = BrailleScript(
        id: .russian,
        title: BrailleScriptID.russian.title,
        glyphs: RussianBrailleData.glyphs
    )

    static let englishGrade1 = BrailleScript(
        id: .englishGrade1,
        title: BrailleScriptID.englishGrade1.title,
        glyphs: EnglishBrailleData.glyphs
    )
}

/// Фасад для старого API + удобный доступ к активному русскому набору.
enum BrailleAlphabet {
    static var allLetters: [BrailleLetter] { BrailleCatalog.russian.letters }

    /// Первые буквы для быстрого старта (уровень firstLetters + начало fullCell).
    static var mvpLetters: [BrailleLetter] {
        let first = allLetters.filter { $0.level == .firstLetters }
        let more = allLetters.filter { $0.level == .fullCell }.prefix(9)
        return first + Array(more)
    }

    static func letter(for character: String) -> BrailleLetter? {
        BrailleCatalog.russian.letter(for: character)
    }

    static func letters(for level: LearningLevel) -> [BrailleLetter] {
        allLetters.filter { $0.level == level }
    }
}
