import Foundation

struct FeedbackContext {
    let settings: AppSettings
    let profile: UserProfile

    var usesAudio: Bool {
        switch profile {
        case .deafBlindChild:
            return settings.parallelSoundForResidualHearing
        case .blindChild, .parentTeacher:
            return true
        }
    }

    var usesSpeech: Bool {
        switch profile {
        case .deafBlindChild:
            return false
        case .blindChild, .parentTeacher:
            return true
        }
    }

    var usesHaptic: Bool {
        settings.hapticEnabled
    }
}

extension UserProfile {
    var isDeafBlind: Bool { self == .deafBlindChild }
    var isBlindHearing: Bool { self == .blindChild }
}
