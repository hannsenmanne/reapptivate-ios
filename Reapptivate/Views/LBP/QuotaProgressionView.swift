import SwiftUI

struct QuotaProgressionView: View {
    @Bindable var viewModel: LbpEnhancementsViewModel
    @State private var isApplying = false

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title3)
                    .foregroundStyle(.painGreen)
                Text("Quoten-Steigerung")
                    .font(.headline)
                    .foregroundStyle(.textPrimary)
                Spacer()
            }

            if let suggestion = viewModel.quotaSuggestion {
                if suggestion.ready {
                    readyCard(suggestion)
                } else {
                    notReadyCard(suggestion)
                }
            } else {
                Button {
                    Task { await viewModel.loadQuotaSuggestion() }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Steigerung prufen")
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.accent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(Color.accent.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }

    // MARK: - Ready Card

    private func readyCard(_ suggestion: QuotaProgressionSuggestion) -> some View {
        VStack(spacing: 16) {
            // Status
            HStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.painGreen)
                Text("Steigerung empfohlen!")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.painGreen)
            }

            // Current vs suggested
            VStack(spacing: 8) {
                ForEach(Array(suggestion.suggestedQuotas.keys.sorted()), id: \.self) { key in
                    if let current = suggestion.currentQuotas[key],
                       let suggested = suggestion.suggestedQuotas[key] {
                        HStack {
                            Text(key)
                                .font(.caption)
                                .foregroundStyle(.textPrimary)
                            Spacer()
                            Text("\(current)")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.textSecondary)
                            Image(systemName: "arrow.right")
                                .font(.caption2)
                                .foregroundStyle(.painGreen)
                            Text("\(suggested)")
                                .font(.caption.weight(.bold).monospacedDigit())
                                .foregroundStyle(.painGreen)
                            Text("Min")
                                .font(.caption2)
                                .foregroundStyle(.textSecondary)
                        }
                    }
                }
            }
            .padding(12)
            .background(Color.appBg)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Text("+\(suggestion.incrementPercent)% Steigerung")
                .font(.caption)
                .foregroundStyle(.textSecondary)

            // Apply button
            Button {
                Task { await apply() }
            } label: {
                Group {
                    if isApplying {
                        ProgressView().tint(.white)
                    } else {
                        Text("Steigerung anwenden")
                    }
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(Color.painGreen)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .disabled(isApplying)
        }
        .padding(16)
        .background(Color.painGreen.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Not Ready Card

    private func notReadyCard(_ suggestion: QuotaProgressionSuggestion) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "clock")
                    .foregroundStyle(.textSecondary)
                Text("Noch nicht bereit")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.textPrimary)
            }

            Text(suggestion.reason)
                .font(.caption)
                .foregroundStyle(.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func apply() async {
        isApplying = true
        _ = await viewModel.applyProgression()
        isApplying = false
    }
}
