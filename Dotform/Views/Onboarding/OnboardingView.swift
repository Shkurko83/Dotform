import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var appState: AppState

    @State private var page = 0

    private let pages: [(title: String, body: String)] = [
        (
            "Дополнение к реальному Брайлю",
            "Это приложение не заменяет выпуклый брайлевский шрифт. Оно тренирует пространственное восприятие ячейки и помогает запомнить буквы."
        ),
        (
            "Полноэкранная ячейка",
            "Экран делится на шесть крупных зон — как точки брайлевской ячейки. Ребёнок исследует их пальцами и запоминает форму буквы."
        ),
        (
            "Режимы обучения",
            "Для незрячих детей — голос, звук и вибрация. Для слепоглухих — вибрация как основной канал. Родители управляют настройками через VoiceOver."
        ),
        (
            "Обратная связь",
            "Заполненные и пустые точки отличаются звуком и вибрацией. Интенсивность можно настроить в разделе настроек."
        ),
    ]

    var body: some View {
        VStack(spacing: 24) {
            TabView(selection: $page) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                    VStack(spacing: 16) {
                        Text(item.title)
                            .font(.title2.bold())
                            .multilineTextAlignment(.center)
                            .accessibilityAddTraits(.isHeader)

                        Text(item.body)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                    }
                    .tag(index)
                    .padding()
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(item.title). \(item.body)")
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            if page == pages.count - 1 {
                NavigationLink {
                    ProfileSelectionView(isOnboarding: true)
                } label: {
                    Text("Выбрать профиль")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
                .accessibilityLabel("Выбрать профиль пользователя")
            } else {
                Button("Далее") { page += 1 }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal)
                    .accessibilityLabel("Следующая страница онбординга")
            }
        }
        .navigationTitle("Добро пожаловать")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        OnboardingView()
            .environmentObject(AppState())
    }
}
