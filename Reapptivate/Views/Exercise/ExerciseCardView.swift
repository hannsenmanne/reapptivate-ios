import SwiftUI

struct ExerciseCardView: View {
    let exercise: ExerciseWithPhase
    let index: Int
    let isCompleted: Bool
    var userSubtype: AemSubtype?
    let onLog: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(alignment: .top) {
                // Number badge
                Text(String(format: "%02d", index + 1))
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(isCompleted ? Color.painGreen : Color.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.exercise.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.textPrimary)

                    Text(exercise.exercise.type.displayName)
                        .font(.caption)
                        .foregroundStyle(.textSecondary)
                }

                Spacer()

                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.painGreen)
                        .font(.title3)
                }
            }

            // Description
            Text(exercise.exercise.description)
                .font(.caption)
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
            Button {
                onLog()
            } label: {
                Text(isCompleted ? "Erneut" : "Erledigt")
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
            }
            .buttonStyle(.borderedProminent)
            .tint(isCompleted ? .textSecondary : .accent)
        }
        .padding(16)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
                .font(.caption)
                .foregroundStyle(Color.subtypeColor(for: subtype))

            Text(cue)
                .font(.caption)
                .foregroundStyle(Color.subtypeColor(for: subtype))
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.subtypeColor(for: subtype).opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
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
                .font(.caption2)
            Text(label)
                .font(.caption2)
        }
        .foregroundStyle(.textSecondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.textSecondary.opacity(0.1))
        .clipShape(Capsule())
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
