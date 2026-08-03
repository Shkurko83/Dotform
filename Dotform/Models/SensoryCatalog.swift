import Foundation

/// Роль обратной связи, для которой можно назначить вибрацию или звук.
enum SensoryFeedbackRole: String, Codable, CaseIterable, Identifiable {
    case filledDot
    case emptyDot
    case success
    case error
    case lessonStart
    case shortSignal
    case longSignal
    case regionLeft
    case regionRight
    case regionTop
    case regionMiddle
    case regionBottom
    case relayGlyph

    var id: String { rawValue }

    var title: String {
        switch self {
        case .filledDot: return "Заполненная точка"
        case .emptyDot: return "Пустая точка"
        case .success: return "Успех"
        case .error: return "Ошибка"
        case .lessonStart: return "Начало урока"
        case .shortSignal: return "Короткий сигнал"
        case .longSignal: return "Длинный сигнал"
        case .regionLeft: return "Зона: слева"
        case .regionRight: return "Зона: справа"
        case .regionTop: return "Зона: верх"
        case .regionMiddle: return "Зона: центр"
        case .regionBottom: return "Зона: низ"
        case .relayGlyph: return "Символ в связи"
        }
    }

    static func from(_ region: SpatialRegion) -> SensoryFeedbackRole {
        switch region {
        case .left: return .regionLeft
        case .right: return .regionRight
        case .top: return .regionTop
        case .middle: return .regionMiddle
        case .bottom: return .regionBottom
        }
    }
}

enum SensoryChannel: String, Codable, CaseIterable, Identifiable {
    case haptic
    case sound

    var id: String { rawValue }

    var title: String {
        switch self {
        case .haptic: return "Вибрация"
        case .sound: return "Звуки"
        }
    }
}

struct SensoryCatalogItem: Identifiable, Hashable, Codable {
    let id: String
    let title: String
    let subtitle: String
    let category: String
    let channel: SensoryChannel
    let payload: SensoryPayload

    enum SensoryPayload: Hashable, Codable {
        case impact(style: ImpactStyle, intensity: Float?)
        case notification(type: NotificationType)
        case selection
        case systemVibrate(SystemVibrateVariant)
        case coreHaptic(pattern: CoreHapticPatternID)
        case appTone(FeedbackToneID)
        case synthesizedTone(frequency: Double, duration: TimeInterval)
        case systemSound(id: SystemSoundID, vibrate: Bool)

        enum ImpactStyle: String, Codable, CaseIterable {
            case light, medium, heavy, soft, rigid
        }

        enum NotificationType: String, Codable, CaseIterable {
            case success, warning, error
        }

        enum FeedbackToneID: String, Codable, CaseIterable {
            case filledDot, emptyDot, success, error, lessonStart
            case regionLeft, regionRight, regionTop, regionMiddle, regionBottom
            case shortPulse, longPulse
        }

        enum CoreHapticPatternID: String, Codable, CaseIterable {
            case sharpTap
            case softTap
            case doubleTap
            case tripleTap
            case shortBuzz
            case mediumBuzz
            case longBuzz
            case heartbeat
            case crescendo
            case decrescendo
            case rampUp
            case rampDown
            case staccato
            case wave
            case sosMorse
        }

        enum SystemVibrateVariant: String, Codable, CaseIterable {
            /// Единственный официальный ID: kSystemSoundID_Vibrate (4095).
            case standardPlaySystemSound
            /// То же 4095, но через AudioServicesPlayAlertSound — так рекомендует Apple.
            case standardPlayAlertSound
            /// Недокументированный ID из UISounds (SMSReceived_Vibrate). Может не работать.
            case smsVibrate1011
            case smsVibrate1311
            /// Недокументированный VibrateAlways. Может не работать.
            case vibrateAlways1352
        }
    }
}

enum SensoryCatalog {
    static let haptics: [SensoryCatalogItem] = impactHaptics + notificationHaptics + selectionHaptics + systemHaptics + coreHapticItems

    static let sounds: [SensoryCatalogItem] = appToneSounds + synthesizedSounds + systemSounds

    static let all: [SensoryCatalogItem] = haptics + sounds

    // MARK: - Haptics

    private static let impactIntensities: [Float?] = [nil, 0.25, 0.5, 0.75, 1.0]

