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
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Exercise name
                    VStack(spacing: 4) {
                        Text(exercise.name)
                            .font(.appHeadline)
                            .foregroundStyle(.textPrimary)
                        Text("Therapeuten-Übung")
                            .font(.appCaption)
                            .foregroundStyle(.blue)
                    }

                    // Pain Slider
                    PainSliderView(painLevel: $painLevel, maxPainLevel: 3)

                    // Sets & Reps
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Sätze")
                                .font(.appCaption)
                                .foregroundStyle(.textSecondary)
                            Stepper(value: $setsCompleted, in: 0...20) {
                                Text("\(setsCompleted)")
                                    .font(.appTitle3)
                            }
                        }
                        .frame(maxWidth: .infinity)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Wiederholungen")
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
                        Text("Notizen (optional)")
                            .font(.appCaption)
                            .foregroundStyle(.textSecondary)
                        TextField("Wie haben Sie sich gefühlt?", text: $notes, axis: .vertical)
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
                                Text("Training speichern")
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
            .navigationTitle("Fortschritt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
            }
        }
        .overlay {
            if showSuccess {
                SuccessBanner(message: "Training erfolgreich gespeichert!")
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
            errorMessage = "Speichern fehlgeschlagen."
        }

        isSubmitting = false
    }
}
