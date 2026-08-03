import SwiftUI

struct ParentSectionView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        List {
            Section {
                Text("Раздел полностью доступен через VoiceOver. Все настройки имеют текстовые описания.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("Управление") {
                NavigationLink("Профиль ребёнка") {
                    ProfileSelectionView()
                }
                .accessibilityLabel("Выбор профиля ребёнка")

                NavigationLink("Настройки обучения") {
                    SettingsView()
                }
                .accessibilityLabel("Настройки обучения")

                NavigationLink("Прогресс и статистика") {
                    ProgressDashboardView()
                }
                .accessibilityLabel("Прогресс и статистика ребёнка")
            }

            Section("Журнал ошибок") {
                let errors = appState.store.progress.sessions.filter { !$0.succeeded }.suffix(15).reversed()
                if errors.isEmpty {
                    Text("Ошибок пока нет.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(errors)) { session in
                        HStack {
                            Text("Буква \(session.letterCharacter)")
                            Spacer()
                            Text(session.date, style: .date)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityLabel("Ошибка по букве \(session.letterCharacter), \(session.date.formatted(date: .abbreviated, time: .shortened))")
                    }
                }
            }

            Section("Текущий профиль") {
                if let profile = appState.profile {
                    Text(profile.title)
                        .accessibilityLabel("Текущий профиль: \(profile.title)")
                } else {
                    Text("Не выбран")
                }

                Text("Режим обратной связи: \(appState.settings.feedbackMode.title)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Родителям и педагогам")
    }
}

#Preview {
    NavigationStack {
        ParentSectionView()
            .environmentObject(AppState())
    }
}
