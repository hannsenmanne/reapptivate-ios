import SwiftUI

struct ProgressLogSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(APIClient.self) private var apiClient
    @Environment(\.dismiss) private var dismiss

    let exercise: ExerciseWithPhase
    let maxPainLevel: Int
    let showSymptomResponse: Bool
    let onSuccess: () -> Void

    @State private var painLevel = 0
    @State private var setsCompleted: Int
    @State private var repsCompleted: Int
    @State private var notes = ""
    @State private var symptomResponse: SymptomResponse?
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showSuccess = false
    @State private var adaptationResult: AdaptationResult?

    init(exercise: ExerciseWithPhase, maxPainLevel: Int, showSymptomResponse: Bool, onSuccess: @escaping () -> Void) {
        self.exercise = exercise
        self.maxPainLevel = maxPainLevel
        self.showSymptomResponse = showSymptomResponse
        self.onSuccess = onSuccess
        _setsCompleted = State(initialValue: exercise.exercise.sets)
        _repsCompleted = State(initialValue: exercise.exercise.reps)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Exercise name
                    VStack(spacing: 4) {
                        Text(exercise.exercise.name)
                            .font(.appHeadline)
                            .foregroundStyle(.textPrimary)
                        Text(exercise.exercise.type.displayName)
                            .font(.appCaption)
                            .foregroundStyle(.textSecondary)
                    }

                    // Pain Slider
                    PainSliderView(painLevel: $painLevel, maxPainLevel: maxPainLevel)

                    // Sets & Reps
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Satze")
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

                    // Symptom Response (neck radiculopathy)
                    if showSymptomResponse {
                        SymptomResponsePicker(selection: $symptomResponse)
                    }

                    // Notes
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Notizen (optional)")
                            .font(.appCaption)
                            .foregroundStyle(.textSecondary)
                        TextField("Wie haben Sie sich gefuhlt?", text: $notes, axis: .vertical)
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
        .overlay {
            if let result = adaptationResult, result.phaseChanged {
                PhaseChangeOverlay(result: result) {
                    adaptationResult = nil
                    dismiss()
                }
            }
        }
    }

    private func submit() async {
        isSubmitting = true
        errorMessage = nil

        let request = ProgressLogRequest(
            exerciseId: exercise.id,
            painLevel: painLevel,
            setsCompleted: setsCompleted,
            repsCompleted: repsCompleted,
            notes: notes.isEmpty ? nil : notes,
            symptomResponse: symptomResponse
        )

        do {
            let response: ProgressLogResponse = try await apiClient.request(
                APIEndpoints.logProgress(body: request)
            )

            if let adaptation = response.adaptation, adaptation.phaseChanged {
                adaptationResult = adaptation
            } else {
                showSuccess = true
                onSuccess()
                try? await Task.sleep(for: .seconds(1.5))
                dismiss()
            }
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Speichern fehlgeschlagen."
        }

        isSubmitting = false
    }
}

// MARK: - Success Banner

struct SuccessBanner: View {
    let message: String

    var body: some View {
        VStack {
            Spacer()
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.white)
                Text(message)
                    .font(.appSubheadlineMedium)
                    .foregroundStyle(.white)
            }
            .padding(16)
            .background(Color.painGreen)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cardRadius, style: .continuous))
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(duration: 0.3), value: true)
    }
}

// MARK: - Phase Change Overlay

struct PhaseChangeOverlay: View {
    let result: AdaptationResult
    let onDismiss: () -> Void

    var isProgress: Bool { result.decision == .progress }

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: isProgress ? "arrow.up.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(isProgress ? .painGreen : .painAmber)

                Text(isProgress ? "Aufgestiegen!" : "Phase angepasst")
                    .font(.appTitle)
                    .foregroundStyle(.white)

                Text("Phase \(result.previousPhase) → Phase \(result.currentPhase)")
                    .font(.appTitle3)
                    .foregroundStyle(.white.opacity(0.8))

                Text(result.reason)
                    .font(.appBody)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Button("Weiter") {
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(.white)
                .foregroundStyle(isProgress ? .painGreen : .painAmber)
                .padding(.top, 8)
            }
            .padding(32)
        }
    }
}
