import SwiftUI

struct RootView: View {
    @StateObject private var appState = AppState()

    var body: some View {
        Group {
            if appState.hasCompletedOnboarding {
                MainTabView()
            } else {
                NavigationStack {
                    OnboardingView()
                }
            }
        }
        .environmentObject(appState)
    }
}

struct MainTabView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        TabView {
            NavigationStack {
                LessonsListView()
            }
            .tabItem {
                Label("Уроки", systemImage: "textformat.abc")
            }
            .accessibilityLabel("Уроки")

            NavigationStack {
                ProgressDashboardView()
            }
            .tabItem {
                Label("Прогресс", systemImage: "chart.bar.fill")
            }
            .accessibilityLabel("Прогресс")

            NavigationStack {
                SensoryCatalogView()
            }
            .tabItem {
                Label("Сигналы", systemImage: "waveform")
            }
            .accessibilityLabel("Каталог вибраций и звуков")

            NavigationStack {
                RelayHubView()
            }
            .tabItem {
                Label("Связь", systemImage: "link")
            }
            .accessibilityLabel("Связь между устройствами")

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Настройки", systemImage: "gearshape.fill")
            }
            .accessibilityLabel("Настройки")
        }
    }
}

struct HomeView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Dotform")
                        .font(.largeTitle.bold())
                        .accessibilityAddTraits(.isHeader)
                    Text("Обучение шрифту Брайля через пространственное восприятие экрана")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }

            if let profile = appState.profile {
                Section("Текущий профиль") {
                    Text(profile.title)
                        .accessibilityLabel("Профиль: \(profile.title)")
                    Text(profile.accessibilityHint)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Быстрый старт") {
                NavigationLink("Начать урок") {
                    LessonsListView()
                }
                .accessibilityLabel("Перейти к списку уроков")

                if let recommended = recommendedLetter {
                    NavigationLink("Рекомендуемый урок: \(recommended.character)") {
                        LessonView(letter: recommended)
                    }
                    .accessibilityLabel("Рекомендуемый урок, буква \(recommended.character)")
                }
            }

            Section {
                NavigationLink("Сменить профиль") {
                    ProfileSelectionView()
                }
                .accessibilityLabel("Сменить профиль пользователя")
            }
        }
        .navigationTitle("Главная")
    }

    private var recommendedLetter: BrailleLetter? {
        appState.store.progress.recommendedLetters(
            from: appState.settings.activeLetters,
            settings: appState.settings
        ).first
    }
}

#Preview {
    RootView()
}
