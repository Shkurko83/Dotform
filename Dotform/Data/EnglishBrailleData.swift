import Foundation

/// English Braille Grade 1 (uncontracted). Цифры/пунктуация — индикаторы в модели, уроки пока не включают.
enum EnglishBrailleData {
    private static let p = "en"

    static let glyphs: [BrailleGlyph] = letters + indicators

    private static let letters: [BrailleGlyph] = [
        .letter(scriptPrefix: p, character: "A", dots: [.dot1], level: .firstLetters, contextWord: "apple"),
        .letter(scriptPrefix: p, character: "B", dots: [.dot1, .dot2], level: .firstLetters, contextWord: "ball"),
        .letter(scriptPrefix: p, character: "C", dots: [.dot1, .dot4], level: .firstLetters, contextWord: "cat"),
        .letter(scriptPrefix: p, character: "D", dots: [.dot1, .dot4, .dot5], level: .fullCell, contextWord: "dog"),
        .letter(scriptPrefix: p, character: "E", dots: [.dot1, .dot5], level: .firstLetters, contextWord: "egg"),
        .letter(scriptPrefix: p, character: "F", dots: [.dot1, .dot2, .dot4], level: .fullCell, contextWord: "fish"),
        .letter(scriptPrefix: p, character: "G", dots: [.dot1, .dot2, .dot4, .dot5], level: .fullCell, contextWord: "goat"),
        .letter(scriptPrefix: p, character: "H", dots: [.dot1, .dot2, .dot5], level: .fullCell, contextWord: "hat"),
        .letter(scriptPrefix: p, character: "I", dots: [.dot2, .dot4], level: .fullCell, contextWord: "ice"),
        .letter(scriptPrefix: p, character: "J", dots: [.dot2, .dot4, .dot5], level: .fullCell, contextWord: "jam"),
        .letter(scriptPrefix: p, character: "K", dots: [.dot1, .dot3], level: .fullCell, contextWord: "kite"),
        .letter(scriptPrefix: p, character: "L", dots: [.dot1, .dot2, .dot3], level: .fullCell, contextWord: "lamp"),
        .letter(scriptPrefix: p, character: "M", dots: [.dot1, .dot3, .dot4], level: .fullCell, contextWord: "moon"),
        .letter(scriptPrefix: p, character: "N", dots: [.dot1, .dot3, .dot4, .dot5], level: .fullCell, contextWord: "nest"),
        .letter(scriptPrefix: p, character: "O", dots: [.dot1, .dot3, .dot5], level: .fullCell, contextWord: "orange"),
        .letter(scriptPrefix: p, character: "P", dots: [.dot1, .dot2, .dot3, .dot4], level: .fullCell, contextWord: "pen"),
        .letter(scriptPrefix: p, character: "Q", dots: [.dot1, .dot2, .dot3, .dot4, .dot5], level: .fullCell, contextWord: "queen"),
        .letter(scriptPrefix: p, character: "R", dots: [.dot1, .dot2, .dot3, .dot5], level: .fullCell, contextWord: "rain"),
        .letter(scriptPrefix: p, character: "S", dots: [.dot2, .dot3, .dot4], level: .fullCell, contextWord: "sun"),
        .letter(scriptPrefix: p, character: "T", dots: [.dot2, .dot3, .dot4, .dot5], level: .fullCell, contextWord: "tree"),
        .letter(scriptPrefix: p, character: "U", dots: [.dot1, .dot3, .dot6], level: .fullCell, contextWord: "umbrella"),
        .letter(scriptPrefix: p, character: "V", dots: [.dot1, .dot2, .dot3, .dot6], level: .fullCell, contextWord: "van"),
        .letter(scriptPrefix: p, character: "W", dots: [.dot2, .dot4, .dot5, .dot6], level: .fullCell, contextWord: "water"),
        .letter(scriptPrefix: p, character: "X", dots: [.dot1, .dot3, .dot4, .dot6], level: .fullCell, contextWord: "box"),
        .letter(scriptPrefix: p, character: "Y", dots: [.dot1, .dot3, .dot4, .dot5, .dot6], level: .fullCell, contextWord: "yarn"),
        .letter(scriptPrefix: p, character: "Z", dots: [.dot1, .dot3, .dot5, .dot6], level: .fullCell, contextWord: "zoo"),
    ]

    /// Индикаторы Grade 1 — в модели для масштабирования; уроки цифр/пунктуации пока не подключены.
    private static let indicators: [BrailleGlyph] = [
        BrailleGlyph(
            id: "en.indicator.capital",
            display: "⇧",
            dots: [.dot6],
            kind: .indicator,
            level: .fullCell,
            contextWord: nil
        ),
        BrailleGlyph(
            id: "en.indicator.number",
            display: "#",
            dots: [.dot3, .dot4, .dot5, .dot6],
            kind: .indicator,
            level: .fullCell,
            contextWord: nil
        ),
        BrailleGlyph(
            id: "en.space",
            display: " ",
            dots: [],
            kind: .space,
            level: .fullCell,
            contextWord: nil
        ),
    ]
}