    private static var impactHaptics: [SensoryCatalogItem] {
        SensoryCatalogItem.SensoryPayload.ImpactStyle.allCases.flatMap { style in
            impactIntensities.map { intensity in
                let intensityLabel = intensity.map { String(format: "%.0f%%", $0 * 100) } ?? "стандарт"
                return SensoryCatalogItem(
                    id: "impact.\(style.rawValue).\(intensityLabel)",
                    title: "Удар — \(impactStyleTitle(style))",
                    subtitle: "Интенсивность: \(intensityLabel)",
                    category: "UIKit · Удар (Impact)",
                    channel: .haptic,
                    payload: .impact(style: style, intensity: intensity)
                )
            }
        }
    }

    private static var notificationHaptics: [SensoryCatalogItem] {
        SensoryCatalogItem.SensoryPayload.NotificationType.allCases.map { type in
            SensoryCatalogItem(
                id: "notification.\(type.rawValue)",
                title: notificationTitle(type),
                subtitle: "UINotificationFeedbackGenerator",
                category: "UIKit · Уведомления",
                channel: .haptic,
                payload: .notification(type: type)
            )
        }
    }

    private static var selectionHaptics: [SensoryCatalogItem] {
        [
            SensoryCatalogItem(
                id: "selection.changed",
                title: "Изменение выбора",
                subtitle: "UISelectionFeedbackGenerator",
                category: "UIKit · Выбор",
                channel: .haptic,
                payload: .selection
            )
        ]
    }

    private static var systemHaptics: [SensoryCatalogItem] {
        SensoryCatalogItem.SensoryPayload.SystemVibrateVariant.allCases.map { variant in
            SensoryCatalogItem(
                id: "system.vibrate.\(variant.rawValue)",
                title: systemVibrateTitle(variant),
                subtitle: systemVibrateSubtitle(variant),
                category: systemVibrateCategory(variant),
                channel: .haptic,
                payload: .systemVibrate(variant)
            )
        }
    }

    private static func systemVibrateTitle(_ variant: SensoryCatalogItem.SensoryPayload.SystemVibrateVariant) -> String {
        switch variant {
        case .standardPlaySystemSound: return "Системная вибрация (4095)"
        case .standardPlayAlertSound: return "Системная вибрация · Alert (4095)"
        case .smsVibrate1011: return "SMS Vibrate (1011)"
        case .smsVibrate1311: return "SMS Vibrate (1311)"
        case .vibrateAlways1352: return "Vibrate Always (1352)"
        }
    }

    private static func systemVibrateSubtitle(_ variant: SensoryCatalogItem.SensoryPayload.SystemVibrateVariant) -> String {
        switch variant {
        case .standardPlaySystemSound:
            return "AudioServicesPlaySystemSound(kSystemSoundID_Vibrate) · официальный API"
        case .standardPlayAlertSound:
            return "AudioServicesPlayAlertSound(kSystemSoundID_Vibrate) · официальный API"
        case .smsVibrate1011:
            return "AudioServicesPlaySystemSound(1011) · недокументированный"
        case .smsVibrate1311:
            return "AudioServicesPlaySystemSound(1311) · недокументированный"
        case .vibrateAlways1352:
            return "AudioServicesPlaySystemSound(1352) · недокументированный"
        }
    }

    private static func systemVibrateCategory(_ variant: SensoryCatalogItem.SensoryPayload.SystemVibrateVariant) -> String {
        switch variant {
        case .standardPlaySystemSound, .standardPlayAlertSound:
            return "Система · AudioServices (официально)"
        case .smsVibrate1011, .smsVibrate1311, .vibrateAlways1352:
            return "Система · AudioServices (недокументировано)"
        }
    }

    private static var coreHapticItems: [SensoryCatalogItem] {
        SensoryCatalogItem.SensoryPayload.CoreHapticPatternID.allCases.map { pattern in
            SensoryCatalogItem(
                id: "coreHaptic.\(pattern.rawValue)",
                title: coreHapticTitle(pattern),
                subtitle: "Core Haptics · CHHapticEngine",
                category: coreHapticCategory(pattern),
                channel: .haptic,
                payload: .coreHaptic(pattern: pattern)
            )
        }
    }

    // MARK: - Sounds

    private static var appToneSounds: [SensoryCatalogItem] {
        SensoryCatalogItem.SensoryPayload.FeedbackToneID.allCases.map { toneID in
            let tone = FeedbackTone.from(catalogID: toneID)
            return SensoryCatalogItem(
                id: "appTone.\(toneID.rawValue)",
                title: appToneTitle(toneID),
                subtitle: String(format: "%.0f Гц · %.2f с", tone.frequency, tone.duration),
                category: "Тоны приложения",
                channel: .sound,
                payload: .appTone(toneID)
            )
        }
    }

