import SwiftUI
import AVFoundation

struct CustomExerciseCardView: View {
    let exercise: CustomExercise
    let isCompleted: Bool
    let onTap: () -> Void

    @AppStorage("appLanguage") private var appLanguage = "de"
    @ScaledMetric(relativeTo: .body) private var thumbnailSize: CGFloat = 56
    @State private var videoThumbnail: UIImage?

    private var isEn: Bool { appLanguage == "en" }

    private let videoStore = ExerciseVideoStore.shared

    /// Video key uses "custom_" prefix to avoid collisions with protocol exercise IDs
    private var videoKey: String { "custom_\(exercise.id)" }

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: 14) {
                // Thumbnail: video frame if available, otherwise icon placeholder
                if let thumbnail = videoThumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: thumbnailSize, height: thumbnailSize)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.smallRadius, style: .continuous))
                } else {
                    RoundedRectangle(cornerRadius: DesignTokens.smallRadius, style: .continuous)
                        .fill(isCompleted ? Color.painGreen.opacity(0.15) : Color.blue.opacity(0.12))
                        .frame(width: thumbnailSize, height: thumbnailSize)
                        .overlay {
                            Image(systemName: "person.fill")
                                .font(.appTitle3)
                                .foregroundStyle(isCompleted ? .painGreen : .blue)
                        }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(exercise.name)
                        .font(.appSubheadlineSemibold)
                        .foregroundStyle(.textPrimary)
                        .lineLimit(1)

                    Text(exerciseSummary)
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.painGreen)
                        .font(.appTitle2)
                        .accessibilityLabel(isEn ? "Completed" : "Abgeschlossen")
                } else {
                    Image(systemName: "play.circle.fill")
                        .foregroundStyle(.blue)
                        .font(.appTitle2)
                        .accessibilityHidden(true)
                }
            }
            .padding(12)
            .background(Color.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cardRadius, style: .continuous))
            .shadow(
                color: DesignTokens.cardShadowColor,
                radius: DesignTokens.cardShadowRadius,
                y: DesignTokens.cardShadowY
            )
        }
        .buttonStyle(.plain)
        .task(id: exercise.id) { await loadVideoThumbnail() }
    }

    private func loadVideoThumbnail() async {
        guard let videoURL = videoStore.videoURL(for: videoKey) else {
            videoThumbnail = nil
            return
        }
        guard videoThumbnail == nil else { return }
        let url = videoURL
        let image: UIImage? = await Task.detached(priority: .utility) {
            let asset = AVAsset(url: url)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            generator.maximumSize = CGSize(width: 200, height: 200)
            guard let cgImage = try? generator.copyCGImage(at: .zero, actualTime: nil) else { return nil }
            return UIImage(cgImage: cgImage)
        }.value
        if let image {
            videoThumbnail = image
        }
    }

    private var exerciseSummary: String {
        var parts: [String] = []
        parts.append("\(exercise.sets) × \(exercise.reps)")
        if let pauseSeconds = exercise.pauseSeconds, pauseSeconds > 0 {
            parts.append(isEn ? "\(pauseSeconds)s Rest" : "\(pauseSeconds)s Pause")
        }
        parts.append(isEn ? "Therapist Exercise" : "Therapeuten-Übung")
        return parts.joined(separator: " · ")
    }
}
