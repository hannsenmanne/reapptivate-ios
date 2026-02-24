import SwiftUI

struct AclMilestoneTimelineView: View {
    let currentMilestone: Int
    let weeksPostSurgery: Int

    private let milestones: [(id: Int, label: String, shortLabel: String, weekRange: String)] = [
        (0, "Prä-OP", "Prä", ""),
        (1, "Meilenstein 1", "M1", "Woche 0-6"),
        (2, "Meilenstein 2", "M2", "Woche 7-12"),
        (3, "Meilenstein 3", "M3", "Woche 13-24"),
        (4, "Meilenstein 4", "M4", "Woche 25-36"),
        (5, "Entlassung", "M5", "Ab Woche 36"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Rehabilitations-Fortschritt")
                        .font(.appHeadline)
                        .foregroundStyle(.textPrimary)
                    Text("Woche \(weeksPostSurgery) nach OP")
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                }
                Spacer()
            }

            // Timeline
            GeometryReader { geo in
                let totalWidth = geo.size.width
                let nodeCount = milestones.count
                let spacing = nodeCount > 1 ? totalWidth / CGFloat(nodeCount - 1) : 0

                ZStack(alignment: .leading) {
                    // Background track
                    Rectangle()
                        .fill(Color.gray200)
                        .frame(height: 2)
                        .offset(y: 0)

                    // Filled track
                    Rectangle()
                        .fill(Color.accent)
                        .frame(
                            width: nodeCount > 1
                                ? spacing * CGFloat(min(currentMilestone, nodeCount - 1))
                                : 0,
                            height: 2
                        )

                    // Nodes
                    ForEach(0..<nodeCount, id: \.self) { index in
                        let isPast = index < currentMilestone
                        let isCurrent = index == currentMilestone
                        let xPos = spacing * CGFloat(index)

                        VStack(spacing: 6) {
                            // Dot
                            Circle()
                                .fill(isPast || isCurrent ? Color.accent : Color.gray300)
                                .frame(
                                    width: isCurrent ? 12 : 8,
                                    height: isCurrent ? 12 : 8
                                )
                                .overlay {
                                    if isPast {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 5, weight: .bold))
                                            .foregroundStyle(.white)
                                    }
                                }

                            // Label
                            Text(milestones[index].shortLabel)
                                .font(isCurrent ? .appCaptionBold : .appCaption2)
                                .foregroundStyle(
                                    isCurrent ? .textPrimary :
                                    isPast ? .textSecondary : .textTertiary
                                )

                            // Week range for current
                            if isCurrent && !milestones[index].weekRange.isEmpty {
                                Text(milestones[index].weekRange)
                                    .font(.appCaption2)
                                    .foregroundStyle(.textSecondary)
                            }
                        }
                        .frame(width: 60)
                        .position(x: xPos, y: 0)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(milestoneAccessibilityLabel(index: index, isPast: isPast, isCurrent: isCurrent))
                    }
                }
            }
            .frame(height: 60)
        }
        .cardStyle()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Rehabilitations-Fortschritt, Woche \(weeksPostSurgery) nach OP")
    }

    private func milestoneAccessibilityLabel(index: Int, isPast: Bool, isCurrent: Bool) -> String {
        let milestone = milestones[index]
        let state = isCurrent ? "aktuell" : isPast ? "abgeschlossen" : "ausstehend"
        let weekInfo = milestone.weekRange.isEmpty ? "" : ", \(milestone.weekRange)"
        return "\(milestone.label), \(state)\(weekInfo)"
    }
}
