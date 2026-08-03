import Foundation

/// Русский шеститочечный Брайль (по латинской транслитерации / ГОСТ).
enum RussianBrailleData {
    private static let p = "ru"

    static let glyphs: [BrailleGlyph] = [
        .letter(scriptPrefix: p, character: "А", dots: [.dot1], level: .firstLetters, contextWord: "арбуз"),
        .letter(scriptPrefix: p, character: "Б", dots: [.dot1, .dot2], level: .firstLetters, contextWord: "бабушка"),
        .letter(scriptPrefix: p, character: "В", dots: [.dot2, .dot4, .dot5, .dot6], level: .fullCell, contextWord: "вода"),
        .letter(scriptPrefix: p, character: "Г", dots: [.dot1, .dot2, .dot4, .dot5], level: .fullCell, contextWord: "гора"),
        .letter(scriptPrefix: p, character: "Д", dots: [.dot1, .dot4, .dot5], level: .fullCell, contextWord: "дом"),
        .letter(scriptPrefix: p, character: "Е", dots: [.dot1, .dot5], level: .firstLetters, contextWord: "ель"),
        .letter(scriptPrefix: p, character: "Ё", dots: [.dot1, .dot6], level: .fullCell, contextWord: "ёлка"),
        .letter(scriptPrefix: p, character: "Ж", dots: [.dot2, .dot4, .dot5], level: .fullCell, contextWord: "жук"),
        .letter(scriptPrefix: p, character: "З", dots: [.dot1, .dot3, .dot5, .dot6], level: .fullCell, contextWord: "зима"),
        .letter(scriptPrefix: p, character: "И", dots: [.dot2, .dot4], level: .fullCell, contextWord: "игра"),
        .letter(scriptPrefix: p, character: "Й", dots: [.dot1, .dot2, .dot3, .dot4, .dot6], level: .fullCell, contextWord: "йод"),
        .letter(scriptPrefix: p, character: "К", dots: [.dot1, .dot3], level: .firstLetters, contextWord: "кот"),
        .letter(scriptPrefix: p, character: "Л", dots: [.dot1, .dot2, .dot3], level: .fullCell, contextWord: "луна"),
        .letter(scriptPrefix: p, character: "М", dots: [.dot1, .dot3, .dot4], level: .fullCell, contextWord: "мама"),
        .letter(scriptPrefix: p, character: "Н", dots: [.dot1, .dot3, .dot4, .dot5], level: .fullCell, contextWord: "нос"),
        .letter(scriptPrefix: p, character: "О", dots: [.dot1, .dot3, .dot5], level: .fullCell, contextWord: "окно"),
        .letter(scriptPrefix: p, character: "П", dots: [.dot1, .dot2, .dot3, .dot4], level: .fullCell, contextWord: "папа"),
        .letter(scriptPrefix: p, character: "Р", dots: [.dot1, .dot2, .dot3, .dot5], level: .fullCell, contextWord: "рука"),
        .letter(scriptPrefix: p, character: "С", dots: [.dot2, .dot3, .dot4], level: .fullCell, contextWord: "снег"),
        .letter(scriptPrefix: p, character: "Т", dots: [.dot2, .dot3, .dot4, .dot5], level: .fullCell, contextWord: "трава"),
        .letter(scriptPrefix: p, character: "У", dots: [.dot1, .dot3, .dot6], level: .fullCell, contextWord: "утро"),
        .letter(scriptPrefix: p, character: "Ф", dots: [.dot1, .dot2, .dot4], level: .fullCell, contextWord: "флаг"),
        .letter(scriptPrefix: p, character: "Х", dots: [.dot1, .dot2, .dot5], level: .fullCell, contextWord: "хлеб"),
        .letter(scriptPrefix: p, character: "Ц", dots: [.dot1, .dot4], level: .fullCell, contextWord: "цвет"),
        .letter(scriptPrefix: p, character: "Ч", dots: [.dot1, .dot2, .dot3, .dot4, .dot5], level: .fullCell, contextWord: "чай"),
        .letter(scriptPrefix: p, character: "Ш", dots: [.dot1, .dot5, .dot6], level: .fullCell, contextWord: "шар"),
        .letter(scriptPrefix: p, character: "Щ", dots: [.dot1, .dot3, .dot4, .dot6], level: .fullCell, contextWord: "щука"),
        .letter(scriptPrefix: p, character: "Ъ", dots: [.dot1, .dot2, .dot3, .dot5, .dot6], level: .fullCell, contextWord: nil),
        .letter(scriptPrefix: p, character: "Ы", dots: [.dot2, .dot3, .dot4, .dot6], level: .fullCell, contextWord: nil),
        .letter(scriptPrefix: p, character: "Ь", dots: [.dot2, .dot3, .dot4, .dot5, .dot6], level: .fullCell, contextWord: nil),
        .letter(scriptPrefix: p, character: "Э", dots: [.dot2, .dot4, .dot6], level: .fullCell, contextWord: "эхо"),
        .letter(scriptPrefix: p, character: "Ю", dots: [.dot1, .dot2, .dot5, .dot6], level: .fullCell, contextWord: "юла"),
        .letter(scriptPrefix: p, character: "Я", dots: [.dot1, .dot2, .dot4, .dot6], level: .fullCell, contextWord: "яблоко"),
        BrailleGlyph(
            id: "ru.space",
            display: " ",
            dots: [],
            kind: .space,
            level: .fullCell,
            contextWord: nil
        ),
    ]
}
