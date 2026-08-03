import Combine
import Foundation

@MainActor
final class ProgressStore: ObservableObject {
    @Published private(set) var progress = ProgressData()
    @Published var settings = AppSettings()

    private let progressKey = "dotform.progress"
    private let settingsKey = "dotform.settings"

    init() {
        load()
    }

    func load() {
        if let data = UserDefaults.standard.data(forKey: progressKey),
           let decoded = try? JSONDecoder().decode(ProgressData.self, from: data) {
            progress = decoded
            progress.unlockedLevels = [0, 1, 2, 3, 4, 5]
        }
        if let data = UserDefaults.standard.data(forKey: settingsKey) {
            if let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
                settings = decoded
            }
            // Миграция со старого ключа enabledLetterCharacters
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let legacy = json["enabledLetterCharacters"] as? [String] {
                settings.migrateEnabledLettersIfNeeded(legacyCharacters: Set(legacy))
            }
        }
    }

    func save() {
        if let data = try? JSONEncoder().encode(progress) {
            UserDefaults.standard.set(data, forKey: progressKey)
        }
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: settingsKey)
        }
    }

    func completeOnboarding(profile: UserProfile) {
        progress.onboardingCompleted = true
        progress.selectedProfile = profile
        if profile.isChildProfile {
            settings.childProfile = profile
        }
        save()
    }

    func selectProfile(_ profile: UserProfile) {
        progress.selectedProfile = profile
        if profile.isChildProfile {
            settings.childProfile = profile
        }
        save()
    }

    func updateSettings(_ newSettings: AppSettings) {
        let profileChanged = settings.childProfile != newSettings.childProfile
        settings = newSettings

        if profileChanged, progress.selectedProfile?.isChildProfile == true {
            progress.selectedProfile = newSettings.childProfile
        }

        save()
    }

    func recordLessonResult(letter: BrailleLetter, succeeded: Bool, phase: LessonPhase, duration: TimeInterval) {
        progress.recordAttempt(letter: letter, succeeded: succeeded, phase: phase, duration: duration)
        save()
    }
}
