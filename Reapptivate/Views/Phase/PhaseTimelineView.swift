import SwiftUI

struct PhaseTimelineView: View {
    let records: [PhaseAdaptationRecord]
    @AppStorage("appLanguage") private var appLanguage = "de"

    private var isEn: Bool { appLanguage == "en" }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(isEn ? "Phase history" : "Phasen-Verlauf")
                .font(.appHeadline)
                .foregroundStyle(.textPrimary)

            if records.isEmpty {
                Text(isEn ? "No phase decisions yet." : "Noch keine Phasenentscheidungen.")
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
    @AppStorage("appLanguage") private var appLanguage = "de"

    private var isEn: Bool { appLanguage == "en" }

    var color: Color {
        switch record.decision {
        case .progress: .phaseProgress
        case .hold: .phaseHold
        case .regress: .phaseRegress
        case .initial, .unknown: .phaseInitial
        }
    }

    var icon: String {
        switch record.decision {
        case .progress: "arrow.up.circle.fill"
        case .hold: "pause.circle.fill"
        case .regress: "arrow.down.circle.fill"
        case .initial, .unknown: "play.circle.fill"
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
                    Text(date.formattedShortLocalized)
                        .font(.appCaption2)
                        .foregroundStyle(.textSecondary.opacity(0.7))
                }

                // Metrics
                HStack(spacing: 12) {
                    if let pain = record.avgPainLevel {
                        Text(appLanguage == "en"
                            ? "Pain: \(String(format: "%.1f", pain))"
                            : "Schmerz: \(String(format: "%.1f", pain))")
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
