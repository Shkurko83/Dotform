import Foundation

enum CustomHapticEventKind: String, Codable, CaseIterable, Identifiable {
    case transient
    case continuous

    var id: String { rawValue }

    var title: String {
        switch self {
        case .transient: return "Удар"
        case .continuous: return "Непрерывный гул"
        }
    }
}

/// Параметры вибрации, собранные в конструкторе Core Haptics.
struct CustomHapticDefinition: Codable, Equatable, Hashable {
    static let catalogItemID = "custom.haptic"

    var kind: CustomHapticEventKind = .transient
    /// Сила вибрации, 0…1.
    var intensity: Float = 0.8
    /// Мягкость (0) … резкость (1).
    var sharpness: Float = 0.5
    /// Длительность гула в секундах (только continuous).
    var duration: Float = 0.3
    /// Время нарастания (только continuous).
    var attack: Float = 0.05
    /// Время затухания (только continuous).
    var decay: Float = 0.05
    /// Число ударов подряд (только transient).
    var repeatCount: Int = 1
    /// Пауза между ударами в секундах.
    var repeatInterval: Float = 0.12

    var summary: String {
        switch kind {
        case .transient:
            let repeats = repeatCount > 1 ? " · ×\(repeatCount)" : ""
            return String(
                format: "Удар · сила %.0f%% · резкость %.0f%%%@",
                intensity * 100, sharpness * 100, repeats
            )
        case .continuous:
            return String(
                format: "Гул · %.2f с · сила %.0f%% · резкость %.0f%%",
                duration, intensity * 100, sharpness * 100
            )
        }
    }
}
