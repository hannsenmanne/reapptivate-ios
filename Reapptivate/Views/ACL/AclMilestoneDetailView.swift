import SwiftUI

struct AclMilestoneDetailView: View {
    @Environment(APIClient.self) private var apiClient

    let milestone: Int

    @State private var milestoneStatus: AclMilestoneStatus?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if isLoading {
                    ProgressView("Meilenstein-Daten laden...")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                } else if let error = errorMessage {
                    InlineErrorView(
                        message: error,
                        errorType: .network,
                        onRetry: { Task { await loadData() } }
                    )
                } else if let status = milestoneStatus {
                    milestoneContent(status: status)
                }
            }
            .padding(16)
        }
        .background(Color.appBg)
        .navigationTitle("Meilenstein \(milestone)")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadData()
        }
    }

    @ViewBuilder
    private func milestoneContent(status: AclMilestoneStatus) -> some View {
        // Status summary
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Aktueller Meilenstein")
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
                Spacer()
                Text("M\(status.currentMilestone)")
                    .font(.appHeadline)
                    .foregroundStyle(.accent)
            }

            HStack {
                Text("Wochen post-OP")
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
                Spacer()
                Text("\(status.weeksPostSurgery)")
                    .font(.appSubheadlineSemibold)
                    .foregroundStyle(.textPrimary)
            }

            if status.isReadyForLab == true {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.farBlue)
                    Text("Bereit für Lab-Assessment")
                        .font(.appSubheadlineMedium)
                        .foregroundStyle(.farBlue)
                }
                .padding(.top, 4)
            }
        }
        .cardStyle()

        // Criteria list
        if let criteria = status.nextCriteria, !criteria.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Kriterien für nächsten Meilenstein")
                    .font(.appHeadline)
                    .foregroundStyle(.textPrimary)

                ForEach(criteria) { criterion in
                    AclCriterionRow(criterion: criterion)
                }
            }
            .cardStyle()
        }
    }

    private func loadData() async {
        isLoading = true
        errorMessage = nil

        do {
            let status: AclMilestoneStatus = try await apiClient.request(
                APIEndpoints.aclMilestoneStatus()
            )
            milestoneStatus = status
        } catch {
            errorMessage = "Meilenstein-Daten konnten nicht geladen werden."
        }

        isLoading = false
    }
}

// MARK: - Criterion Row

struct AclCriterionRow: View {
    let criterion: AclMilestoneCriterion

    private var isMet: Bool { criterion.met == true }

    private var progressPercent: Double {
        guard let current = criterion.currentValue, let threshold = criterion.threshold, threshold > 0 else {
            return 0
        }
        return min(1.0, current / threshold)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: isMet ? "checkmark.circle.fill" : "xmark.circle")
                    .font(.appSubheadline)
                    .foregroundStyle(isMet ? .painGreen : .painRed)

                Text(criterion.labelDE ?? criterion.label ?? criterion.id)
                    .font(.appSubheadlineMedium)
                    .foregroundStyle(.textPrimary)

                Spacer()

                if let current = criterion.currentValue {
                    HStack(spacing: 2) {
                        Text(String(format: "%.0f", current))
                            .font(.appSubheadlineSemibold)
                            .foregroundStyle(isMet ? .painGreen : .textPrimary)

                        if let threshold = criterion.threshold {
                            Text("/ \(String(format: "%.0f", threshold))\(criterion.unit ?? "")")
                                .font(.appCaption)
                                .foregroundStyle(.textSecondary)
                        }
                    }
                } else {
                    Text("--")
                        .font(.appSubheadlineMedium)
                        .foregroundStyle(.textTertiary)
                }
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: DesignTokens.progressBarRadius)
                        .fill(Color.textSecondary.opacity(0.15))
                        .frame(height: 4)
                    RoundedRectangle(cornerRadius: DesignTokens.progressBarRadius)
                        .fill(isMet ? Color.painGreen : Color.accent)
                        .frame(width: geo.size.width * progressPercent, height: 4)
                }
            }
            .frame(height: 4)
        }
        .padding(.vertical, 4)
    }
}
