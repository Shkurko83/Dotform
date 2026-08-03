import SwiftUI

struct LessonsListView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedLevel: LearningLevel = .firstLetters

    var body: some View {
        List {
            Section("Уровни") {
                ForEach(LearningLevel.allCases) { level in
                    LevelRow(level: level, isSelected: selectedLevel == level)
                        .contentShape(Rectangle())
                        .onTapGesture { selectedLevel = level }
                        .accessibilityAddTraits(selectedLevel == level ? .isSelected : [])
                }
            }

            if selectedLevel == .sensoryPrep {
                Section("Сенсорные упражнения") {
                    ForEach(LessonCatalog.sensoryExercises()) { exercise in
                        NavigationLink {
                            SensoryExerciseView(exercise: exercise)
                        } label: {
                            Text(exercise.title)
                        }
                        .accessibilityLabel(exercise.title)
                        .accessibilityHint(exercise.instruction)
                    }
                }
            } else if selectedLevel == .spatialBasics {
                Section("Пространственные упражнения") {
                    ForEach(LessonCatalog.spatialExercises()) { exercise in
                        NavigationLink {
                            SensoryExerciseView(exercise: exercise)
                        } label: {
                            Text(exercise.title)
                        }
                    }
                }
            } else {
                Section("Буквы") {
                    let letters = LessonCatalog.lessons(
                        for: selectedLevel,
                        settings: appState.settings,
                        progress: appState.store.progress
                    )
                    if letters.isEmpty {
                        Text("Нет доступных букв для этого уровня.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(letters) { letter in
                            NavigationLink {
                                LessonView(letter: letter)
                            } label: {
                                LetterRow(letter: letter, progress: appState.store.progress.letterProgress[letter.character])
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Уроки")
    }
}

private struct LevelRow: View {
    let level: LearningLevel
    let isSelected: Bool

    var body: some View {
        Text(level.title)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(level.accessibilityDescription)
            .accessibilityValue(isSelected ? "Выбран" : "Доступен")
    }
}

private struct LetterRow: View {
    let letter: BrailleLetter
    let progress: LetterProgress?

    var body: some View {
        HStack {
            Text(letter.character)
                .font(.title2)
                .frame(width: 36)
                .accessibilityHidden(true)

            VStack(alignment: .leading) {
                Text("Буква \(letter.character)")
                if let progress {
                    Text("Успехов: \(progress.successCount), ошибок: \(progress.errorCount)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if progress?.isLearned == true {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .accessibilityLabel("Изучена")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        var text = "Буква \(letter.character)"
        if let progress {
            text += ", успехов \(progress.successCount), ошибок \(progress.errorCount)"
            if progress.isLearned { text += ", изучена" }
        }
        return text
    }
}

#Preview {
    NavigationStack {
        LessonsListView()
            .environmentObject(AppState())
    }
}
