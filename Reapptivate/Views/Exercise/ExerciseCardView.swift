import SwiftUI
import AVFoundation

struct ExerciseCardView: View {
    let exercise: ExerciseWithPhase
    let isCompleted: Bool
    var userSubtype: AemSubtype?
    let onTap: () -> Void

    @ScaledMetric(relativeTo: .body) private var thumbnailSize: CGFloat = 56
    @State private var videoThumbnail: UIImage?
    @AppStorage("appLanguage") private var appLanguage = "de"

    private let videoStore = ExerciseVideoStore.shared

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
                        .fill(isCompleted ? Color.painGreen.opacity(0.15) : Color.accent.opacity(0.12))
                        .frame(width: thumbnailSize, height: thumbnailSize)
                        .overlay {
                            Image(systemName: exerciseTypeIcon)
                                .font(.appTitle3)
                                .foregroundStyle(isCompleted ? .painGreen : .accent)
                        }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(exercise.exercise.name)
                        .font(.appSubheadlineSemibold)
                        .foregroundStyle(.textPrimary)
                        .lineLimit(1)

                    Text(exerciseSummary)
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                        .lineLimit(1)

                    if let subtype = userSubtype,
                       let cue = exercise.exercise.cognitiveCues?.cue(for: subtype) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.subtypeColor(for: subtype))
                                .frame(width: 6, height: 6)
                            Text(cue)
                                .font(.appCaption2)
                                .foregroundStyle(Color.subtypeColor(for: subtype))
                                .lineLimit(1)
                        }
                    }
                }

                Spacer()

                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.painGreen)
                        .font(.appTitle2)
                        .accessibilityLabel(appLanguage == "en" ? "Completed" : "Abgeschlossen")
                } else {
                    HStack(spacing: 6) {
                        if videoThumbnail == nil, exercise.exercise.videoUrl != nil {
                            Image(systemName: "play.rectangle.fill")
                                .foregroundStyle(.textSecondary)
                                .font(.appCaption)
                                .accessibilityLabel(appLanguage == "en" ? "Video available" : "Video verfügbar")
                        }
                        Image(systemName: "play.circle.fill")
                            .foregroundStyle(.accent)
                            .font(.appTitle2)
                            .accessibilityHidden(true)
                    }
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
        guard let videoURL = videoStore.videoURL(for: exercise.id) else {
            videoThumbnail = nil
            return
        }
        // Skip if already loaded
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
        let isEn = appLanguage == "en"
        var parts: [String] = []
        parts.append("\(exercise.exercise.sets) × \(exercise.exercise.reps)")
        if let holdTime = exercise.exercise.holdTime {
            parts.append(isEn ? "\(holdTime)s hold" : "\(holdTime)s halten")
        }
        parts.append(exercise.exercise.type.displayName)
        return parts.joined(separator: " · ")
    }

    private var exerciseTypeIcon: String {
        switch exercise.exercise.type {
        case .isometric: "hand.raised"
        case .hsr: "dumbbell.fill"
        case .eccentric: "arrow.down.circle"
        case .concentric: "arrow.up.circle"
        case .motorControl: "figure.mind.and.body"
        case .bodyAwareness: "figure.cooldown"
        case .pacing: "timer"
        case .gradedActivity: "chart.bar.fill"
        case .relaxation: "leaf"
        case .functional: "figure.walk"
        case .unknown: "questionmark.circle"
        }
    }
}

// MARK: - Cognitive Cue Badge

struct CognitiveCueBadge: View {
    let subtype: AemSubtype
    let cue: String

    var icon: String {
        switch subtype {
        case .FAR: "magnifyingglass"
        case .DER: "timer"
        case .EER: "chart.bar"
        case .AR, .unknown: "checkmark.circle"
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.appCaption)
                .foregroundStyle(Color.subtypeColor(for: subtype))

            Text(cue)
                .font(.appCaption)
                .foregroundStyle(Color.subtypeColor(for: subtype))
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.subtypeColor(for: subtype).opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.smallRadius, style: .continuous))
    }
}

// MARK: - Parameter Pills

struct ExerciseParameterPills: View {
    let exercise: Exercise
    @AppStorage("appLanguage") private var appLanguage = "de"

    var body: some View {
        let isEn = appLanguage == "en"
        FlowLayout(spacing: 6) {
            ParameterPill(label: "\(exercise.sets) x \(exercise.reps)", icon: "repeat")

            if let holdTime = exercise.holdTime {
                ParameterPill(label: isEn ? "\(holdTime)s hold" : "\(holdTime)s halten", icon: "timer")
            }

            if let tempo = exercise.tempo {
                ParameterPill(label: tempo, icon: "metronome")
            }

            ParameterPill(label: exercise.intensity, icon: "flame")

            ParameterPill(label: isEn ? "\(exercise.restBetweenSets)s rest" : "\(exercise.restBetweenSets)s Pause", icon: "pause.circle")
        }
    }
}

struct ParameterPill: View {
    let label: String
    let icon: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.appCaption2)
            Text(label)
                .font(.appCaption2)
        }
        .foregroundStyle(.textSecondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.textSecondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.badgeRadius, style: .continuous))
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxX = max(maxX, currentX)
        }

        return (CGSize(width: maxX, height: currentY + lineHeight), positions)
    }
}
