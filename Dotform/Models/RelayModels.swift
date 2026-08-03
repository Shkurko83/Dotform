import Foundation

enum RelayMessageType: String, Codable {
    case hello
    case text
    case cancel
    case ping
    case ack
}

struct RelayEnvelope: Codable, Equatable {
    static let protocolVersion = 1

    var v: Int
    var type: RelayMessageType
    var text: String?
    var scriptID: String?
    var sentAt: Date
    var messageID: String?

    static func hello(scriptID: BrailleScriptID, displayName: String) -> RelayEnvelope {
        RelayEnvelope(
            v: protocolVersion,
            type: .hello,
            text: displayName,
            scriptID: scriptID.rawValue,
            sentAt: Date(),
            messageID: UUID().uuidString
        )
    }

    static func text(_ body: String, scriptID: BrailleScriptID) -> RelayEnvelope {
        RelayEnvelope(
            v: protocolVersion,
            type: .text,
            text: body,
            scriptID: scriptID.rawValue,
            sentAt: Date(),
            messageID: UUID().uuidString
        )
    }

    static func cancel() -> RelayEnvelope {
        RelayEnvelope(
            v: protocolVersion,
            type: .cancel,
            text: nil,
            scriptID: nil,
            sentAt: Date(),
            messageID: UUID().uuidString
        )
    }

    static func ping() -> RelayEnvelope {
        RelayEnvelope(
            v: protocolVersion,
            type: .ping,
            text: nil,
            scriptID: nil,
            sentAt: Date(),
            messageID: UUID().uuidString
        )
    }

    func encoded() -> Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try? encoder.encode(self)
    }

    static func decode(from data: Data) -> RelayEnvelope? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(RelayEnvelope.self, from: data)
    }
}

enum RelayRole: String, CaseIterable, Identifiable {
    case receiver
    case writer

    var id: String { rawValue }

    var title: String {
        switch self {
        case .receiver: return "Я принимаю"
        case .writer: return "Я пишу"
        }
    }

    var subtitle: String {
        switch self {
        case .receiver: return "Покажите QR — второй телефон отсканирует"
        case .writer: return "Отсканируйте QR на устройстве слепоглухого"
        }
    }
}

struct RelayPairingPayload: Codable, Equatable {
    let session: String
    let peer: String
    let service: String

    static let bonjourService = "dotform-relay"

    var qrString: String {
        "dotform://pair?session=\(session)&peer=\(peer.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? peer)&service=\(service)"
    }

    static func parse(_ string: String) -> RelayPairingPayload? {
        guard let url = URL(string: string),
              url.scheme == "dotform",
              url.host == "pair",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let session = components.queryItems?.first(where: { $0.name == "session" })?.value,
              let peer = components.queryItems?.first(where: { $0.name == "peer" })?.value
        else { return nil }

        let service = components.queryItems?.first(where: { $0.name == "service" })?.value ?? bonjourService
        return RelayPairingPayload(session: session, peer: peer, service: service)
    }
}

/// Компактный payload для Apple Watch.
struct WatchGlyphPayload: Codable, Equatable {
    let glyphID: String
    let display: String
    let dots: [Int]
    let intensity: Float
    let sharpness: Float
    let duration: Float
    let kind: String
    let playDotsInSequence: Bool
}
