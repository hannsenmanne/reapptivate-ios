import SwiftUI

struct PacingAdjustmentHistoryView: View {
    @Bindable var viewModel: LbpEnhancementsViewModel
    @AppStorage("appLanguage") private var appLanguage = "de"

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "arrow.triangle.branch")
                    .font(.appTitle3)
                    .foregroundStyle(.painAmber)
                Text(appLanguage == "en" ? "Plan Adjustments" : "Plan-Anpassungen")
                    .font(.appHeadline)
                    .foregroundStyle(.textPrimary)
                Spacer()
            }

            if viewModel.planAdjustments.isEmpty {
                VStack(spacing: 8) {
                    Text(appLanguage == "en" ? "No adjustments" : "Keine Anpassungen")
                        .font(.appSubheadline)
                        .foregroundStyle(.textSecondary)
                    Text(appLanguage == "en"
                        ? "Automatic adjustments will appear here when trigger rules are activated."
                        : "Automatische Anpassungen werden hier angezeigt, wenn Trigger-Regeln aktiviert werden.")
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 16)
            } else {
                ForEach(viewModel.planAdjustments) { adjustment in
                    AdjustmentRow(adjustment: adjustment)
                }
            }
        }
        .task {
            await viewModel.loadPlanAdjustments()
        }
    }
}

// MARK: - Adjustment Row

struct AdjustmentRow: View {
    let adjustment: PlanAdjustment
    @AppStorage("appLanguage") private var appLanguage = "de"

    var ruleDisplayName: String {
        switch adjustment.ruleId {
        case "FLARE_RULE": return appLanguage == "en" ? "Pain Flare" : "Schmerz-Schub"
        case "LOW_ADHERENCE_RULE": return appLanguage == "en" ? "Low Adherence" : "Niedrige Adhärenz"
        case "OVERDOING_RULE_DER": return appLanguage == "en" ? "Overexertion" : "Überbelastung"
        case "FEAR_STUCK_RULE": return appLanguage == "en" ? "Avoidance Detected" : "Vermeidung erkannt"
        default: return adjustment.ruleId
        }
    }

    var ruleIcon: String {
        switch adjustment.ruleId {
        case "FLARE_RULE": return "flame.fill"
        case "LOW_ADHERENCE_RULE": return "arrow.down.circle"
        case "OVERDOING_RULE_DER": return "exclamationmark.triangle.fill"
        case "FEAR_STUCK_RULE": return "eye.slash"
        default: return "gear"
        }
    }

    var ruleColor: Color {
        switch adjustment.ruleId {
        case "FLARE_RULE": return .painRed
        case "LOW_ADHERENCE_RULE": return .painAmber
        case "OVERDOING_RULE_DER": return .derOrange
        case "FEAR_STUCK_RULE": return .farBlue
        default: return .textSecondary
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: ruleIcon)
                .font(.appCaption)
                .foregroundStyle(ruleColor)
                .frame(width: 28, height: 28)
                .background(ruleColor.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(ruleDisplayName)
                        .font(.appSubheadlineMedium)
                        .foregroundStyle(.textPrimary)

                    if adjustment.applied {
                        Text(appLanguage == "en" ? "Applied" : "Angewandt")
                            .font(.appCaption2)
                            .foregroundStyle(.painGreen)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.painGreen.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.badgeRadius, style: .continuous))
                    }
                }

                Text(adjustment.action ?? "")
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .cardStyle(padding: 12)
    }
}
