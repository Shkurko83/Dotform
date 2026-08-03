import Foundation

enum RelayToken: Equatable {
    case glyph(BrailleGlyph)
    case unknown(Character)
    case space
}

enum TextToHapticEncoder {
    static func tokenize(_ text: String, scriptID: BrailleScriptID) -> [RelayToken] {
        let script = BrailleCatalog.script(scriptID)
        var tokens: [RelayToken] = []
        tokens.reserveCapacity(text.count)

        for character in text {
            if character.isWhitespace || character == "\n" {
                tokens.append(.space)
                continue
            }

            let asString = String(character)
            if let glyph = script.letter(for: asString)
                ?? script.letter(for: asString.uppercased())
                ?? script.letter(for: asString.lowercased()) {
                tokens.append(.glyph(glyph))
            } else if let glyph = script.glyph(forDisplay: asString) {
                tokens.append(.glyph(glyph))
            } else {
                tokens.append(.unknown(character))
            }
        }
        return tokens
    }
}
