import SwiftUI

struct PacingPlanView: View {
    @Bindable var viewModel: LbpEnhancementsViewModel

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: "timer")
                    .font(.title3)
                    .foregroundStyle(Color.subtypeColor(for: viewModel.subtype))
                Text("Pacing-Plan")
                    .font(.headline)
                    .foregroundStyle(.textPrimary)
                Spacer()
            }

            if let plan = viewModel.pacingPlan {
                // Activities
                ForEach(plan.targetActivities) { activity in
                    PacingActivityRow(activity: activity, plan: plan)
                }

                // Rules
                if let rules = Optional(plan.rules) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Regeln")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.textSecondary)

                        if let increment = rules.quotaIncrementPercent {
                            RuleRow(icon: "chart.line.uptrend.xyaxis", text: "Steigerung: \(increment)% pro Woche")
                        }
                        if let pause = rules.mandatoryPauseMinutes, pause > 0 {
                            RuleRow(icon: "pause.circle", text: "Obligatorische Pause: \(pause) Min")
                        }
                        if let freq = rules.pauseFrequencyMinutes, freq > 0 {
                            RuleRow(icon: "clock.arrow.circlepath", text: "Pause alle \(freq) Min")
                        }
                        if let cap = rules.weeklySessionCap {
                            RuleRow(icon: "calendar", text: "Max. \(cap) Einheiten/Woche")
                        }
                    }
                    .padding(12)
                    .background(Color.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "gauge.with.dots.needle.bottom.50percent")
                        .font(.system(size: 32))
                        .foregroundStyle(.textSecondary)
                    Text("Noch kein Pacing-Plan")
                        .font(.subheadline)
                        .foregroundStyle(.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            }
        }
    }
}

// MARK: - Pacing Activity Row

struct PacingActivityRow: View {
    let activity: TargetActivity
    let plan: PacingPlan

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.farBlue.opacity(0.15))
                .frame(width: 36, height: 36)
                .overlay {
                    Image(systemName: activityIcon)
                        .font(.caption)
                        .foregroundStyle(.farBlue)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(activity.label)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.textPrimary)

                if plan.baselineMode {
                    Text("Baseline-Phase")
                        .font(.caption)
                        .foregroundStyle(.painAmber)
                } else if let quota = activity.quota {
                    Text("Ziel: \(quota) \(activity.unit ?? "Min")")
                        .font(.caption)
                        .foregroundStyle(.textSecondary)
                }
            }

            Spacer()

            if let baseline = activity.baseline {
                VStack(alignment: .trailing, spacing: 0) {
                    Text("\(baseline)")
                        .font(.subheadline.weight(.bold).monospacedDigit())
                        .foregroundStyle(.textPrimary)
                    Text("Baseline")
                        .font(.caption2)
                        .foregroundStyle(.textSecondary)
                }
            }
        }
        .padding(12)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    var activityIcon: String {
        let key = activity.key.lowercased()
        if key.contains("sitz") { return "chair.fill" }
        if key.contains("steh") { return "figure.stand" }
        if key.contains("geh") || key.contains("walk") { return "figure.walk" }
        if key.contains("sport") || key.contains("train") { return "dumbbell.fill" }
        if key.contains("haus") || key.contains("garten") { return "house.fill" }
        return "clock.fill"
    }
}

// MARK: - Rule Row

struct RuleRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.painGreen)
                .frame(width: 16)
            Text(text)
                .font(.caption)
                .foregroundStyle(.textPrimary)
        }
    }
}
