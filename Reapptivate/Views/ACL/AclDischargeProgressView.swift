import SwiftUI

struct AclDischargeProgressView: View {
    @Environment(APIClient.self) private var apiClient

    @State private var progress: AclDischargeProgress?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            if isLoading {
                ProgressView("Entlassungsdaten laden...")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
            } else if let error = errorMessage {
                InlineErrorView(
                    message: error,
                    errorType: .network,
                    onRetry: { Task { await loadProgress() } }
                )
            } else if let progress {
                dischargeContent(progress)
            } else {
                EmptyStateView(
                    icon: "target",
                    title: "Noch keine Daten",
                    message: "Entlassungskriterien werden ab Meilenstein 4 angezeigt."
                )
            }
        }
        .padding(.bottom, 32)
        .task {
            await loadProgress()
        }
    }

    @ViewBuilder
    private func dischargeContent(_ progress: AclDischargeProgress) -> some View {
        // Overall progress card
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 10) {
                    Image(systemName: "target")
                        .font(.appTitle3)
                        .foregroundStyle(.textSecondary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Entlassungskriterien")
                            .font(.appHeadline)
                            .foregroundStyle(.textPrimary)
                        Text("Fortschritt zur Return-to-Sport Freigabe")
                            .font(.appCaption)
                            .foregroundStyle(.textSecondary)
                    }
                }

                Spacer()

                Text("\(progress.overallPercent)%")
                    .font(.appTitle2)
                    .foregroundStyle(overallColor(for: progress.overallPercent))
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: DesignTokens.progressBarRadius)
                        .fill(Color.textSecondary.opacity(0.15))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: DesignTokens.progressBarRadius)
                        .fill(overallColor(for: progress.overallPercent))
                        .frame(
                            width: geo.size.width * CGFloat(min(100, progress.overallPercent)) / 100,
                            height: 6
                        )
                }
            }
            .frame(height: 6)

            if progress.metCount == progress.totalCount && progress.totalCount > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.painGreen)
                    Text("Alle Kriterien erfüllt -- Entlassung möglich")
                        .font(.appSubheadlineMedium)
                        .foregroundStyle(.painGreen)
                }
                .padding(.top, 4)
            } else {
                Text("\(progress.metCount) von \(progress.totalCount) Kriterien erfüllt")
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
            }
        }
        .cardStyle()
        .cardEntryAnimation(index: 0)

        // Criteria list
        ForEach(Array(progress.criteria.enumerated()), id: \.element.id) { index, criterion in
            DischargeCriterionCard(criterion: criterion)
                .cardEntryAnimation(index: index + 1)
        }
    }

    private func overallColor(for percent: Int) -> Color {
        if percent >= 85 { return .painGreen }
        if percent >= 70 { return .painAmber }
        return .painRed
    }

    private func loadProgress() async {
        isLoading = true
        errorMessage = nil

        do {
            let result: AclDischargeProgress = try await apiClient.request(
                APIEndpoints.aclDischargeProgress()
            )
            progress = result
        } catch {
            errorMessage = "Entlassungsdaten konnten nicht geladen werden."
        }

        isLoading = false
    }
}

// MARK: - Discharge Criterion Card

struct DischargeCriterionCard: View {
    let criterion: AclDischargeCriterion

    private var isMet: Bool { criterion.met == true }

    private var progressPercent: Double {
        if isMet { return 1.0 }
        guard let current = criterion.currentValue, let threshold = criterion.threshold else {
            return 0
        }
        // For "<=" operators, lower values are better (e.g., extension deficit <= 0)
        if criterion.operator == "<=" {
            if current <= threshold { return 1.0 }
            if threshold <= 0 {
                // Target is 0 or below: scale progress inversely with current value
                return max(0, 1.0 - (current - threshold) / max(1, abs(current)))
            }
            return min(1.0, threshold / current)
        }
        // For ">=" operators (default), higher values are better
        guard threshold > 0 else { return 0 }
        return min(1.0, current / threshold)
    }

    private var criterionColor: Color {
        if isMet { return .painGreen }
        let pct = progressPercent * 100
        if pct >= 70 { return .painAmber }
        return .painRed
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                    .font(.appSubheadline)
                    .foregroundStyle(isMet ? .painGreen : .textSecondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(criterion.test ?? criterion.category ?? criterion.id)
                        .font(.appSubheadlineMedium)
                        .foregroundStyle(isMet ? .textSecondary : .textPrimary)

                    if let category = criterion.category, criterion.test != nil {
                        Text(category)
                            .font(.appCaption2)
                            .foregroundStyle(.textTertiary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    if let current = criterion.currentValue {
                        Text(String(format: "%.0f", current))
                            .font(.appSubheadlineSemibold)
                            .foregroundStyle(criterionColor)
                    } else {
                        Text("--")
                            .font(.appSubheadlineMedium)
                            .foregroundStyle(.textTertiary)
                    }

                    if let threshold = criterion.threshold {
                        Text("/ \(String(format: "%.0f", threshold))\(criterion.unit ?? "")")
                            .font(.appCaption2)
                            .foregroundStyle(.textSecondary)
                    }
                }
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: DesignTokens.progressBarRadius)
                        .fill(Color.textSecondary.opacity(0.15))
                        .frame(height: 4)
                    RoundedRectangle(cornerRadius: DesignTokens.progressBarRadius)
                        .fill(criterionColor)
                        .frame(width: geo.size.width * progressPercent, height: 4)
                }
            }
            .frame(height: 4)
        }
        .cardStyle()
    }
}
