import SwiftUI

struct NstSessionLogView: View {
    @Environment(APIClient.self) private var apiClient
    @Environment(\.dismiss) private var dismiss

    let sessionType: String
    let exercises: [NeckShoulderExercise]
    let accentColor: Color
    let onSuccess: () -> Void

    @State private var viewModel: NstTrackingViewModel?
    @State private var painBefore = 0
    @State private var painAfter = 0
    @State private var completedExercises: Set<String> = []
    @State private var notes = ""
    @State private var isSubmitting = false
    @State private var showSuccess = false
    @State private var showTriggerAlert = false
    @State private var triggerEvaluation: NstTriggerEvaluation?
    @State private var submitSuccessTrigger = false
    @State private var errorMessage: String?

    var sessionLabel: String {
        switch sessionType {
        case "strength_a": "Kraft A"
        case "strength_b": "Kraft B"
        case "mobility": "Mobilität"
        default: sessionType
        }
    }

    private var hasUnsavedChanges: Bool {
        painBefore != 0 || painAfter != 0 || !notes.isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Session type header
                    HStack(spacing: 10) {
                        Image(systemName: sessionTypeIcon)
                            .font(.appTitle3)
                            .foregroundStyle(accentColor)
                        Text(sessionLabel)
                            .font(.appHeadline)
                            .foregroundStyle(.textPrimary)
                    }

                    // Pain before
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Schmerz vorher")
                            .font(.appSubheadlineMedium)
                            .foregroundStyle(.textPrimary)
                        SimplePainSlider(value: $painBefore, accentColor: accentColor)
                    }
                    .cardStyle()

                    // Exercise checklist
                    if !exercises.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Übungen")
                                    .font(.appSubheadlineMedium)
                                    .foregroundStyle(.textPrimary)
                                Spacer()
                                Text("\(completedExercises.count)/\(exercises.count)")
                                    .font(.appCaptionMedium)
                                    .foregroundStyle(accentColor)
                            }

                            ForEach(exercises) { exercise in
                                ExerciseCheckRow(
                                    exercise: exercise,
                                    isCompleted: completedExercises.contains(exercise.id),
                                    accentColor: accentColor
                                ) {
                                    if completedExercises.contains(exercise.id) {
                                        completedExercises.remove(exercise.id)
                                    } else {
                                        completedExercises.insert(exercise.id)
                                    }
                                }
                            }

                            // Select all / deselect all
                            Button {
                                if completedExercises.count == exercises.count {
                                    completedExercises.removeAll()
                                } else {
                                    completedExercises = Set(exercises.map(\.id))
                                }
                            } label: {
                                Text(completedExercises.count == exercises.count ? "Alle abwählen" : "Alle auswählen")
                                    .font(.appCaption)
                                    .foregroundStyle(accentColor)
                            }
                        }
                        .cardStyle()
                    }

                    // Pain after
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Schmerz nachher")
                            .font(.appSubheadlineMedium)
                            .foregroundStyle(.textPrimary)
                        SimplePainSlider(value: $painAfter, accentColor: accentColor)
                    }
                    .cardStyle()

                    // Notes
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Notizen (optional)")
                            .font(.appCaption)
                            .foregroundStyle(.textSecondary)
                        TextField("Wie haben Sie sich gefühlt?", text: $notes, axis: .vertical)
                            .font(.appBody)
                            .lineLimit(3...5)
                            .inputFieldStyle()
                    }

                    // Error
                    if let error = errorMessage {
                        Text(error)
                            .font(.appCaption)
                            .foregroundStyle(.painRed)
                    }

                    // Submit
                    Button {
                        Task { await submit() }
                    } label: {
                        Group {
                            if isSubmitting {
                                ProgressView().tint(.white)
                            } else {
                                Label("Training speichern", systemImage: "checkmark.circle.fill")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                    }
                    .buttonStyle(.accentFilled)
                    .disabled(isSubmitting)
                }
                .padding(20)
            }
            .background(Color.appBg)
            .navigationTitle("Sitzung erfassen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
            }
        }
        .task {
            viewModel = NstTrackingViewModel(apiClient: apiClient)
            // Pre-select all exercises
            completedExercises = Set(exercises.map(\.id))
        }
        .overlay {
            if showSuccess {
                SuccessBanner(message: "Sitzung erfolgreich gespeichert!")
            }
        }
        .alert("Hinweis", isPresented: $showTriggerAlert) {
            Button("Verstanden") {
                showTriggerAlert = false
                onSuccess()
                dismiss()
            }
        } message: {
            if let evaluation = triggerEvaluation,
               let rules = evaluation.matchedRules, !rules.isEmpty {
                Text(rules.map(\.reason).joined(separator: "\n"))
            } else {
                Text("Ihr Programm wurde angepasst.")
            }
        }
        .conditionalHaptic(.success, trigger: submitSuccessTrigger)
        .interactiveDismissDisabled(hasUnsavedChanges)
    }

    private var sessionTypeIcon: String {
        switch sessionType {
        case "strength_a", "strength_b": "figure.strengthtraining.traditional"
        case "mobility": "figure.flexibility"
        default: "figure.mixed.cardio"
        }
    }

    private func submit() async {
        guard let viewModel else { return }
        isSubmitting = true
        errorMessage = nil

        let success = await viewModel.logSession(
            sessionType: sessionType,
            painBefore: painBefore,
            painAfter: painAfter,
            exercisesCompleted: Array(completedExercises),
            durationSeconds: nil,
            notes: notes.isEmpty ? nil : notes
        )

        if success {
            submitSuccessTrigger.toggle()

            if let evaluation = viewModel.lastTriggerEvaluation,
               let rules = evaluation.matchedRules, !rules.isEmpty {
                triggerEvaluation = evaluation
                showTriggerAlert = true
            } else {
                showSuccess = true
                onSuccess()
                try? await Task.sleep(for: .seconds(1.5))
                dismiss()
            }
        } else {
            errorMessage = viewModel.errorMessage
        }

        isSubmitting = false
    }
}

// MARK: - Simple Pain Slider

private struct SimplePainSlider: View {
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

// MARK: - Exercise Check Row

private struct ExerciseCheckRow: View {
    let exercise: NeckShoulderExercise
    let isCompleted: Bool
    let accentColor: Color
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.appTitle3)
                    .foregroundStyle(isCompleted ? accentColor : Color.gray300)

                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.name)
                        .font(.appSubheadline)
                        .foregroundStyle(isCompleted ? .textPrimary : .textSecondary)
                        .lineLimit(1)
                    Text(exercise.detail)
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                }

                Spacer()
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}
