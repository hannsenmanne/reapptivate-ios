import SwiftUI

struct PhaseTimelineView: View {
    let records: [PhaseAdaptationRecord]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Phasen-Verlauf")
                .font(.appHeadline)
                .foregroundStyle(.textPrimary)

            if records.isEmpty {
                Text("Noch keine Phasenentscheidungen.")
                    .font(.appSubheadline)
                    .foregroundStyle(.textSecondary)
                    .frame(maxWidth: .infinity)
                    .cardStyle(padding: 20)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(records.enumerated()), id: \.element.id) { index, record in
                        TimelineEntryView(
                            record: record,
                            isLast: index == records.count - 1
                        )
                    }
                }
            }
        }
    }
}

struct TimelineEntryView: View {
    let record: PhaseAdaptationRecord
    let isLast: Bool

    var color: Color {
        switch record.decision {
        case .progress: .phaseProgress
        case .hold: .phaseHold
        case .regress: .phaseRegress
        case .initial: .phaseInitial
        }
    }

    var icon: String {
        switch record.decision {
        case .progress: "arrow.up.circle.fill"
        case .hold: "pause.circle.fill"
        case .regress: "arrow.down.circle.fill"
        case .initial: "play.circle.fill"
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Timeline line + dot
            VStack(spacing: 0) {
                Image(systemName: icon)
                    .font(.appTitle3)
                    .foregroundStyle(color)

                if !isLast {
                    Rectangle()
                        .fill(Color.textSecondary.opacity(0.2))
                        .frame(width: 2)
                        .frame(minHeight: 40)
                }
            }
            .frame(width: 28)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(record.decision.displayName)
                        .font(.appSubheadlineSemibold)
                        .foregroundStyle(color)

                    if let prev = record.previousPhase {
                        Text("Phase \(prev) → \(record.currentPhase)")
                            .font(.appCaption)
                            .foregroundStyle(.textSecondary)
                    } else {
                        Text("Phase \(record.currentPhase)")
                            .font(.appCaption)
                            .foregroundStyle(.textSecondary)
                    }

                    Spacer()
                }

                Text(record.reason)
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)

                if let date = record.decidedAtDate {
                    Text(date.formattedShortGerman)
                        .font(.appCaption2)
                        .foregroundStyle(.textSecondary.opacity(0.7))
                }

                // Metrics
                HStack(spacing: 12) {
                    if let pain = record.avgPainLevel {
                        Text("Schmerz: \(String(format: "%.1f", pain))")
                            .font(.appCaption2)
                    }
                    if let compliance = record.compliancePct {
                        Text("Compliance: \(Int(compliance))%")
                            .font(.appCaption2)
                    }
                }
                .foregroundStyle(.textSecondary)
            }
            .padding(.bottom, isLast ? 0 : 16)
        }
    }
}
