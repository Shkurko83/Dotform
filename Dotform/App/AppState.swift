import Combine
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    let store: ProgressStore
    @Published var path = NavigationPath()

    let feedback = CompositeFeedbackEngine()
    let speech = SpeechService()

    var blindFeedback: BlindFeedback {
        BlindFeedback(speech: speech)
    }

    private var cancellables = Set<AnyCancellable>()

    init() {
        let store = ProgressStore()
        self.store = store
        store.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    var profile: UserProfile? {
        store.progress.selectedProfile
    }

    var settings: AppSettings {
        get { store.settings }
        set { store.updateSettings(newValue) }
    }

    var hasCompletedOnboarding: Bool {
        store.progress.onboardingCompleted
    }

    func completeOnboarding(profile: UserProfile) {
        store.completeOnboarding(profile: profile)
        objectWillChange.send()
    }

    func selectProfile(_ profile: UserProfile) {
        store.selectProfile(profile)
        objectWillChange.send()
    }

    func effectiveProfileForLessons() -> UserProfile {
        settings.childProfile
    }

    var feedbackContext: FeedbackContext {
        FeedbackContext(settings: settings, profile: settings.childProfile)
    }
}
