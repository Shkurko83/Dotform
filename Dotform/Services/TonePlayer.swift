import AVFoundation
import AudioToolbox

/// Генератор чётко различимых тонов. При сбое — системные звуки.
@MainActor
final class TonePlayer {
    static let shared = TonePlayer()

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
    private var isConfigured = false

    private init() {
        configureIfNeeded()
    }

    func play(frequency: Double, duration: TimeInterval, volume: Float) {
        configureIfNeeded()

        if isConfigured {
            let frameCount = AVAudioFrameCount(format.sampleRate * duration)
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
                playFallback(for: frequency)
                return
            }

            buffer.frameLength = frameCount
            let samples = buffer.floatChannelData![0]
            let angularFrequency = 2.0 * Double.pi * frequency / format.sampleRate

            for frame in 0..<Int(frameCount) {
                let progress = Double(frame) / Double(frameCount)
                let envelope = min(1.0, min(progress * 15.0, (1.0 - progress) * 15.0))
                samples[frame] = Float(sin(angularFrequency * Double(frame)) * envelope) * volume
            }

            player.stop()
            player.scheduleBuffer(buffer, at: nil, options: .interrupts)
            if !engine.isRunning { try? engine.start() }
            player.play()
        } else {
            playFallback(for: frequency)
        }
    }

    private func playFallback(for frequency: Double) {
        let sound: SystemSoundID
        if frequency >= 700 {
            sound = 1057
        } else if frequency >= 500 {
            sound = 1104
        } else if frequency >= 350 {
            sound = 1103
        } else {
            sound = 1053
        }
        AudioServicesPlaySystemSound(sound)
    }

    private func configureIfNeeded() {
        guard !isConfigured else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: format)
            try engine.start()
            isConfigured = true
        } catch {
            isConfigured = false
        }
    }
}

enum FeedbackTone {
    case filledDot
    case emptyDot
    case success
    case error
    case lessonStart
    case regionLeft
    case regionRight
    case regionTop
    case regionMiddle
    case regionBottom
    case shortPulse
    case longPulse

    var frequency: Double {
        switch self {
        case .filledDot: return 1_046
        case .emptyDot: return 196
        case .success: return 1_175
        case .error: return 165
        case .lessonStart: return 784
        case .regionLeft: return 392
        case .regionRight: return 880
        case .regionTop: return 659
        case .regionMiddle: return 523
        case .regionBottom: return 262
        case .shortPulse: return 740
        case .longPulse: return 330
        }
    }

    var duration: TimeInterval {
        switch self {
        case .filledDot: return 0.22
        case .emptyDot: return 0.03
        case .success: return 0.28
        case .error: return 0.2
        case .lessonStart: return 0.14
        case .regionLeft: return 0.12
        case .regionRight: return 0.18
        case .regionTop: return 0.1
        case .regionMiddle: return 0.09
        case .regionBottom: return 0.35
        case .shortPulse: return 0.06
        case .longPulse: return 0.45
        }
    }

    var volumeMultiplier: Float {
        switch self {
        case .filledDot, .success, .regionRight, .longPulse: return 1.0
        case .emptyDot: return 0.25
        case .regionTop, .regionMiddle, .shortPulse: return 0.7
        default: return 0.85
        }
    }
}
