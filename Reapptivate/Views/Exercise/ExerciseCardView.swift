import SwiftUI

struct ExerciseCardView: View {
    let exercise: ExerciseWithPhase
    let index: Int
    let isCompleted: Bool
    var userSubtype: AemSubtype?
    let onLog: () -> Void
    var onDetail: (() -> Void)?

    @ScaledMetric(relativeTo: .caption) private var badgeSize: CGFloat = 28

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header (tappable for detail)
            Button {
                onDetail?()
            } label: {
                HStack(alignment: .top) {
                    // Number badge
                    Text(String(format: "%02d", index + 1))
                        .font(.appCaptionBold.monospacedDigit())
                        .foregroundStyle(.white)
                        .frame(width: badgeSize, height: badgeSize)
                        .background(isCompleted ? Color.painGreen : Color.accent)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.smallRadius, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(exercise.exercise.name)
                            .font(.appSubheadlineSemibold)
                            .foregroundStyle(.textPrimary)

                        Text(exercise.exercise.type.displayName)
                            .font(.appCaption)
                            .foregroundStyle(.textSecondary)
                    }

                    Spacer()

                    if isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.painGreen)
                            .font(.title3)
                            .accessibilityLabel("Abgeschlossen")
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.appCaption)
                            .foregroundStyle(.textSecondary)
                            .accessibilityHidden(true)
                    }
                }
            }
            .buttonStyle(.plain)

            // Description
            Text(exercise.exercise.description)
                .font(.appCaption)
                .foregroundStyle(.textSecondary)
                .lineLimit(3)

            // Cognitive Cue (LBP only)
            if let subtype = userSubtype,
               let cue = exercise.exercise.cognitiveCues?.cue(for: subtype) {
                CognitiveCueBadge(subtype: subtype, cue: cue)
            }

            // Parameters
            ExerciseParameterPills(exercise: exercise.exercise)

            // Action Button
            if isCompleted {
                Button {
                    onLog()
                } label: {
                    Text("Erneut")
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                }
                .buttonStyle(.secondary)
            } else {
                Button {
                    onLog()
                } label: {
                    Text("Eintragen")
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                }
                .buttonStyle(.accentFilled)
            }
        }
        .cardStyle()
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
        case .AR: "checkmark.circle"
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

    var body: some View {
        FlowLayout(spacing: 6) {
            ParameterPill(label: "\(exercise.sets) x \(exercise.reps)", icon: "repeat")

            if let holdTime = exercise.holdTime {
                ParameterPill(label: "\(holdTime)s halten", icon: "timer")
            }

            if let tempo = exercise.tempo {
                ParameterPill(label: tempo, icon: "metronome")
            }

            ParameterPill(label: exercise.intensity, icon: "flame")

            ParameterPill(label: "\(exercise.restBetweenSets)s Pause", icon: "pause.circle")
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