    private static let synthesizedFrequencies: [Double] = [
        110, 146, 196, 220, 262, 294, 330, 349, 392, 440, 466, 523, 587, 659, 698,
        740, 784, 880, 988, 1_046, 1_175, 1_318, 1_566, 1_760, 2_093, 2_349, 2_793, 3_136
    ]

    private static var synthesizedSounds: [SensoryCatalogItem] {
        synthesizedFrequencies.flatMap { frequency in
            [0.06, 0.15, 0.3, 0.5].map { duration in
                SensoryCatalogItem(
                    id: "synth.\(Int(frequency)).\(Int(duration * 1000))",
                    title: String(format: "%.0f Гц", frequency),
                    subtitle: String(format: "Синтез · %.2f с", duration),
                    category: "Синтезированные тоны",
                    channel: .sound,
                    payload: .synthesizedTone(frequency: frequency, duration: duration)
                )
            }
        }
    }

    private static var systemSounds: [SensoryCatalogItem] {
        SystemSoundCatalog.entries.map { entry in
            SensoryCatalogItem(
                id: "systemSound.\(entry.id).\(entry.vibrate ? "alert" : "sound")",
                title: entry.title,
                subtitle: entry.subtitle,
                category: entry.category,
                channel: .sound,
                payload: .systemSound(id: entry.id, vibrate: entry.vibrate)
            )
        }
    }

    // MARK: - Labels

    private static func impactStyleTitle(_ style: SensoryCatalogItem.SensoryPayload.ImpactStyle) -> String {
        switch style {
        case .light: return "Лёгкий"
        case .medium: return "Средний"
        case .heavy: return "Тяжёлый"
        case .soft: return "Мягкий"
        case .rigid: return "Жёсткий"
        }
    }

    private static func notificationTitle(_ type: SensoryCatalogItem.SensoryPayload.NotificationType) -> String {
        switch type {
        case .success: return "Успех"
        case .warning: return "Предупреждение"
        case .error: return "Ошибка"
        }
    }

    private static func coreHapticTitle(_ pattern: SensoryCatalogItem.SensoryPayload.CoreHapticPatternID) -> String {
        switch pattern {
        case .sharpTap: return "Резкий тап"
        case .softTap: return "Мягкий тап"
        case .doubleTap: return "Двойной тап"
        case .tripleTap: return "Тройной тап"
        case .shortBuzz: return "Короткий гул"
        case .mediumBuzz: return "Средний гул"
        case .longBuzz: return "Длинный гул"
        case .heartbeat: return "Сердцебиение"
        case .crescendo: return "Нарастание"
        case .decrescendo: return "Затухание"
        case .rampUp: return "Плавный рост"
        case .rampDown: return "Плавное падение"
        case .staccato: return "Стаккато"
        case .wave: return "Волна"
        case .sosMorse: return "SOS (Морзе)"
        }
    }

    private static func coreHapticCategory(_ pattern: SensoryCatalogItem.SensoryPayload.CoreHapticPatternID) -> String {
        switch pattern {
        case .sharpTap, .softTap, .doubleTap, .tripleTap:
            return "Core Haptics · Короткие"
        case .shortBuzz, .mediumBuzz, .longBuzz, .rampUp, .rampDown:
            return "Core Haptics · Непрерывные"
        case .heartbeat, .crescendo, .decrescendo, .staccato, .wave, .sosMorse:
            return "Core Haptics · Паттерны"
        }
    }

    private static func appToneTitle(_ toneID: SensoryCatalogItem.SensoryPayload.FeedbackToneID) -> String {
        switch toneID {
        case .filledDot: return "Заполненная точка"
        case .emptyDot: return "Пустая точка"
        case .success: return "Успех"
        case .error: return "Ошибка"
        case .lessonStart: return "Начало урока"
        case .regionLeft: return "Зона: слева"
        case .regionRight: return "Зона: справа"
        case .regionTop: return "Зона: верх"
        case .regionMiddle: return "Зона: центр"
        case .regionBottom: return "Зона: низ"
        case .shortPulse: return "Короткий импульс"
        case .longPulse: return "Длинный импульс"
        }
    }
}

