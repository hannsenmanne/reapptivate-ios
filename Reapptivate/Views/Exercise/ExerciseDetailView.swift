import SwiftUI
import AVKit

struct ExerciseDetailView: View {
    @Environment(AppState.self) private var appState
    let exercise: ExerciseWithPhase
    let onLog: () -> Void
    let onStartSession: () -> Void

    private let videoStore = ExerciseVideoStore.shared
    @State private var savedVideoURL: URL?
    @State private var showVideoSourcePicker = false
    @State private var showCamera = false
    @State private var showLibrary = false
    @State private var hapticTrigger = false
    @State private var errorMessage: String?
    @AppStorage("appLanguage") private var appLanguage = "de"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection

                // Cognitive Cue
                if let subtype = appState.currentUser?.aemSubtype,
                   let cue = exercise.exercise.cognitiveCues?.cue(for: subtype) {
                    CognitiveCueBadge(subtype: subtype, cue: cue)
                }

                // Video or Description
                if let videoURL = savedVideoURL {
                    RecordedVideoSection(
                        videoURL: videoURL,
                        onReRecord: { showVideoSourcePicker = true },
                        onDelete: { Task { await deleteVideo() } }
                    )
                } else {
                    Text(exercise.exercise.description)
                        .font(.appBody)
                        .foregroundStyle(.textPrimary)

                    recordVideoButton
                }

                if let error = errorMessage {
                    InlineErrorView(message: error, onDismiss: {
                        errorMessage = nil
                    })
                }

                parametersCard
                actionButtons
            }
            .padding(16)
        }
        .background(Color.appBg)
        .navigationBarTitleDisplayMode(.inline)
        .task { loadSavedVideo() }
        .confirmationDialog(appLanguage == "en" ? "Add Video" : "Video hinzufügen", isPresented: $showVideoSourcePicker) {
            Button(appLanguage == "en" ? "Record Video" : "Video aufnehmen") { showCamera = true }
            Button(appLanguage == "en" ? "Choose from Library" : "Aus Mediathek wählen") { showLibrary = true }
            Button(appLanguage == "en" ? "Cancel" : "Abbrechen", role: .cancel) {}
        }
        .fullScreenCover(isPresented: $showCamera) {
            VideoCaptureView(onVideoRecorded: { url in Task { await saveVideo(from: url) } })
        }
        .sheet(isPresented: $showLibrary) {
            VideoLibraryPicker(onVideoPicked: { url in Task { await saveVideo(from: url) } })
                .glassSheet()
        }
        .sensoryFeedback(.success, trigger: hapticTrigger)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(exercise.exercise.type.displayName)
                .font(.appCaptionMedium)
                .foregroundStyle(.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.accent.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.badgeRadius, style: .continuous))

            Text(exercise.exercise.name)
                .font(.appTitle2)
                .foregroundStyle(.textPrimary)

            Text(exercise.phaseTitle)
                .font(.appSubheadline)
                .foregroundStyle(.textSecondary)
        }
    }

    // MARK: - Record Video Button

    private var recordVideoButton: some View {
        Button {
            showVideoSourcePicker = true
        } label: {
            Label(appLanguage == "en" ? "Record Video" : "Video aufnehmen", systemImage: "video.badge.plus")
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
            let isEn = appLanguage == "en"
            ParameterRow(label: isEn ? "Sets" : "Sätze", value: "\(exercise.exercise.sets)")
            ParameterRow(label: isEn ? "Reps" : "Wiederholungen", value: "\(exercise.exercise.reps)")

            if let holdTime = exercise.exercise.holdTime {
                ParameterRow(label: isEn ? "Hold time" : "Haltezeit", value: isEn
                    ? "\(holdTime) sec"
                    : "\(holdTime) Sek.")
            }

            if let tempo = exercise.exercise.tempo {
                ParameterRow(label: "Tempo", value: tempo)
            }

            ParameterRow(label: isEn ? "Intensity" : "Intensität", value: exercise.exercise.intensity)
            ParameterRow(label: isEn ? "Rest between sets" : "Pause zwischen Sätzen", value: isEn
                ? "\(exercise.exercise.restBetweenSets) sec"
                : "\(exercise.exercise.restBetweenSets) Sek.")
        }
        .cardStyle()
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                onStartSession()
            } label: {
                Label("Training starten", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
            }
            .buttonStyle(.accentFilled)

            Button {
                onLog()
            } label: {
                Label("Schnell protokollieren", systemImage: "checkmark.circle")
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
            }
            .buttonStyle(.secondary)
        }
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

// MARK: - Recorded Video Section

struct RecordedVideoSection: View {
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

struct ParameterRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.appSubheadline)
                .foregroundStyle(.textSecondary)
            Spacer()
            Text(value)
                .font(.appSubheadlineMedium)
                .foregroundStyle(.textPrimary)
        }
    }
}
