import SwiftUI

struct ExerciseSessionView: View {
    @Environment(\.dismiss) private var dismiss
    let exercise: ExerciseWithPhase
    let maxPainLevel: Int
    let showSymptomResponse: Bool
    let onComplete: () -> Void

    @State private var currentSet = 1
    @State private var isResting = false
    @State private var isHolding = false
    @State private var timerSeconds = 0
    @State private var timer: Timer?
    @State private var showProgressLog = false

    var totalSets: Int { exercise.exercise.sets }
    var holdTime: Int { exercise.exercise.holdTime ?? 0 }
    var restTime: Int { exercise.exercise.restBetweenSets }

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // Progress
                HStack(spacing: 4) {
                    ForEach(1...totalSets, id: \.self) { set in
                        Rectangle()
                            .fill(set < currentSet ? Color.painGreen : (set == currentSet ? Color.accent : Color.textSecondary.opacity(0.2)))
                            .frame(height: 4)
                    }
                }

                Spacer()

                // Timer Display
                VStack(spacing: 16) {
                    Text(isResting ? "Pause" : "Satz \(currentSet)/\(totalSets)")
                        .font(.appTitle3)
                        .foregroundStyle(.textSecondary)

                    if isHolding || isResting {
                        let target = isResting ? restTime : holdTime
                        let remaining = max(0, target - timerSeconds)

                        Text(timeString(remaining))
                            .font(.system(size: 72, weight: .bold, design: .rounded))
                            .foregroundStyle(isResting ? .textSecondary : .accent)
                            .contentTransition(.numericText())

                        // Progress ring
                        ZStack {
                            Circle()
                                .stroke(Color.textSecondary.opacity(0.2), lineWidth: 6)
                            Circle()
                                .trim(from: 0, to: target > 0 ? CGFloat(timerSeconds) / CGFloat(target) : 0)
                                .stroke(isResting ? Color.textSecondary : Color.accent, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .animation(.linear(duration: 1), value: timerSeconds)
                        }
                        .frame(width: 160, height: 160)
                    } else {
                        // Manual mode (no hold time)
                        Text("\(exercise.exercise.reps)")
                            .font(.system(size: 72, weight: .bold, design: .rounded))
                            .foregroundStyle(.accent)

                        Text("Wiederholungen")
                            .font(.appSubheadline)
                            .foregroundStyle(.textSecondary)

                        if let tempo = exercise.exercise.tempo {
                            Text("Tempo: \(tempo)")
                                .font(.appCaptionMedium)
                                .foregroundStyle(.textSecondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.accent.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.badgeRadius, style: .continuous))
                        }
                    }
                }

                Spacer()

                // Controls
                VStack(spacing: 16) {
                    if holdTime > 0 && !isResting {
                        // Hold timer mode
                        if isHolding {
                            Button {
                                stopTimer()
                                completeSet()
                            } label: {
                                Label("Satz beenden", systemImage: "stop.fill")
                                    .font(.appBodySemibold)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.painAmber)
                        } else {
                            Button {
                                startHold()
                            } label: {
                                Label("Halten starten", systemImage: "play.fill")
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                            }
                            .buttonStyle(.accentFilled)
                        }
                    } else if isResting {
                        Button {
                            stopTimer()
                            isResting = false
                        } label: {
                            Label("Pause uberspringen", systemImage: "forward.fill")
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                        }
                        .buttonStyle(.secondary)
                    } else {
                        // Manual reps mode
                        Button {
                            completeSet()
                        } label: {
                            Label(currentSet == totalSets ? "Letzter Satz fertig" : "Satz fertig",
                                  systemImage: "checkmark.circle.fill")
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                        }
                        .buttonStyle(.accentFilled)
                    }
                }
            }
            .padding(24)
            .background(Color.appBg)
            .navigationTitle(exercise.exercise.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        stopTimer()
                        dismiss()
                    }
                }
            }
            .onDisappear {
                stopTimer()
            }
            .sheet(isPresented: $showProgressLog) {
                ProgressLogSheet(
                    exercise: exercise,
                    maxPainLevel: maxPainLevel,
                    showSymptomResponse: showSymptomResponse,
                    onSuccess: {
                        onComplete()
                        dismiss()
                    }
                )
            }
        }
    }

    // MARK: - Timer Logic

    private func startHold() {
        isHolding = true
        timerSeconds = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                timerSeconds += 1
                if timerSeconds >= holdTime {
                    stopTimer()
                    completeSet()
                }
            }
        }
    }

    private func startRest() {
        isResting = true
        timerSeconds = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                timerSeconds += 1
                if timerSeconds >= restTime {
                    stopTimer()
                    isResting = false
                }
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        isHolding = false
    }

    private func completeSet() {
        if currentSet >= totalSets {
            // All sets done — open progress log
            showProgressLog = true
        } else {
            currentSet += 1
            startRest()
        }
    }

    private func timeString(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
