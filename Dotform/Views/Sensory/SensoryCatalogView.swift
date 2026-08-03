import CoreHaptics
import SwiftUI

struct SensoryCatalogView: View {
    @EnvironmentObject private var appState: AppState
    @State private var channel: SensoryChannel = .haptic
    @State private var selectedRole: SensoryFeedbackRole = .filledDot
    @State private var searchText = ""

    private var settings: AppSettings {
        appState.settings
    }

    var body: some View {
        VStack(spacing: 0) {
            rolePicker
            channelPicker
            catalogList
        }
        .navigationTitle("Сигналы")
        .searchable(text: $searchText, prompt: "Поиск по названию")
    }

    private var rolePicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Назначить для")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(SensoryFeedbackRole.allCases) { role in
                        Button {
                            selectedRole = role
                        } label: {
                            Text(role.title)
                                .font(.caption.weight(selectedRole == role ? .semibold : .regular))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(selectedRole == role ? Color.accentColor : Color(.secondarySystemFill))
                                .foregroundStyle(selectedRole == role ? Color.white : Color.primary)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Роль: \(role.title)")
                        .accessibilityAddTraits(selectedRole == role ? .isSelected : [])
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 10)
        .background(Color(.systemGroupedBackground))
    }

    private var channelPicker: some View {
        Picker("Канал", selection: $channel) {
            ForEach(SensoryChannel.allCases) { item in
                Text(item.title).tag(item)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.bottom, 8)
        .accessibilityLabel("Канал обратной связи")
    }

    private var catalogList: some View {
        List {
            if channel == .haptic {
                if !supportsCoreHaptics {
                    Section {
                        Label("Core Haptics недоступен на этом устройстве — паттерны воспроизведут системную вибрацию.", systemImage: "iphone.slash")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Section {
                    Text("Через AudioServices для вибрации без звука Apple официально даёт только kSystemSoundID_Vibrate (4095). Остальные варианты вибрации — в разделах UIKit и Core Haptics. ID 1011, 1311, 1352 — недокументированные, могут молчать или исчезнуть в будущих iOS.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                customHapticSection
                hapticSections
            } else {
                soundSections
            }
        }
        .listStyle(.insetGrouped)
    }

    @ViewBuilder
    private var customHapticSection: some View {
        Section {
            NavigationLink {
                CustomHapticBuilderView(
                    role: selectedRole,
                    initial: settings.customHapticByRole[selectedRole.rawValue] ?? CustomHapticDefinition()
                )
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Своя вибрация")
                            .font(.body.weight(.medium))
                        if isCustomHapticSelected(for: selectedRole) {
                            Text(settings.customHapticByRole[selectedRole.rawValue]?.summary ?? "")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Собрать: сила, мягкость, длительность")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    if isCustomHapticSelected(for: selectedRole) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.accentColor)
                    }
                }
            }
            .accessibilityLabel("Конструктор своей вибрации для роли \(selectedRole.title)")

            if isCustomHapticSelected(for: selectedRole) {
                Button {
                    previewCustomHaptic(for: selectedRole)
                } label: {
                    Label("Проиграть свою вибрацию", systemImage: "waveform.path")
                }
            }
        } header: {
            Text("Конструктор")
        }
    }

    @ViewBuilder
    private var hapticSections: some View {
        ForEach(groupedItems(SensoryCatalog.haptics), id: \.category) { group in
            Section {
                ForEach(group.items) { item in
                    catalogRow(item)
                }
            } header: {
                Text("\(group.category) (\(group.items.count))")
            }
        }
    }

    @ViewBuilder
    private var soundSections: some View {
        ForEach(groupedItems(SensoryCatalog.sounds), id: \.category) { group in
            Section {
                ForEach(group.items) { item in
                    catalogRow(item)
                }
            } header: {
                Text("\(group.category) (\(group.items.count))")
            }
        }
    }

    private func catalogRow(_ item: SensoryCatalogItem) -> some View {
        let isSelected = selectedItemID(for: selectedRole, channel: channel) == item.id

        return HStack(spacing: 12) {
            Button {
                assign(item, to: selectedRole)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                        .font(.title3)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title)
                            .font(.body)
                            .foregroundStyle(.primary)
                        Text(item.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(item.title)
            .accessibilityValue(isSelected ? "Выбрано для \(selectedRole.title)" : "Не выбрано")
            .accessibilityHint("Нажмите, чтобы назначить для роли \(selectedRole.title)")

            Spacer(minLength: 0)

            Button {
                SensoryCatalogPlayer.shared.play(
                    item,
                    volume: settings.auxiliarySoundVolume,
                    hapticIntensity: settings.hapticIntensity
                )
            } label: {
                Image(systemName: channel == .haptic ? "waveform.path" : "speaker.wave.2.fill")
                    .font(.title3)
                    .frame(width: 44, height: 44)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(channel == .haptic ? "Почувствовать" : "Прослушать")
            .accessibilityHint(item.title)
        }
        .padding(.vertical, 2)
    }

    private var supportsCoreHaptics: Bool {
        CHHapticEngine.capabilitiesForHardware().supportsHaptics
    }

    private func groupedItems(_ items: [SensoryCatalogItem]) -> [(category: String, items: [SensoryCatalogItem])] {
        let filtered = items.filter { item in
            guard !searchText.isEmpty else { return true }
            let query = searchText.lowercased()
            return item.title.lowercased().contains(query)
                || item.subtitle.lowercased().contains(query)
                || item.category.lowercased().contains(query)
        }

        let grouped = Dictionary(grouping: filtered, by: \.category)
        return grouped.keys.sorted().map { key in
            (category: key, items: grouped[key]!.sorted { $0.title < $1.title })
        }
    }

    private func selectedItemID(for role: SensoryFeedbackRole, channel: SensoryChannel) -> String? {
        switch channel {
        case .haptic: settings.hapticSelections[role.rawValue]
        case .sound: settings.soundSelections[role.rawValue]
        }
    }

    private func assign(_ item: SensoryCatalogItem, to role: SensoryFeedbackRole) {
        var updated = settings
        switch item.channel {
        case .haptic:
            updated.hapticSelections[role.rawValue] = item.id
            if item.id != CustomHapticDefinition.catalogItemID {
                updated.customHapticByRole.removeValue(forKey: role.rawValue)
            }
        case .sound:
            updated.soundSelections[role.rawValue] = item.id
        }
        appState.store.updateSettings(updated)
        SensoryCatalogPlayer.shared.play(
            item,
            volume: updated.auxiliarySoundVolume,
            hapticIntensity: updated.hapticIntensity
        )
    }

    private func isCustomHapticSelected(for role: SensoryFeedbackRole) -> Bool {
        settings.hapticSelections[role.rawValue] == CustomHapticDefinition.catalogItemID
    }

    private func previewCustomHaptic(for role: SensoryFeedbackRole) {
        guard let custom = settings.customHapticByRole[role.rawValue] else { return }
        SensoryCatalogPlayer.shared.playCustomHaptic(custom, scale: settings.hapticIntensity)
    }
}

#Preview {
    NavigationStack {
        SensoryCatalogView()
            .environmentObject(AppState())
    }
}
