import CoreHaptics
import SwiftUI

struct CustomHapticBuilderView: View {
    @EnvironmentObject private var appState: AppState
    let role: SensoryFeedbackRole

    @State private var definition: CustomHapticDefinition

    init(role: SensoryFeedbackRole, initial: CustomHapticDefinition = CustomHapticDefinition()) {
        self.role = role
        _definition = State(initialValue: initial)
    }

    private var settings: AppSettings {
        appState.settings
    }

    private var isAssigned: Bool {
        settings.hapticSelections[role.rawValue] == CustomHapticDefinition.catalogItemID
    }

    var body: some View {
        Form {
            infoSection
            typeSection
            parametersSection
            if definition.kind == .continuous {
                envelopeSection
            } else {
                repeatSection
            }
            actionsSection
        }
        .navigationTitle("Своя вибрация")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let saved = settings.customHapticByRole[role.rawValue] {
                definition = saved
            }
        }
    }

    private var infoSection: some View {
        Section {
            LabeledContent("Роль", value: role.title)
            if isAssigned {
                Label("Назначено для этой роли", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.subheadline)
            }
            Text(definition.summary)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var typeSection: some View {
        Section("Тип") {
            Picker("Тип вибрации", selection: $definition.kind) {
                ForEach(CustomHapticEventKind.allCases) { kind in
                    Text(kind.title).tag(kind)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Тип вибрации")
        }
    }

    private var parametersSection: some View {
        Section("Параметры") {
            sliderRow(
                title: "Сила",
                value: $definition.intensity,
                range: 0.1...1,
                format: "%.0f%%"
            )
            sliderRow(
                title: "Резкость",
                value: $definition.sharpness,
                range: 0...1,
                format: "%.0f%%",
                hint: "0 — мягко, 1 — резко"
            )

            if definition.kind == .continuous {
                sliderRow(
                    title: "Длительность",
                    value: $definition.duration,
                    range: 0.05...2.0,
                    step: 0.05,
                    format: "%.2f с"
                )
            }
        }
    }

    private var envelopeSection: some View {
        Section("Огибающая") {
            sliderRow(
                title: "Нарастание",
                value: $definition.attack,
                range: 0...0.5,
                step: 0.01,
                format: "%.2f с"
            )
            sliderRow(
                title: "Затухание",
                value: $definition.decay,
                range: 0...0.5,
                step: 0.01,
                format: "%.2f с"
            )
        }
    }

    private var repeatSection: some View {
        Section("Повторы") {
            Stepper("Число ударов: \(definition.repeatCount)", value: $definition.repeatCount, in: 1...8)
                .accessibilityLabel("Число ударов")

            if definition.repeatCount > 1 {
                sliderRow(
                    title: "Пауза между ударами",
                    value: $definition.repeatInterval,
                    range: 0.04...0.5,
                    step: 0.02,
                    format: "%.2f с"
                )
            }
        }
    }

    private var actionsSection: some View {
        Section {
            Button {
                preview()
            } label: {
                Label("Проиграть", systemImage: "waveform.path")
            }
            .accessibilityLabel("Проиграть вибрацию с текущими параметрами")

            Button {
                assignToRole()
            } label: {
                Label("Назначить для «\(role.title)»", systemImage: "checkmark.circle")
            }
            .accessibilityLabel("Назначить эту вибрацию для роли \(role.title)")

            if isAssigned {
                Button(role: .destructive) {
                    clearAssignment()
                } label: {
                    Label("Сбросить назначение", systemImage: "arrow.uturn.backward")
                }
            }
        } footer: {
            if !CHHapticEngine.capabilitiesForHardware().supportsHaptics {
                Text("Core Haptics недоступен — будет короткая системная вибрация.")
            } else {
                Text("Параметры сохраняются и используются в уроках для выбранной роли. Глобальный слайдер «Интенсивность haptic» в настройках масштабирует силу.")
            }
        }
    }

    private func sliderRow(
        title: String,
        value: Binding<Float>,
        range: ClosedRange<Float>,
        step: Float = 0.05,
        format: String,
        hint: String? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                Spacer()
                Text(String(format: format, value.wrappedValue * (format.contains("%%") ? 100 : 1)))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Slider(value: value, in: range, step: step)
                .accessibilityLabel(title)
            if let hint {
                Text(hint)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private func preview() {
        SensoryCatalogPlayer.shared.playCustomHaptic(
            definition,
            scale: settings.hapticIntensity
        )
    }

    private func assignToRole() {
        var updated = settings
        updated.customHapticByRole[role.rawValue] = definition
        updated.hapticSelections[role.rawValue] = CustomHapticDefinition.catalogItemID
        appState.store.updateSettings(updated)
        preview()
    }

    private func clearAssignment() {
        var updated = settings
        updated.hapticSelections.removeValue(forKey: role.rawValue)
        updated.customHapticByRole.removeValue(forKey: role.rawValue)
        appState.store.updateSettings(updated)
    }
}

#Preview {
    NavigationStack {
        CustomHapticBuilderView(role: .success)
            .environmentObject(AppState())
    }
}
