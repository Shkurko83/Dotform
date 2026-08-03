import SwiftUI

struct ProgressDashboardView: View {
    @EnvironmentObject private var appState: AppState

    private var progress: ProgressData { appState.store.progress }

    var body: some View {
        List {
            Section("Обзор") {
                StatRow(
                    title: "Изучено букв",
                    value: "\(progress.learnedLetters.count)",
                    accessibilityText: "Изучено букв: \(progress.learnedLetters.count)"
                )
                StatRow(
                    title: "Всего попыток",
                    value: "\(progress.sessions.count)",
                    accessibilityText: "Всего попыток: \(progress.sessions.count)"
                )
                StatRow(
                    title: "Успешных попыток",
                    value: "\(progress.sessions.filter(\.succeeded).count)",
                    accessibilityText: "Успешных попыток: \(progress.sessions.filter(\.succeeded).count)"
                )
                StatRow(
                    title: "Ошибочных попыток",
                    value: "\(progress.sessions.filter { !$0.succeeded }.count)",
                    accessibilityText: "Ошибочных попыток: \(progress.sessions.filter { !$0.succeeded }.count)"
                )
            }

            if !progress.learnedLetters.isEmpty {
                Section("Изученные буквы") {
                    ForEach(progress.learnedLetters) { item in
                        LetterProgressRow(progress: item)
                    }
                }
            }

            if !progress.hardestLetters.isEmpty {
                Section("Наиболее сложные буквы") {
                    ForEach(progress.hardestLetters) { item in
                        LetterProgressRow(progress: item)
                    }
                }
            }

            Section("Журнал последних занятий") {
                if progress.sessions.isEmpty {
                    Text("Пока нет записей.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(progress.sessions.suffix(20).reversed()) { session in
                        SessionRow(session: session)
                    }
                }
            }
        }
        .navigationTitle("Прогресс")
    }
}

private struct StatRow: View {
    let title: String
    let value: String
    let accessibilityText: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }
}

private struct LetterProgressRow: View {
    let progress: LetterProgress

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Буква \(progress.character)")
                .font(.headline)
            Text("Успехов: \(progress.successCount), ошибок: \(progress.errorCount)")
                .font(.subheadline)
            Text("Точность: \(Int(progress.accuracy * 100))%")
                .font(.caption)
                .foregroundStyle(.secondary)
            if progress.totalTimeSpent > 0 {
                Text("Время: \(formattedTime(progress.totalTimeSpent))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "Буква \(progress.character). Успехов \(progress.successCount), ошибок \(progress.errorCount). Точность \(Int(progress.accuracy * 100)) процентов."
        )
    }

    private func formattedTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return "\(minutes) мин \(seconds) сек"
    }
}

private struct SessionRow: View {
    let session: SessionRecord

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Буква \(session.letterCharacter)")
                Text(session.phase)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(session.succeeded ? "Успех" : "Ошибка")
                .foregroundStyle(session.succeeded ? .green : .orange)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "Буква \(session.letterCharacter), этап \(session.phase), \(session.succeeded ? "успех" : "ошибка")"
        )
    }
}

#Preview {
    NavigationStack {
        ProgressDashboardView()
            .environmentObject(AppState())
    }
}
