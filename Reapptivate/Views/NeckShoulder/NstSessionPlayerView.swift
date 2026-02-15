import SwiftUI

struct NstSessionPlayerView: View {
    @Environment(APIClient.self) private var apiClient
    @Environment(\.dismiss) private var dismiss

    let sessionType: String
    let exercises: [NeckShoulderExercise]
    let accentColor: Color
    let onComplete: () -> Void

    @State private var currentIndex = 0
    @State private var currentSet = 1
    @State private var isResting = false
    @State private var restSeconds = 0
    @State private var timer: Timer?
    @State private var painBefore = 0
    @State private var painAfter = 0
    @State private var completedExercises: Set<String> = []
    @State private var phase: PlayerPhase = .painBefore
    @State private var showLogSheet = false
    @State private var restTrigger = false

    enum PlayerPhase {
        case painBefore
        case exercising
        case painAfter
    }

    var currentExercise: NeckShoulderExercise? {
        guard currentIndex < exercises.count else { return nil }
        return exercises[currentIndex]
    }

    var sessionLabel: String {
        switch sessionType {
        case "strength_a": "Kraft A"
        case "strength_b": "Kraft B"
        case "mobility": "Mobilität"
        default: sessionType
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle().fill(Color.gray200)
                        Rectangle()
                            .fill(accentColor)
                            .frame(width: geo.size.width * progress)
                            .animation(.easeInOut(duration: 0.3), value: progress)
                    }
                }
                .frame(height: 4)

