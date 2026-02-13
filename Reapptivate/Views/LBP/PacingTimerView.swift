import SwiftUI
import AVFoundation
import AudioToolbox
import Combine

struct PacingTimerView: View {
    @Bindable var viewModel: LbpEnhancementsViewModel
    @Environment(\.scenePhase) private var scenePhase

    enum TimerState {
        case idle, active, paused, onBreak, completed
    }

    @State private var timerState: TimerState = .idle
    @State private var selectedActivityKey: String?
    @State private var elapsedSeconds: Int = 0
    @State private var breakSeconds: Int = 0
    @State private var soundPlayed80 = false
    @State private var soundPlayed100 = false
    @State private var audioPlayer: AVAudioPlayer?
    @State private var backgroundDate: Date?

    private let timerPublisher = Timer.publish(every: 1, on: .main, in: .common)

    var selectedActivity: TargetActivity? {
        viewModel.pacingPlan?.targetActivities.first { $0.key == selectedActivityKey }
    }

    var quotaSeconds: Int {
        (selectedActivity?.quota ?? 0) * 60
    }

    var progress: Double {
        guard quotaSeconds > 0 else { return 0 }
        return min(1.0, Double(elapsedSeconds) / Double(quotaSeconds))
    }

    var isDer: Bool {
        viewModel.subtype == .DER
    }

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: "clock.fill")
                    .font(.appTitle3)
                    .foregroundStyle(Color.subtypeColor(for: viewModel.subtype))
                Text("Aktivitats-Timer")
                    .font(.appHeadline)
                    .foregroundStyle(.textPrimary)
                Spacer()
            }

            switch timerState {
            case .idle:
                idleView
            case .active, .paused:
                activeView
            case .onBreak:
                breakView
            case .completed:
                completedView
            }
        }
        .onDisappear {
            resetTimer()
        }
        .onReceive(timerPublisher.autoconnect()) { _ in
            guard timerState == .active || timerState == .onBreak else { return }
            if timerState == .active {
                tick()
            } else if timerState == .onBreak {
                breakSeconds += 1
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background:
                if timerState == .active || timerState == .onBreak {
                    backgroundDate = Date()
                }
            case .active:
                if let bgDate = backgroundDate {
                    let elapsed = Int(Date().timeIntervalSince(bgDate))
                    backgroundDate = nil
                    if timerState == .active {
                        elapsedSeconds += elapsed
                        // Check if quota was reached while backgrounded
                        if quotaSeconds > 0 && elapsedSeconds >= quotaSeconds {
                            if !soundPlayed100 {
                                soundPlayed100 = true
                                playAlarmSound()
                                UINotificationFeedbackGenerator().notificationOccurred(.warning)
                            }
                            if isDer { startBreak() }
                        }
                    } else if timerState == .onBreak {
                        breakSeconds += elapsed
                    }
                }
            default:
                break
            }
        }
    }

    // MARK: - Idle View

    private var idleView: some View {
        VStack(spacing: 16) {
            if let activities = viewModel.pacingPlan?.targetActivities {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Aktivitat auswahlen")
                        .font(.appSubheadlineMedium)
                        .foregroundStyle(.textPrimary)

                    ForEach(activities) { activity in
                        Button {
                            selectedActivityKey = activity.key
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: selectedActivityKey == activity.key ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selectedActivityKey == activity.key ? .accent : .textSecondary)
                                Text(activity.label)
                                    .font(.appSubheadline)
                                    .foregroundStyle(.textPrimary)
                                Spacer()
                                if let quota = activity.quota {
                                    Text("Ziel: \(quota) Min")
                                        .font(.appCaption)
                                        .foregroundStyle(.textSecondary)
                                }
                            }
                            .padding(10)
                            .background(selectedActivityKey == activity.key ? Color.accent.opacity(0.06) : .clear)
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.smallRadius, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }

                if selectedActivityKey != nil {
                    Button {
                        startTimer()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "play.fill")
                            Text("Timer starten")
                        }
                        .font(.appBodySemibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.subtypeColor(for: viewModel.subtype))
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.buttonRadius, style: .continuous))
                    }
                }
            }
        }
        .cardStyle()
    }

    // MARK: - Active View

    private var activeView: some View {
        VStack(spacing: 20) {
            // Timer display
            Text(timeString(elapsedSeconds))
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundStyle(.textPrimary)

            // Progress bar
            VStack(spacing: 4) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.textSecondary.opacity(0.15))
                            .frame(height: 12)

                        Rectangle()
                            .fill(progressColor)
                            .frame(width: geo.size.width * progress, height: 12)
                    }
                }
                .frame(height: 12)

                HStack {
                    Text(selectedActivity?.label ?? "")
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                    Spacer()
                    if let quota = selectedActivity?.quota {
                        Text("Ziel: \(quota) Min")
                            .font(.appCaption)
                            .foregroundStyle(.textSecondary)
                    }
                }
            }

            // Warning at 80%
            if progress >= 0.8 && progress < 1.0 {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.painAmber)
                    Text("Fast fertig! Bereiten Sie sich auf eine Pause vor.")
                        .font(.appCaption)
                        .foregroundStyle(.textPrimary)
                }
                .infoBoxStyle(color: .painAmber)
            }

            // Controls
            HStack(spacing: 16) {
                Button {
                    if timerState == .paused {
                        resumeTimer()
                    } else {
                        pauseTimer()
                    }
                } label: {
                    Image(systemName: timerState == .paused ? "play.fill" : "pause.fill")
                        .font(.appTitle2)
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.textSecondary)
                        .clipShape(Circle())
                }

                Button {
                    completeTimer()
                } label: {
                    Text("Fertig")
                        .font(.appBodySemibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.painGreen)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.buttonRadius, style: .continuous))
                }
            }

            // Pacing tips
            VStack(alignment: .leading, spacing: 4) {
                Text("Pacing-Tipps")
                    .font(.appCaptionMedium)
                    .foregroundStyle(.textSecondary)
                Text("Halten Sie sich an Ihre Quota. Es ist besser, etwas unter dem Ziel zu bleiben als daruber.")
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .infoBoxStyle(color: .farBlue)
        }
        .cardStyle()
    }

    // MARK: - Break View

    private var breakView: some View {
        VStack(spacing: 20) {
            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: 36))
                .foregroundStyle(.painAmber)

            Text("Pausenzeit!")
                .font(.appTitle2)
                .foregroundStyle(.textPrimary)

            Text(timeString(breakSeconds))
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundStyle(.painAmber)

            if let pauseMin = viewModel.pacingPlan?.rules.mandatoryPauseMinutes {
                Text("Mindestens \(pauseMin) Minuten Pause einhalten")
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
            }

            Button {
                endBreak()
            } label: {
                Text("Pause beenden")
                    .font(.appBodySemibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.painAmber)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.buttonRadius, style: .continuous))
            }
        }
        .padding(24)
        .background(
            LinearGradient(
                colors: [Color.painAmber.opacity(0.1), Color.painAmber.opacity(0.03)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cardRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: DesignTokens.cardRadius, style: .continuous).stroke(Color.gray200, lineWidth: 1))
    }

    // MARK: - Completed View

    private var completedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.painGreen)

            Text("Abgeschlossen!")
                .font(.appTitle2)
                .foregroundStyle(.textPrimary)

            Text("Gesamtzeit: \(timeString(elapsedSeconds))")
                .font(.appHeadline.monospacedDigit())
                .foregroundStyle(.textSecondary)

            Button {
                resetTimer()
            } label: {
                Text("Neuen Timer starten")
                    .font(.appSubheadlineMedium)
                    .foregroundStyle(.accent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(Color.accent.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.buttonRadius, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: DesignTokens.buttonRadius, style: .continuous).stroke(Color.gray200, lineWidth: 1))
            }
        }
        .padding(24)
        .background(Color.painGreen.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cardRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: DesignTokens.cardRadius, style: .continuous).stroke(Color.gray200, lineWidth: 1))
    }

    // MARK: - Timer Logic

    private var progressColor: Color {
        if progress >= 1.0 { return .painRed }
        if progress >= 0.8 { return .painAmber }
        return .farBlue
    }

    private func startTimer() {
        timerState = .active
        elapsedSeconds = 0
        soundPlayed80 = false
        soundPlayed100 = false
        setupAudioSession()
    }

    private func tick() {
        elapsedSeconds += 1

        // Check 80% cue
        if !soundPlayed80 && quotaSeconds > 0 && Double(elapsedSeconds) / Double(quotaSeconds) >= 0.8 {
            soundPlayed80 = true
            playKnockSound()
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }

        // Check 100% cue
        if !soundPlayed100 && quotaSeconds > 0 && elapsedSeconds >= quotaSeconds {
            soundPlayed100 = true
            playAlarmSound()
            UINotificationFeedbackGenerator().notificationOccurred(.warning)

            // DER: mandatory break
            if isDer {
                startBreak()
            }
        }
    }

    private func pauseTimer() {
        timerState = .paused
    }

    private func resumeTimer() {
        timerState = .active
    }

    private func completeTimer() {
        timerState = .completed
    }

    private func startBreak() {
        timerState = .onBreak
        breakSeconds = 0
    }

    private func endBreak() {
        timerState = .completed
    }

    private func resetTimer() {
        timerState = .idle
        elapsedSeconds = 0
        breakSeconds = 0
        soundPlayed80 = false
        soundPlayed100 = false
        deactivateAudioSession()
    }

    // MARK: - Audio

    private func setupAudioSession() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    private func deactivateAudioSession() {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func playKnockSound() {
        AudioServicesPlaySystemSound(1057) // Tock sound
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            AudioServicesPlaySystemSound(1057)
        }
    }

    private func playAlarmSound() {
        AudioServicesPlaySystemSound(1005) // Alert sound
    }

    // MARK: - Helpers

    private func timeString(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
