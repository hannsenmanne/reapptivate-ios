import SwiftUI
import AVKit

struct CustomExerciseDetailView: View {
    let exercise: CustomExercise
    let onLog: () -> Void

    private let videoStore = ExerciseVideoStore.shared
    @State private var savedVideoURL: URL?
    @State private var showVideoSourcePicker = false
    @State private var showCamera = false
    @State private var showLibrary = false
    @State private var hapticTrigger = false
    @State private var errorMessage: String?

    /// Video key uses "custom_" prefix to avoid collisions with protocol exercise IDs
    private var videoKey: String { "custom_\(exercise.id)" }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection

                // Video or Description
                if let videoURL = savedVideoURL {
                    RecordedVideoSection(
                        videoURL: videoURL,
                        onReRecord: { showVideoSourcePicker = true },
                        onDelete: { Task { await deleteVideo() } }
                    )
                } else {
                    Text(exercise.description)
                        .font(.appBody)
                        .foregroundStyle(.textPrimary)

                    recordVideoButton
                }

                if let error = errorMessage {
                    InlineErrorView(message: error, onDismiss: {
                        errorMessage = nil
                    })
                }

                if let extra = exercise.extra, !extra.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Hinweise")
                            .font(.appCaptionMedium)
                            .foregroundStyle(.textSecondary)
                        Text(extra)
                            .font(.appBody)
                            .foregroundStyle(.textPrimary)
                    }
                }

                parametersCard
                actionButtons
            }
            .padding(16)
        }
        .background(Color.appBg)
        .navigationBarTitleDisplayMode(.inline)
        .task { loadSavedVideo() }
        .confirmationDialog("Video hinzufügen", isPresented: $showVideoSourcePicker) {
            Button("Video aufnehmen") { showCamera = true }
            Button("Aus Mediathek wählen") { showLibrary = true }
            Button("Abbrechen", role: .cancel) {}
        }
        .fullScreenCover(isPresented: $showCamera) {
            VideoCaptureView(onVideoRecorded: { url in Task { await saveVideo(from: url) } })
        }
        .sheet(isPresented: $showLibrary) {
            VideoLibraryPicker(onVideoPicked: { url in Task { await saveVideo(from: url) } })
        }
        .sensoryFeedback(.success, trigger: hapticTrigger)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Therapeuten-Übung")
                .font(.appCaptionMedium)
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.badgeRadius, style: .continuous))

            Text(exercise.name)
                .font(.appTitle2)
                .foregroundStyle(.textPrimary)
        }
    }

    // MARK: - Record Video Button

    private var recordVideoButton: some View {
        Button {
            showVideoSourcePicker = true
        } label: {
            Label("Video aufnehmen", systemImage: "video.badge.plus")
                .font(.appSubheadlineMedium)
                .foregroundStyle(.accent)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color.accent.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.buttonRadius, style: .continuous))
        }
    }

    // MARK: - Parameters Card

    private var parametersCard: some View {
        VStack(spacing: 12) {
            ParameterRow(label: "Sätze", value: "\(exercise.sets)")
            ParameterRow(label: "Wiederholungen", value: "\(exercise.reps)")

            if let pauseSeconds = exercise.pauseSeconds, pauseSeconds > 0 {
                ParameterRow(label: "Pause zwischen Sätzen", value: UserDefaults.standard.string(forKey: "appLanguage") == "en"
                    ? "\(pauseSeconds) sec"
                    : "\(pauseSeconds) Sek.")
            }
        }
        .cardStyle()
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        Button {
            onLog()
        } label: {
            Label("Training protokollieren", systemImage: "checkmark.circle")
                .frame(maxWidth: .infinity)
                .frame(height: 48)
        }
        .buttonStyle(.accentFilled)
    }

    // MARK: - Actions

    private func loadSavedVideo() {
        savedVideoURL = videoStore.videoURL(for: videoKey)
    }

    private func saveVideo(from sourceURL: URL) async {
        do {
            let saved = try await videoStore.saveVideo(from: sourceURL, for: videoKey)
            savedVideoURL = saved
            errorMessage = nil
            hapticTrigger.toggle()
        } catch {
            errorMessage = "Video konnte nicht gespeichert werden."
        }
    }

    private func deleteVideo() async {
        try? await videoStore.deleteVideo(for: videoKey)
        savedVideoURL = nil
    }
}