                ScrollView {
                    VStack(spacing: 24) {
                        switch phase {
                        case .painBefore:
                            painBeforeSection
                        case .exercising:
                            exerciseSection
                        case .painAfter:
                            painAfterSection
                        }
                    }
                    .padding(20)
                }
            }
            .background(Color.appBg)
            .navigationTitle(sessionLabel)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
            }
        }
        .sensoryFeedback(.impact, trigger: restTrigger)
    }

    private var progress: Double {
        guard !exercises.isEmpty else { return 0 }
        switch phase {
        case .painBefore: return 0.05
        case .exercising:
            return 0.1 + (Double(currentIndex) / Double(exercises.count)) * 0.8
        case .painAfter: return 0.95
        }
    }

    // MARK: - Pain Before

    private var painBeforeSection: some View {
        VStack(spacing: 24) {
            Image(systemName: "heart.text.clipboard")
                .font(.system(size: 40))
                .foregroundStyle(accentColor)

            Text("Wie ist Ihr Schmerzniveau?")
                .font(.appTitle3)
                .foregroundStyle(.textPrimary)

            Text("Bitte bewerten Sie Ihren aktuellen Schmerz vor dem Training.")
                .font(.appSubheadline)
                .foregroundStyle(.textSecondary)
                .multilineTextAlignment(.center)

            SimplePainDisplay(value: $painBefore, accentColor: accentColor)
                .cardStyle()

            Button {
                withAnimation { phase = .exercising }
            } label: {
                Text("Training starten")
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
            }
            .buttonStyle(.accentFilled)
        }
    }

    // MARK: - Exercise Section

    @ViewBuilder
    private var exerciseSection: some View {
        if let exercise = currentExercise {
            VStack(spacing: 20) {
                // Exercise counter
                Text("Übung \(currentIndex + 1) von \(exercises.count)")
                    .font(.appCaptionMedium)
                    .foregroundStyle(.textSecondary)

                // Exercise name
                VStack(spacing: 4) {
                    Text(exercise.name)
                        .font(.appTitle3)
                        .foregroundStyle(.textPrimary)
                    if let muscle = exercise.targetMuscle {
                        Text(muscle)
                            .font(.appCaption)
                            .foregroundStyle(accentColor)
                    }
                }

                // Set counter
                VStack(spacing: 8) {
                    Text("Satz \(currentSet) von \(exercise.sets ?? 1)")
                        .font(.appHeadline)
                        .foregroundStyle(.textPrimary)

                    Text(exercise.reps ?? "")
                        .font(.appSubheadline)
                        .foregroundStyle(.textSecondary)

                    if let hold = exercise.holdSeconds {
                        Text("\(hold)s halten")
                            .font(.appCaptionMedium)
                            .foregroundStyle(accentColor)
                    }
                }
                .cardStyle()

                // Rest timer
                if isResting {
                    VStack(spacing: 8) {
                        Text("Pause")
                            .font(.appCaption)
                            .foregroundStyle(.textSecondary)
                        Text("\(restSeconds)s")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(accentColor)
                            .contentTransition(.numericText())
                        Button("Überspringen") {
                            stopRest()
                            advanceSet()
                        }
                        .font(.appCaptionMedium)
                        .foregroundStyle(.textSecondary)
                    }
                    .padding(.vertical, 8)
                } else {
                    // Complete set button
                    Button {
                        completeSet(exercise: exercise)
                    } label: {
                        Label("Satz abschliessen", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                    }
                    .buttonStyle(.accentFilled)
                }

                // Skip exercise
                Button {
                    nextExercise()
                } label: {
                    Text("Übung überspringen")
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                }
            }
        }
    }

    // MARK: - Pain After

    private var painAfterSection: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 40))
                .foregroundStyle(.painGreen)

            Text("Training abgeschlossen!")
                .font(.appTitle3)
                .foregroundStyle(.textPrimary)

            Text("Wie ist Ihr Schmerzniveau nach dem Training?")
                .font(.appSubheadline)
                .foregroundStyle(.textSecondary)
                .multilineTextAlignment(.center)

            SimplePainDisplay(value: $painAfter, accentColor: accentColor)
                .cardStyle()

            Button {
                showLogSheet = true
            } label: {
                Text("Sitzung speichern")
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
            }
            .buttonStyle(.accentFilled)
        }
        .sheet(isPresented: $showLogSheet) {
            NstSessionLogView(
                sessionType: sessionType,
                exercises: exercises,
                accentColor: accentColor,
                onSuccess: {
                    onComplete()
                    dismiss()
                }
            )
        }
    }

    // MARK: - Actions

    private func completeSet(exercise: NeckShoulderExercise) {
        if currentSet >= (exercise.sets ?? 1) {
            completedExercises.insert(exercise.id)
            nextExercise()
        } else {
            // Start rest timer
            isResting = true
            restSeconds = 60
            restTrigger.toggle()
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                Task { @MainActor in
                    if restSeconds > 0 {
                        restSeconds -= 1
                    } else {
                        stopRest()
                        advanceSet()
                    }
                }
            }
        }
    }

    private func advanceSet() {
        currentSet += 1
    }

    private func nextExercise() {
        stopRest()
        if currentIndex + 1 < exercises.count {
            currentIndex += 1
            currentSet = 1
        } else {
            withAnimation { phase = .painAfter }
        }
    }

    private func stopRest() {
        timer?.invalidate()
        timer = nil
        isResting = false
    }
}

// MARK: - Simple Pain Display (reusable)

private struct SimplePainDisplay: View {
    @Binding var value: Int
    let accentColor: Color

    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(value)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(painColor)
                    .contentTransition(.numericText())
                    .animation(.spring(duration: 0.2), value: value)
                Text("/10")
                    .font(.appSubheadline)
                    .foregroundStyle(.textSecondary)
            }

            Slider(value: Binding(
                get: { Double(value) },
                set: { value = Int(round($0)) }
            ), in: 0...10, step: 1)
            .tint(painColor)

            HStack {
                Text("Kein Schmerz")
                    .font(.appCaption2)
                    .foregroundStyle(.textSecondary)
                Spacer()
                Text("Stärkster Schmerz")
                    .font(.appCaption2)
                    .foregroundStyle(.textSecondary)
            }
        }
    }

    private var painColor: Color {
        if value <= 3 { return .painGreen }
        if value <= 5 { return .painAmber }
        return .painRed
    }
}
