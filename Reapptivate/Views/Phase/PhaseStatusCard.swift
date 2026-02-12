import SwiftUI

struct PhaseStatusCard: View {
    let status: AdaptivePhaseStatus
    let maxPhase: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(status.phaseName)
                        .font(.title3.bold())
                        .foregroundStyle(.textPrimary)

                    Text("Tag \(status.daysInPhase) in dieser Phase")
                        .font(.caption)
                        .foregroundStyle(.textSecondary)
                }

                Spacer()

                DecisionBadge(decision: status.lastDecision)
            }

            // Stats Row
            HStack(spacing: 16) {
                MiniStat(label: "Schmerz", value: String(format: "%.1f", status.currentPainAvg), color: Color.painColor(for: Int(status.currentPainAvg)))
                MiniStat(label: "Compliance", value: "\(Int(status.currentCompliance))%", color: status.currentCompliance >= 66 ? .painGreen : .painAmber)
                MiniStat(label: "Trainings", value: "\(status.sessionsInPhase)", color: .textPrimary)
            }

            // Readiness Checklist
            VStack(spacing: 8) {
                Text("Fortschritts-Bereitschaft")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ReadinessRow(label: "Mindestzeit in Phase", met: status.progressionReadiness.minDaysMet)
                ReadinessRow(label: "Mindesttrainings", met: status.progressionReadiness.minSessionsMet)
                ReadinessRow(label: "Schmerzkriterien", met: status.progressionReadiness.painCriteriaMet)
                ReadinessRow(label: "Compliance-Kriterien", met: status.progressionReadiness.complianceCriteriaMet)
            }

            // Progress bar
            HStack(spacing: 4) {
                ForEach(0..<4, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(index < status.progressionReadiness.criteriaMetCount ? Color.painGreen : Color.textSecondary.opacity(0.2))
                        .frame(height: 4)
                }
            }

            // Hint
            Text(status.nextEvaluationHint)
                .font(.caption)
                .foregroundStyle(.textSecondary)
        }
        .padding(16)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct MiniStat: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ReadinessRow: View {
    let label: String
    let met: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: met ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(met ? .painGreen : .textSecondary.opacity(0.4))
                .font(.body)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(met ? .textPrimary : .textSecondary)
            Spacer()
        }
    }
}
