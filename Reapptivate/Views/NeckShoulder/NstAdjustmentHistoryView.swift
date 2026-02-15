import SwiftUI

struct NstAdjustmentHistoryView: View {
    @Environment(APIClient.self) private var apiClient

    @State private var adjustments: [NstPlanAdjustment] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    let accentColor: Color

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "arrow.triangle.branch")
                    .font(.appTitle3)
                    .foregroundStyle(.painAmber)
                Text("Plan-Anpassungen")
                    .font(.appHeadline)
                    .foregroundStyle(.textPrimary)
                Spacer()
            }

            if isLoading {
                ProgressView("Verlauf laden...")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            } else if let error = errorMessage {
                InlineErrorView(message: error) {
                    Task { await loadAdjustments() }
                }
            } else if adjustments.isEmpty {
                VStack(spacing: 8) {
                    Text("Keine Anpassungen")
                        .font(.appSubheadline)
                        .foregroundStyle(.textSecondary)
                    Text("Automatische Anpassungen werden hier angezeigt, wenn Trigger-Regeln aktiviert werden.")
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 16)
            } else {
                ForEach(adjustments) { adjustment in
                    NstAdjustmentRow(adjustment: adjustment)
                }
            }
        }
        .task {
            await loadAdjustments()
        }
    }

    private func loadAdjustments() async {
        isLoading = true
        errorMessage = nil
        do {
            let response: NstAdjustmentsResponse = try await apiClient.request(APIEndpoints.nstAdjustments())
            adjustments = response.adjustments
        } catch {
            errorMessage = "Anpassungen konnten nicht geladen werden."
        }
        isLoading = false
    }
}

// MARK: - Adjustment Row

private struct NstAdjustmentRow: View {
    let adjustment: NstPlanAdjustment

    var ruleDisplayName: String {
        switch adjustment.ruleId {
        case "NST_PAIN_SPIKE_RULE": return "Schmerz-Schub"
        case "NST_LOW_COMPLIANCE_RULE": return "Niedrige Adhärenz"
        case "NST_OVERTRAINING_RULE": return "Überbelastung"
        case "NST_HIGH_STRESS_RULE": return "Hoher Stress"
        default: return adjustment.ruleId
        }
    }

    var ruleIcon: String {
        switch adjustment.ruleId {
        case "NST_PAIN_SPIKE_RULE": return "flame.fill"
        case "NST_LOW_COMPLIANCE_RULE": return "arrow.down.circle"
        case "NST_OVERTRAINING_RULE": return "exclamationmark.triangle.fill"
        case "NST_HIGH_STRESS_RULE": return "brain.head.profile"
        default: return "gear"
        }
    }

    var ruleColor: Color {
        switch adjustment.ruleId {
        case "NST_PAIN_SPIKE_RULE": return .painRed
        case "NST_LOW_COMPLIANCE_RULE": return .painAmber
        case "NST_OVERTRAINING_RULE": return .painRed
        case "NST_HIGH_STRESS_RULE": return .painAmber
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
                        Text("Angewandt")
                            .font(.appCaption2)
                            .foregroundStyle(.painGreen)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.painGreen.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.badgeRadius, style: .continuous))
                    }
                }

                Text(adjustment.action)
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .cardStyle(padding: 12)
    }
}
