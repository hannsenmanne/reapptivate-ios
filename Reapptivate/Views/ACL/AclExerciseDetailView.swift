import SwiftUI
import AVKit

struct AclExerciseDetailView: View {
    let exercise: AclStreamExercise
    let isCompleted: Bool
    let onToggle: () -> Void

    private let videoStore = ExerciseVideoStore.shared
    @State private var savedVideoURL: URL?
    @State private var showVideoSourcePicker = false
    @State private var showCamera = false
    @State private var showLibrary = false
    @State private var hapticTrigger = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection

                // Video or Description
                if let videoURL = savedVideoURL {
                    AclRecordedVideoSection(
                        videoURL: videoURL,
                        onReRecord: { showVideoSourcePicker = true },
                        onDelete: { Task { await deleteVideo() } }
                    )
                } else {
                    if let desc = exercise.descriptionDE ?? exercise.description {
                        Text(desc)
                            .font(.appBody)
                            .foregroundStyle(.textPrimary)
                    }

                    recordVideoButton
                }

                if let error = errorMessage {
                    InlineErrorView(message: error, onDismiss: {
                        errorMessage = nil
                    })
                }

                // Parameters Card
                if hasParameters {
                    parametersCard
                }

                // Complete Button
                if isCompleted {
                    Button {
                        onToggle()
                    } label: {
                        Label("Als unerledigt markieren", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                    }
                    .buttonStyle(.secondary)
                } else {
                    Button {
                        onToggle()
                    } label: {
                        Label("Als erledigt markieren", systemImage: "checkmark.circle")
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                    }
                    .buttonStyle(.accentFilled)
                }
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
            Text(exercise.nameDE ?? exercise.name)
                .font(.appTitle2)
                .foregroundStyle(.textPrimary)

            if let intensity = exercise.intensity {
                Text(intensity)
                    .font(.appSubheadline)
                    .foregroundStyle(.textSecondary)
            }
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

    private var hasParameters: Bool {
        exercise.sets != nil || exercise.reps != nil || exercise.holdTime != nil || exercise.tempo != nil
    }

    private var parametersCard: some View {
        VStack(spacing: 12) {
            if let sets = exercise.sets {
                ParameterRow(label: "Sätze", value: "\(sets)")
            }
            if let reps = exercise.reps {
                ParameterRow(label: "Wiederholungen", value: reps)
            }
            if let holdTime = exercise.holdTime, holdTime > 0 {
                ParameterRow(label: "Haltezeit", value: "\(holdTime) Sek.")
            }
            if let tempo = exercise.tempo {
                ParameterRow(label: "Tempo", value: tempo)
            }
            if let intensity = exercise.intensity {
                ParameterRow(label: "Intensität", value: intensity)
            }
        }
        .cardStyle()
    }

    // MARK: - Actions

    private func loadSavedVideo() {
        savedVideoURL = videoStore.videoURL(for: exercise.id)
    }

    private func saveVideo(from sourceURL: URL) async {
        do {
            let saved = try await videoStore.saveVideo(from: sourceURL, for: exercise.id)
            savedVideoURL = saved
            errorMessage = nil
            hapticTrigger.toggle()
        } catch {
            errorMessage = "Video konnte nicht gespeichert werden."
        }
    }

    private func deleteVideo() async {
        try? await videoStore.deleteVideo(for: exercise.id)
        savedVideoURL = nil
    }
}

// MARK: - Recorded Video Section (ACL)

private struct AclRecordedVideoSection: View {
    let videoURL: URL
    let onReRecord: () -> Void
    let onDelete: () -> Void

    @State private var player: AVPlayer?

    var body: some View {
        VStack(spacing: 12) {
            VideoPlayer(player: player)
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cardRadius, style: .continuous))
                .task {
                    player = AVPlayer(url: videoURL)
                }
                .onDisappear {
                    player?.pause()
                    player = nil
                }

            HStack(spacing: 12) {
                Button {
                    onReRecord()
                } label: {
                    Label("Neu aufnehmen", systemImage: "arrow.triangle.2.circlepath")
                        .font(.appCaption)
                        .foregroundStyle(.accent)
                }

                Spacer()

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Löschen", systemImage: "trash")
                        .font(.appCaption)
                        .foregroundStyle(.red)
                }
            }
        }
    }
}
