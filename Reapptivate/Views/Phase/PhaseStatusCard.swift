import SwiftUI

struct PhaseStatusCard: View {
    let status: AdaptivePhaseStatus
    let maxPhase: Int

    @AppStorage("appLanguage") private var appLanguage = "de"

    var body: some View {
        let isEn = appLanguage == "en"

        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(status.phaseName)
                        .font(.appTitle3)
                        .foregroundStyle(.textPrimary)

                    Text(isEn ? "Day \(status.daysInPhase) in this phase" : "Tag \(status.daysInPhase) in dieser Phase")
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                }

                Spacer()

                DecisionBadge(decision: status.lastDecision)
            }

            // Stats Row
            HStack(spacing: 16) {
                MiniStat(label: isEn ? "Pain" : "Schmerz", value: String(format: "%.1f", status.currentPainAvg), color: Color.painColor(for: Int(status.currentPainAvg)))
                MiniStat(label: isEn ? "Compliance" : "Compliance", value: "\(Int(status.currentCompliance))%", color: status.currentCompliance >= 66 ? .painGreen : .painAmber)
                MiniStat(label: isEn ? "Sessions" : "Trainings", value: "\(status.sessionsInPhase)", color: .textPrimary)
            }

            // Readiness Checklist
            VStack(spacing: 8) {
                Text(isEn ? "Progression readiness" : "Fortschritts-Bereitschaft")
                    .font(.appCaptionMedium)
                    .foregroundStyle(.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ReadinessRow(label: isEn ? "Minimum time in phase" : "Mindestzeit in Phase", met: status.progressionReadiness.minDaysMet, isEn: isEn)
                ReadinessRow(label: isEn ? "Minimum sessions" : "Mindesttrainings", met: status.progressionReadiness.minSessionsMet, isEn: isEn)
                ReadinessRow(label: isEn ? "Pain criteria" : "Schmerzkriterien", met: status.progressionReadiness.painCriteriaMet, isEn: isEn)
                ReadinessRow(label: isEn ? "Compliance criteria" : "Compliance-Kriterien", met: status.progressionReadiness.complianceCriteriaMet, isEn: isEn)
            }

            // Progress bar
            HStack(spacing: 4) {
                ForEach(0..<4, id: \.self) { index in
                    Rectangle()
                        .fill(index < status.progressionReadiness.criteriaMetCount ? Color.painGreen : Color.textSecondary.opacity(0.2))
                        .frame(height: 4)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(isEn ? "Progress" : "Fortschritt")
            .accessibilityValue(isEn ? "\(status.progressionReadiness.criteriaMetCount) of 4 criteria met" : "\(status.progressionReadiness.criteriaMetCount) von 4 Kriterien erfüllt")

            // Hint
            Text(status.nextEvaluationHint)
                .font(.appCaption)
                .foregroundStyle(.textSecondary)
        }
        .cardStyle()
    }
}

struct MiniStat: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.appSubheadlineSemibold)
                .foregroundStyle(color)
            Text(label)
                .font(.appCaption2)
                .foregroundStyle(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

struct ReadinessRow: View {
    let label: String
    let met: Bool
    var isEn: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: met ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(met ? .painGreen : .textSecondary.opacity(0.4))
                .font(.appBody)
                .accessibilityHidden(true)
            Text(label)
                .font(.appSubheadline)
                .foregroundStyle(met ? .textPrimary : .textSecondary)
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
        .accessibilityValue(met ? (isEn ? "Met" : "Erfüllt") : (isEn ? "Not yet met" : "Noch nicht erfüllt"))
    }
}