// MARK: - System sound table

private struct SystemSoundEntry {
    let id: SystemSoundID
    let title: String
    let subtitle: String
    let category: String
    let vibrate: Bool
}

private enum SystemSoundCatalog {
    static let entries: [SystemSoundEntry] = namedSounds + alertVariants

    private static let namedSounds: [SystemSoundEntry] = [
        // UI и сообщения
        entry(1000, "Новая почта", "Mail · New Mail", "Системные · Почта и сообщения"),
        entry(1001, "Почта отправлена", "Mail · Sent", "Системные · Почта и сообщения"),
        entry(1002, "Голосовая почта", "Voicemail", "Системные · Почта и сообщения"),
        entry(1003, "Входящее сообщение", "Received Message", "Системные · Почта и сообщения"),
        entry(1004, "Отправленное сообщение", "Sent Message", "Системные · Почта и сообщения"),
        entry(1005, "Будильник", "Alarm", "Системные · Почта и сообщения"),
        entry(1006, "Низкий заряд", "Low Power", "Системные · Почта и сообщения"),
        entry(1007, "SMS · Tri-tone", "SMS Received", "Системные · Рингтоны SMS"),
        entry(1008, "SMS · Chime", "SMS Received", "Системные · Рингтоны SMS"),
        entry(1009, "SMS · Glass", "SMS Received", "Системные · Рингтоны SMS"),
        entry(1010, "SMS · Horn", "SMS Received", "Системные · Рингтоны SMS"),
        entry(1011, "SMS · Bell", "SMS Received", "Системные · Рингтоны SMS"),
        entry(1012, "SMS · Electronic", "SMS Received", "Системные · Рингтоны SMS"),
        entry(1013, "SMS · Anticipate", "SMS Received", "Системные · Рингтоны SMS"),
        entry(1014, "SMS · Bloom", "SMS Received", "Системные · Рингтоны SMS"),
        entry(1015, "SMS · Calypso", "SMS Received", "Системные · Рингтоны SMS"),
        entry(1016, "SMS · Choo Choo", "SMS Received", "Системные · Рингтоны SMS"),
        entry(1017, "SMS · Descent", "SMS Received", "Системные · Рингтоны SMS"),
        entry(1018, "SMS · Fanfare", "SMS Received", "Системные · Рингтоны SMS"),
        entry(1019, "SMS · Ladder", "SMS Received", "Системные · Рингтоны SMS"),
        entry(1020, "SMS · Minuet", "SMS Received", "Системные · Рингтоны SMS"),
        entry(1021, "SMS · News Flash", "SMS Received", "Системные · Рингтоны SMS"),
        entry(1022, "SMS · Noir", "SMS Received", "Системные · Рингтоны SMS"),
        entry(1023, "SMS · Sherwood Forest", "SMS Received", "Системные · Рингтоны SMS"),
        entry(1024, "SMS · Spell", "SMS Received", "Системные · Рингтоны SMS"),
        entry(1025, "SMS · Suspense", "SMS Received", "Системные · Рингтоны SMS"),
        entry(1026, "SMS · Telegraph", "SMS Received", "Системные · Рингтоны SMS"),
        entry(1027, "SMS · Tiptoes", "SMS Received", "Системные · Рингтоны SMS"),
        entry(1028, "SMS · Typewriters", "SMS Received", "Системные · Рингтоны SMS"),
        entry(1029, "SMS · Update", "SMS Received", "Системные · Рингтоны SMS"),
        entry(1030, "USSD Alert", "USSD", "Системные · SIM и сеть"),
        entry(1031, "SIM · Call Dropped", "SIM Toolkit", "Системные · SIM и сеть"),
        entry(1032, "SIM · General Beep", "SIM Toolkit", "Системные · SIM и сеть"),
        entry(1033, "SIM · Negative ACK", "SIM Toolkit", "Системные · SIM и сеть"),
        entry(1034, "SIM · Positive ACK", "SIM Toolkit", "Системные · SIM и сеть"),
        entry(1035, "SIM · SMS", "SIM Toolkit", "Системные · SIM и сеть"),
        entry(1036, "Tink", "Key Press", "Системные · Клавиатура"),
        entry(1037, "CT Busy", "Call Tone", "Системные · SIM и сеть"),
        entry(1038, "CT Congestion", "Call Tone", "Системные · SIM и сеть"),
        // PIN и тоны
        entry(1050, "SIM Toolkit Tone", "SIM Toolkit", "Системные · SIM и сеть"),
        entry(1051, "PIN · нажатие", "PIN Key", "Системные · PIN"),
        entry(1052, "PIN · удаление", "PIN Delete", "Системные · PIN"),
        entry(1053, "PIN · обычный", "PIN Normal", "Системные · PIN"),
        entry(1054, "Alert General", "Alert", "Системные · Оповещения"),
        entry(1055, "Alert Busy", "Alert", "Системные · Оповещения"),
        entry(1056, "Alert Congestion", "Alert", "Системные · Оповещения"),
        entry(1057, "Tock", "Key Press", "Системные · Клавиатура"),
        // Рингтоны и камера
        entry(1100, "Рингтон 1", "Ringtone", "Системные · Рингтоны"),
        entry(1103, "Рингтон 2", "Ringtone", "Системные · Рингтоны"),
        entry(1104, "Рингтон 3", "Ringtone", "Системные · Рингтоны"),
        entry(1105, "Рингтон 4", "Ringtone", "Системные · Рингтоны"),
        entry(1106, "Рингтон 5", "Ringtone", "Системные · Рингтоны"),
        entry(1107, "Tink 2", "UI Sound", "Системные · UI"),
        entry(1108, "Затвор камеры", "Photo Shutter", "Системные · Камера и запись"),
        entry(1109, "Встряхивание", "Shake", "Системные · UI"),
        entry(1110, "JBL · Begin", "JBL", "Системные · JBL"),
        entry(1111, "JBL · End", "JBL", "Системные · JBL"),
        entry(1112, "JBL · Confirm", "JBL", "Системные · JBL"),
        entry(1113, "JBL · Cancel", "JBL", "Системные · JBL"),
        entry(1114, "Начало записи", "Recording", "Системные · Камера и запись"),
        entry(1115, "Конец записи", "Recording", "Системные · Камера и запись"),
        entry(1116, "JBL · Ambiguous", "JBL", "Системные · JBL"),
        entry(1117, "JBL · Other", "JBL", "Системные · JBL"),
        entry(1118, "Конец записи видео", "End Video Recording", "Системные · Камера и запись"),
        // Клавиши
        entry(1150, "Нажатие клавиши", "Key Press", "Системные · Клавиатура"),
        entry(1151, "Модификатор 1", "Key Modifier", "Системные · Клавиатура"),
        entry(1152, "Модификатор 2", "Key Modifier", "Системные · Клавиатура"),
        entry(1153, "Модификатор 3", "Key Modifier", "Системные · Клавиатура"),
        entry(1154, "Модификатор 4", "Key Modifier", "Системные · Клавиатура"),
        // Email
        entry(1200, "Email · новое", "Email", "Системные · Почта и сообщения"),
        entry(1201, "Email · отправлено", "Email", "Системные · Почта и сообщения"),
        entry(1202, "Email · удалено", "Email", "Системные · Почта и сообщения"),
        entry(1203, "Email · получено", "Email", "Системные · Почта и сообщения"),
        entry(1204, "Email · сохранено", "Email", "Системные · Почта и сообщения"),
        entry(1205, "Email · ошибка", "Email", "Системные · Почта и сообщения"),
        entry(1206, "Email · незначительное", "Email", "Системные · Почта и сообщения"),
        entry(1207, "Email · незначительное 2", "Email", "Системные · Почта и сообщения"),
        entry(1208, "Email · прочитано", "Email", "Системные · Почта и сообщения"),
        entry(1209, "Email · помечено", "Email", "Системные · Почта и сообщения"),
        entry(1210, "Email · результат поиска", "Email", "Системные · Почта и сообщения"),
        entry(1211, "Email · непрочитано", "Email", "Системные · Почта и сообщения"),
        entry(1212, "Email · удалено 2", "Email", "Системные · Почта и сообщения"),
        // Generic alerts
        entry(1254, "Generic Alert 1", "Alert", "Системные · Оповещения"),
        entry(1255, "Generic Alert 2", "Alert", "Системные · Оповещения"),
        entry(1256, "Generic Alert 3", "Alert", "Системные · Оповещения"),
        // Lock / unlock
        entry(1300, "Блокировка", "Lock Sound", "Системные · Блокировка"),
        entry(1301, "Разблокировка", "Unlock Sound", "Системные · Блокировка"),
        entry(1302, "Клик клавиши", "Key Click", "Системные · Клавиатура"),
        entry(1303, "Модификатор клавиши 1", "Key Modifier", "Системные · Клавиатура"),
        entry(1304, "Модификатор клавиши 2", "Key Modifier", "Системные · Клавиатура"),
        entry(1305, "Модификатор клавиши 3", "Key Modifier", "Системные · Клавиатура"),
        entry(1306, "Модификатор клавиши 4", "Key Modifier", "Системные · Клавиатура"),
        entry(1307, "Модификатор клавиши 5", "Key Modifier", "Системные · Клавиатура"),
        entry(1308, "Модификатор клавиши 6", "Key Modifier", "Системные · Клавиатура"),
        entry(1309, "Модификатор клавиши 7", "Key Modifier", "Системные · Клавиатура"),
        entry(1310, "Модификатор клавиши 8", "Key Modifier", "Системные · Клавиатура"),
        entry(1311, "Модификатор клавиши 9", "Key Modifier", "Системные · Клавиатура"),
        entry(1312, "Модификатор клавиши 10", "Key Modifier", "Системные · Клавиатура"),
        entry(1313, "Модификатор клавиши 11", "Key Modifier", "Системные · Клавиатура"),
        entry(1314, "Модификатор клавиши 12", "Key Modifier", "Системные · Клавиатура"),
        entry(1315, "Модификатор клавиши 13", "Key Modifier", "Системные · Клавиатура"),
        // Siri
        entry(1320, "Siri · старт", "Siri", "Системные · Siri"),
        entry(1321, "Siri · стоп", "Siri", "Системные · Siri"),
        entry(1322, "Siri · ошибка", "Siri", "Системные · Siri"),
        // Activity
        entry(1350, "Активность · старт", "Activity", "Системные · Активность"),
        entry(1351, "Активность · цель", "Activity Goal", "Системные · Активность"),
    ] + undocumentedRange(1039, 1049, category: "Системные · Прочие") +
        undocumentedRange(1101, 1102, category: "Системные · Прочие") +
        undocumentedRange(1119, 1149, category: "Системные · Прочие") +
        undocumentedRange(1213, 1253, category: "Системные · Прочие") +
        undocumentedRange(1257, 1299, category: "Системные · Прочие") +
        undocumentedRange(1316, 1319, category: "Системные · Прочие") +
        undocumentedRange(1323, 1349, category: "Системные · Прочие") +
        undocumentedRange(1352, 1360, category: "Системные · Прочие")

