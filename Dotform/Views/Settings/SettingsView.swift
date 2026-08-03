import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var localSettings: AppSettings

    init() {
        _localSettings = State(initialValue: AppSettings())
    }

    var body: some View {
        Form {
            generalSection
            hapticSection
            deafBlindSection
            parentSection
        }
        .navigationTitle("Настройки")
        .onAppear {
            localSettings = appState.settings
        }
        .onChange(of: localSettings) { _, newValue in
            appState.store.updateSettings(newValue)
        }
    }

    private var generalSection: some View {
        Group {
            Section("Режим обучения") {
            Picker("Профиль ребёнка", selection: $localSettings.childProfile) {
                ForEach(UserProfile.allCases.filter(\.isChildProfile)) { profile in
                    Text(profile.title).tag(profile)
                }
            }
            .accessibilityLabel("Профиль ребёнка. Определяет звук и вибрацию в уроках")
            .accessibilityValue(localSettings.childProfile.title)

            if localSettings.childProfile == .deafBlindChild {
                Text("Звук и речь отключены. Только вибрация.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("В режиме слепоглухого ребёнка звук и речь отключены, работает только вибрация")
            } else {
                Text("Звук, речь и вибрация включены.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }

        Section("Алфавит") {
            Picker("Язык Брайля", selection: $localSettings.activeScript) {
                ForEach(BrailleScriptID.allCases) { script in
                    Text(script.title).tag(script)
                }
            }
            .accessibilityLabel("Язык алфавита Брайля")
            .onChange(of: localSettings.activeScript) { _, _ in
                localSettings.enabledGlyphIDs = []
            }

            Toggle("В связи: точки по очереди", isOn: $localSettings.relayPlayDotsInSequence)
                .accessibilityLabel("В режиме связи проигрывать точки символа по очереди")
        }

        Section("Общие") {
            Picker("Язык", selection: $localSettings.language) {
                ForEach(AppLanguage.allCases) { lang in
                    Text(lang.title).tag(lang)
                }
            }
            .accessibilityLabel("Язык приложения")
            .accessibilityValue(localSettings.language.title)

            VStack(alignment: .leading) {
                Text("Скорость озвучивания")
                Slider(value: $localSettings.speechRate, in: 0.2...0.6, step: 0.05)
                    .accessibilityLabel("Скорость озвучивания")
                    .accessibilityValue("\(Int(localSettings.speechRate * 100)) процентов")
            }

            VStack(alignment: .leading) {
                Text("Громкость вспомогательных звуков")
                Slider(value: $localSettings.auxiliarySoundVolume, in: 0...1, step: 0.1)
                    .accessibilityLabel("Громкость вспомогательных звуков")
                    .accessibilityValue("\(Int(localSettings.auxiliarySoundVolume * 100)) процентов")
            }

            Picker("Уровень сложности", selection: $localSettings.difficulty) {
                ForEach(DifficultyLevel.allCases) { level in
                    Text(level.title).tag(level)
                }
            }
            .accessibilityLabel("Уровень сложности")

            Toggle("Автопереход после правильного ответа", isOn: $localSettings.autoAdvanceOnSuccess)
                .accessibilityLabel("Автопереход после правильного ответа")
                .accessibilityValue(localSettings.autoAdvanceOnSuccess ? "Включено" : "Выключено")

            Toggle("Показывать точки на экране", isOn: $localSettings.showDotsVisually)
                .accessibilityLabel("Показывать точки на экране для проверки зрения")

            Toggle("Озвучивать зоны", isOn: $localSettings.spokenZoneFeedback)
                .accessibilityLabel("Озвучивать названия зон: слева, справа, точка, пусто")
            }
        }
    }

    private var hapticSection: some View {
        Section("Тактильная обратная связь") {
            Toggle("Включить haptic", isOn: $localSettings.hapticEnabled)
                .accessibilityLabel("Включить тактильную обратную связь")
                .accessibilityValue(localSettings.hapticEnabled ? "Включено" : "Выключено")

            VStack(alignment: .leading) {
                Text("Интенсивность haptic")
                Slider(value: $localSettings.hapticIntensity, in: 0.2...1, step: 0.1)
                    .disabled(!localSettings.hapticEnabled)
                    .accessibilityLabel("Интенсивность тактильной обратной связи")
            }

            VStack(alignment: .leading) {
                Text("Продолжительность сигналов")
                Slider(value: $localSettings.signalDuration, in: 0.1...1, step: 0.1)
                    .accessibilityLabel("Продолжительность сигналов")
            }
        }
    }

    private var deafBlindSection: some View {
        Section("Режим слепоглухих детей") {
            Toggle("Вибрация как основной канал", isOn: $localSettings.vibrationPrimaryChannel)
                .accessibilityLabel("Вибрация как основной канал")

            Toggle("Параллельный звук при остаточном слухе", isOn: $localSettings.parallelSoundForResidualHearing)
                .accessibilityLabel("Параллельный звук при остаточном слухе")

            Toggle("Альтернативные вибро-паттерны", isOn: $localSettings.useAlternativeHapticPatterns)
                .accessibilityLabel("Альтернативные вибро-паттерны")

            Toggle("Режим модельной руки", isOn: $localSettings.modelHandEnabled)
                .accessibilityLabel("Режим модельной руки")

            VStack(alignment: .leading) {
                Text("Пауза между инструкцией и проверкой")
                Slider(value: $localSettings.instructionPauseDuration, in: 0.5...5, step: 0.5)
                    .accessibilityLabel("Пауза между инструкцией и проверкой")
                    .accessibilityValue(String(format: "%.1f секунд", localSettings.instructionPauseDuration))
            }

            Picker("Чувствительность к ошибке", selection: $localSettings.errorSensitivity) {
                ForEach(ErrorSensitivity.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .accessibilityLabel("Чувствительность к ошибке")
        }
    }

    private var parentSection: some View {
        Section("Родительские настройки") {
            Toggle("Повтор изученных букв", isOn: $localSettings.repeatLearnedLetters)
                .accessibilityLabel("Повтор изученных букв")

            NavigationLink("Набор букв для обучения") {
                LetterSelectionView(
                    scriptID: localSettings.activeScript,
                    enabledGlyphIDs: $localSettings.enabledGlyphIDs
                )
            }
            .accessibilityLabel("Выбор набора букв для обучения")

            Stepper(
                "Лимит сессии: \(localSettings.sessionLengthLimitMinutes.map { "\($0) мин" } ?? "без ограничения")",
                value: Binding(
                    get: { localSettings.sessionLengthLimitMinutes ?? 0 },
                    set: { localSettings.sessionLengthLimitMinutes = $0 > 0 ? $0 : nil }
                ),
                in: 0...120,
                step: 5
            )
            .accessibilityLabel("Ограничение длины сессии в минутах")
        }
    }
}

private struct LetterSelectionView: View {
    let scriptID: BrailleScriptID
    @Binding var enabledGlyphIDs: Set<String>

    private var letters: [BrailleGlyph] {
        BrailleCatalog.letters(for: scriptID)
    }

    private var allEnabled: Bool {
        enabledGlyphIDs.isEmpty || enabledGlyphIDs.count == letters.count
    }

    var body: some View {
        List {
            Section {
                Toggle("Все буквы", isOn: Binding(
                    get: { allEnabled },
                    set: { enabled in
                        enabledGlyphIDs = enabled ? [] : Set(letters.prefix(1).map(\.id))
                    }
                ))
            }
            ForEach(letters) { letter in
                Toggle(isOn: binding(for: letter)) {
                    Text("Буква \(letter.display)")
                }
                .accessibilityLabel("Буква \(letter.display)")
                .accessibilityValue(isEnabled(letter) ? "Включена" : "Выключена")
            }
        }
        .navigationTitle("Буквы · \(scriptID.shortTitle)")
    }

    private func isEnabled(_ letter: BrailleGlyph) -> Bool {
        enabledGlyphIDs.isEmpty || enabledGlyphIDs.contains(letter.id)
    }

    private func binding(for letter: BrailleGlyph) -> Binding<Bool> {
        Binding(
            get: { isEnabled(letter) },
            set: { enabled in
                if enabledGlyphIDs.isEmpty {
                    enabledGlyphIDs = Set(letters.map(\.id))
                }
                if enabled {
                    enabledGlyphIDs.insert(letter.id)
                } else {
                    enabledGlyphIDs.remove(letter.id)
                }
                if enabledGlyphIDs.count == letters.count {
                    enabledGlyphIDs = []
                }
            }
        )
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(AppState())
    }
}
