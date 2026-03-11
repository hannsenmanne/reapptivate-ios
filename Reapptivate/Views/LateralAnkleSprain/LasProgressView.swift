import SwiftUI

struct LasProgressView: View {
    @Environment(APIClient.self) private var apiClient
    @State private var history: [LasHistoryEntry] = []
    @State private var isLoading = true
    @State private var showRescreening = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "chart.xyaxis.line")
                    .font(.appTitle3)
                    .foregroundStyle(.accent)
                    .accessibilityHidden(true)
                Text("CAIT-Verlauf")
                    .font(.appHeadline)
                    .foregroundStyle(.textPrimary)
                Spacer()
            }

            if isLoading {
                ProgressView("CAIT-Verlauf laden...")
                    .padding(.vertical, 16)
            } else if let error = errorMessage {
                InlineErrorView(
                    message: error,
                    errorType: .network,
                    onRetry: {
                        Task { await loadHistory() }
                    }
                )
            } else if history.isEmpty {
                Text("Noch keine Screening-Daten")
                    .font(.appSubheadline)
                    .foregroundStyle(.textSecondary)
                    .padding(.vertical, 16)
            } else {
                // Score sparkline
                if history.count > 1 {
                    LasSparkline(entries: history)
                        .frame(height: 80)
                        .padding(.horizontal, 4)
                }

                // History entries
                ForEach(history) { entry in
                    LasHistoryRow(entry: entry)
                }

                // Rescreening button
                Button {
                    showRescreening = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Rescreening durchführen")
                    }
                    .font(.appSubheadlineMedium)
                    .foregroundStyle(.accent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(Color.accent.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.buttonRadius, style: .continuous))
                }
                .sheet(isPresented: $showRescreening, onDismiss: {
                    Task { await loadHistory() }
                }) {
                    LasScreeningView(isRescreening: true)
                }
            }
        }
        .cardStyle()
        .task {
            await loadHistory()
        }
    }

    private func loadHistory() async {
        isLoading = true
        errorMessage = nil
        do {
            let response: LasHistoryResponse = try await apiClient.request(APIEndpoints.lasHistory())
            history = response.history
        } catch {
            errorMessage = "CAIT-Verlauf konnte nicht geladen werden."
        }
        isLoading = false
    }
}

// MARK: - LAS History Row

private struct LasHistoryRow: View {
    let entry: LasHistoryEntry
    @ScaledMetric(relativeTo: .caption) private var scoreCircleSize: CGFloat = 32

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(entry.severityGrade.map { Color.severityColor(for: $0) } ?? Color.arGray)
                .frame(width: scoreCircleSize, height: scoreCircleSize)
                .overlay {
                    Text("\(entry.caitScore)")
                        .font(.appCaptionBold)
                        .foregroundStyle(.white)
                }
                .accessibilityLabel("CAIT-Score \(entry.caitScore)")

            VStack(alignment: .leading, spacing: 2) {
                Text("CAIT: \(entry.caitScore)/30")
                    .font(.appSubheadlineMedium)
                    .foregroundStyle(.textPrimary)
                Text(entry.severityLabel ?? "")
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
            }

            Spacer()

            if let date = entry.createdAtDate {
                Text(date.formattedGerman)
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
            }
        }
        .padding(10)
        .background(Color.appBg)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.smallRadius, style: .continuous))
    }
}

// MARK: - LAS Sparkline

struct LasSparkline: View {
    let entries: [LasHistoryEntry]

    private var scores: [Double] {
        entries.reversed().map { Double($0.caitScore) }
    }

    private var severities: [LasSeverityGrade] {
        entries.reversed().map { $0.severityGrade ?? LasSeverityGrade.from(caitScore: $0.caitScore) }
    }

    private func xPos(_ index: Int, width: CGFloat) -> CGFloat {
        scores.count > 1 ? CGFloat(index) * width / CGFloat(scores.count - 1) : width / 2
    }

    private func yPos(_ score: Double, height: CGFloat, padding: CGFloat = 6) -> CGFloat {
        // Higher CAIT score = better = higher on chart (lower y position)
        padding + (height - 2 * padding) * (1 - score / 30.0)
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            Path { path in
                guard scores.count > 1 else { return }
                for (index, score) in scores.enumerated() {
                    let point = CGPoint(x: xPos(index, width: w), y: yPos(score, height: h))
                    if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
                }
            }
            .stroke(Color.accent, lineWidth: 2.5)

            ForEach(Array(scores.enumerated()), id: \.offset) { index, score in
                Circle()
                    .fill(Color.severityColor(for: severities[index]))
                    .frame(width: 8, height: 8)
                    .position(x: xPos(index, width: w), y: yPos(score, height: h))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("CAIT-Verlaufsdiagramm")
    }
}
