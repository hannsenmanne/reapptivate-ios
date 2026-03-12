import SwiftUI

struct CustomExerciseLogSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(APIClient.self) private var apiClient
    @Environment(\.dismiss) private var dismiss

    let exercise: CustomExercise
    let onSuccess: () -> Void

    @State private var painLevel = 0
    @State private var setsCompleted: Int
    @State private var repsCompleted: Int
    @State private var notes = ""
    @AppStorage("appLanguage") private var appLanguage = "de"
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showSuccess = false

    init(exercise: CustomExercise, onSuccess: @escaping () -> Void) {
        self.exercise = exercise
        self.onSuccess = onSuccess
        _setsCompleted = State(initialValue: exercise.sets)
        _repsCompleted = State(initialValue: exercise.reps)
    }

    var body: some View {
        let isEn = appLanguage == "en"

        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Exercise name
                    VStack(spacing: 4) {
                        Text(exercise.name)
                            .font(.appHeadline)
                            .foregroundStyle(.textPrimary)
                        Text(isEn ? "Therapist exercise" : "Therapeuten-Übung")
                            .font(.appCaption)
                            .foregroundStyle(.blue)
                    }

                    // Pain Slider
                    PainSliderView(painLevel: $painLevel, maxPainLevel: appState.currentUser?.aemSubtype?.maxPainLevel ?? 3)

                    // Sets & Reps
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(isEn ? "Sets" : "Sätze")
                                .font(.appCaption)
                                .foregroundStyle(.textSecondary)
                            Stepper(value: $setsCompleted, in: 0...20) {
                                Text("\(setsCompleted)")
                                    .font(.appTitle3)
                            }
                        }
                        .frame(maxWidth: .infinity)

                        VStack(alignment: .leading, spacing: 6) {
                            Text(isEn ? "Repetitions" : "Wiederholungen")
                                .font(.appCaption)
                                .foregroundStyle(.textSecondary)
                            Stepper(value: $repsCompleted, in: 0...50) {
                                Text("\(repsCompleted)")
                                    .font(.appTitle3)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }

                    // Notes
                    VStack(alignment: .leading, spacing: 6) {
                        Text(isEn ? "Notes (optional)" : "Notizen (optional)")
                            .font(.appCaption)
                            .foregroundStyle(.textSecondary)
                        TextField(isEn ? "How did you feel?" : "Wie haben Sie sich gefühlt?", text: $notes, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(3...5)
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
                                Text(isEn ? "Save workout" : "Training speichern")
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
            .navigationTitle(isEn ? "Progress" : "Fortschritt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(isEn ? "Cancel" : "Abbrechen") { dismiss() }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(isEn ? "Done" : "Fertig") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                    .font(.appSubheadlineMedium)
                    .foregroundStyle(.accent)
                }
            }
        }
        .overlay {
            if showSuccess {
                SuccessBanner(message: isEn ? "Workout saved successfully!" : "Training erfolgreich gespeichert!")
            }
        }
    }

    private func submit() async {
        isSubmitting = true
        errorMessage = nil

        let request = ProgressLogRequest(
            exerciseId: "custom_\(exercise.id)",
            painLevel: painLevel,
            setsCompleted: setsCompleted,
            repsCompleted: repsCompleted,
            notes: notes.isEmpty ? nil : notes,
            symptomResponse: nil
        )

        do {
            let _: ProgressLogResponse = try await apiClient.request(
                APIEndpoints.logProgress(body: request)
            )

            showSuccess = true
            onSuccess()
            try? await Task.sleep(for: .seconds(1.5))
            dismiss()
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = appLanguage == "en" ? "Failed to save." : "Speichern fehlgeschlagen."
        }

        isSubmitting = false
    }
}