    private static var alertVariants: [SystemSoundEntry] {
        namedSounds
            .filter { !$0.vibrate && $0.id != 1118 && $0.id < 1352 }
            .map { sound in
                SystemSoundEntry(
                    id: sound.id,
                    title: "\(sound.title) + вибро",
                    subtitle: "AudioServicesPlayAlertSound · ID \(sound.id)",
                    category: sound.category + " (с вибрацией)",
                    vibrate: true
                )
            }
    }

    private static func entry(_ id: SystemSoundID, _ title: String, _ subtitle: String, _ category: String) -> SystemSoundEntry {
        SystemSoundEntry(id: id, title: title, subtitle: "AudioServicesPlaySystemSound · ID \(id) · \(subtitle)", category: category, vibrate: false)
    }

    private static func undocumentedRange(_ start: SystemSoundID, _ end: SystemSoundID, category: String) -> [SystemSoundEntry] {
        guard start <= end else { return [] }
        return (start...end).map { id in
            SystemSoundEntry(
                id: id,
                title: "Системный звук #\(id)",
                subtitle: "AudioServicesPlaySystemSound · ID \(id)",
                category: category,
                vibrate: false
            )
        }
    }
}

// MARK: - FeedbackTone bridge

extension FeedbackTone {
    static func from(catalogID: SensoryCatalogItem.SensoryPayload.FeedbackToneID) -> FeedbackTone {
        switch catalogID {
        case .filledDot: return .filledDot
        case .emptyDot: return .emptyDot
        case .success: return .success
        case .error: return .error
        case .lessonStart: return .lessonStart
        case .regionLeft: return .regionLeft
        case .regionRight: return .regionRight
        case .regionTop: return .regionTop
        case .regionMiddle: return .regionMiddle
        case .regionBottom: return .regionBottom
        case .shortPulse: return .shortPulse
        case .longPulse: return .longPulse
        }
    }
}

typealias SystemSoundID = UInt32
