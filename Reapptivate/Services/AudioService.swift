import AudioToolbox
import AVFoundation
import UIKit

@Observable
@MainActor
final class AudioService {
    static let shared = AudioService()

    private var audioPlayer: AVAudioPlayer?
    private var isSessionActive = false
    private var soundTask: Task<Void, Never>?

    private init() {}

    // MARK: - Audio Session

    func activateSession() {
        guard !isSessionActive else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
            isSessionActive = true
        } catch {
            // Silent fail
        }
    }

    func deactivateSession() {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        isSessionActive = false
    }

    // MARK: - System Sounds

    func playTick() {
        AudioServicesPlaySystemSound(1104) // Tick
    }

    func playComplete() {
        AudioServicesPlaySystemSound(1025) // Completion
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    func playWarning() {
        AudioServicesPlaySystemSound(1057) // Tock
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    func playAlarm() {
        AudioServicesPlaySystemSound(1005) // Alert
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    // MARK: - Double Knock (80% cue)

    func playDoubleKnock() {
        soundTask?.cancel()
        soundTask = Task { @MainActor in
            AudioServicesPlaySystemSound(1057)
            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled else { return }
            AudioServicesPlaySystemSound(1057)
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    // MARK: - Triple Beep (100% cue)

    func playTripleBeep() {
        soundTask?.cancel()
        soundTask = Task { @MainActor in
            AudioServicesPlaySystemSound(1005)
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            AudioServicesPlaySystemSound(1005)
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            AudioServicesPlaySystemSound(1005)
        }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}
