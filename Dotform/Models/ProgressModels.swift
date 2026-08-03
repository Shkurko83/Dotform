import Foundation

struct LetterProgress: Codable, Identifiable, Equatable {
    let character: String
    var successCount: Int = 0
    var errorCount: Int = 0
    var lastAttemptDate: Date?
    var lastSuccessDate: Date?
    var totalTimeSpent: TimeInterval = 0
    var isLearned: Bool = false

    var id: String { character }

    var accuracy: Double {
        let total = successCount + errorCount
        guard total > 0 else { return 0 }
        return Double(successCount) / Double(total)
    }

    var difficultyScore: Double {
        Double(errorCount) - Double(successCount) * 0.5
    }
}

struct SessionRecord: Codable, Identifiable {
    let id: UUID
    let date: Date
    let letterCharacter: String
    let phase: String
    let succeeded: Bool
    let duration: TimeInterval
}

struct ProgressData: Codable {
    var letterProgress: [String: LetterProgress] = [:]
    var sessions: [SessionRecord] = []
    var unlockedLevels: Set<Int> = [0, 1, 2, 3, 4, 5]
    var onboardingCompleted: Bool = false
    var selectedProfile: UserProfile?

    mutating func recordAttempt(
        letter: BrailleLetter,
        succeeded: Bool,
        phase: LessonPhase,
        duration: TimeInterval
    ) {
        let key = letter.id
        var progress = letterProgress[key] ?? LetterProgress(character: key)
        if succeeded {
            progress.successCount += 1
            progress.lastSuccessDate = Date()
            if progress.successCount >= 3 && progress.accuracy >= 0.6 {
                progress.isLearned = true
            }
        } else {
            progress.errorCount += 1
        }
        progress.lastAttemptDate = Date()
        progress.totalTimeSpent += duration
        letterProgress[key] = progress

        let phaseName: String
        switch phase {
        case .entry: phaseName = "entry"
        case .modelHand: phaseName = "modelHand"
        case .exploration: phaseName = "exploration"
        case .reinforcement: phaseName = "reinforcement"
        case .test: phaseName = "test"
        case .result(let success): phaseName = success ? "resultSuccess" : "resultFailure"
        }

        sessions.append(SessionRecord(
            id: UUID(),
            date: Date(),
            letterCharacter: key,
            phase: phaseName,
            succeeded: succeeded,
            duration: duration
        ))

        if sessions.count > 500 {
            sessions.removeFirst(sessions.count - 500)
        }

        updateUnlockedLevels()
    }

    private mutating func updateUnlockedLevels() {
        unlockedLevels = [0, 1, 2, 3, 4, 5]
    }

    var hardestLetters: [LetterProgress] {
        letterProgress.values
            .filter { $0.errorCount > 0 }
            .sorted { $0.difficultyScore > $1.difficultyScore }
            .prefix(5)
            .map { $0 }
    }

    var learnedLetters: [LetterProgress] {
        letterProgress.values.filter(\.isLearned).sorted { $0.character < $1.character }
    }

    func recommendedLetters(from catalog: [BrailleLetter], settings: AppSettings) -> [BrailleLetter] {
        let enabled = catalog.filter { settings.isGlyphEnabled($0) }
        let recentErrors = letterProgress.values
            .filter { $0.lastAttemptDate != nil && $0.errorCount > $0.successCount }
            .sorted { ($0.lastAttemptDate ?? .distantPast) > ($1.lastAttemptDate ?? .distantPast) }

        var result: [BrailleLetter] = []
        for progress in recentErrors.prefix(3) {
            if let letter = enabled.first(where: { $0.id == progress.character || $0.display == progress.character }) {
                result.append(letter)
            }
        }

        let unlearned = enabled.filter { letter in
            !(letterProgress[letter.id]?.isLearned ?? letterProgress[letter.display]?.isLearned ?? false)
        }
        result.append(contentsOf: unlearned)

        if settings.repeatLearnedLetters {
            let learned = enabled.filter { letter in
                letterProgress[letter.id]?.isLearned ?? letterProgress[letter.display]?.isLearned ?? false
            }
            result.append(contentsOf: learned.shuffled().prefix(2))
        }

        var seen = Set<String>()
        return result.filter { seen.insert($0.id).inserted }
    }
}
