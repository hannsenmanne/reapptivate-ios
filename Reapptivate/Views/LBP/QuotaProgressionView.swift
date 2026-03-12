import SwiftUI

struct QuotaProgressionView: View {
    @Bindable var viewModel: LbpEnhancementsViewModel
    @AppStorage("appLanguage") private var appLanguage = "de"
    @State private var isApplying = false

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.appTitle3)
                    .foregroundStyle(.painGreen)
                Text(appLanguage == "en" ? "Quota Progression" : "Quoten-Steigerung")
                    .font(.appHeadline)
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
                        Text(appLanguage == "en" ? "Check progression" : "Steigerung prufen")
                    }
                    .font(.appSubheadlineMedium)
                    .foregroundStyle(.accent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(Color.accent.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.buttonRadius, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: DesignTokens.buttonRadius, style: .continuous).stroke(Color.gray200, lineWidth: 1))
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
                Text(appLanguage == "en" ? "Progression recommended!" : "Steigerung empfohlen!")
                    .font(.appSubheadlineSemibold)
                    .foregroundStyle(.painGreen)
            }

            // Current vs suggested
            if let suggestedQuotas = suggestion.suggestedQuotas {
                VStack(spacing: 8) {
                    ForEach(Array(suggestedQuotas.keys.sorted()), id: \.self) { key in
                        if let current = suggestion.currentQuotas?[key],
                           let suggested = suggestedQuotas[key] {
                            HStack {
                                Text(key)
                                    .font(.appCaption)
                                    .foregroundStyle(.textPrimary)
                                Spacer()
                                Text("\(current)")
                                    .font(.appCaption.monospacedDigit())
                                    .foregroundStyle(.textSecondary)
                                Image(systemName: "arrow.right")
                                    .font(.appCaption2)
                                    .foregroundStyle(.painGreen)
                                Text("\(suggested)")
                                    .font(.appCaptionBold.monospacedDigit())
                                    .foregroundStyle(.painGreen)
                                Text(appLanguage == "en" ? "min" : "Min")
                                    .font(.appCaption2)
                                    .foregroundStyle(.textSecondary)
                            }
                        }
                    }
                }
                .padding(12)
                .background(Color.appBg)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.smallRadius, style: .continuous))
            }

            if let increment = suggestion.incrementPercent {
                Text(appLanguage == "en" ? "+\(increment)% increase" : "+\(increment)% Steigerung")
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
            }

            // Apply button
            Button {
                Task { await apply() }
            } label: {
                Group {
                    if isApplying {
                        ProgressView().tint(.white)
                    } else {
                        Text(appLanguage == "en" ? "Apply progression" : "Steigerung anwenden")
                    }
                }
                .font(.appSubheadlineSemibold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(Color.painGreen)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.buttonRadius, style: .continuous))
            }
            .disabled(isApplying)
        }
        .padding(16)
        .background(Color.painGreen.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cardRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: DesignTokens.cardRadius, style: .continuous).stroke(Color.gray200, lineWidth: 1))
    }

    // MARK: - Not Ready Card

    private func notReadyCard(_ suggestion: QuotaProgressionSuggestion) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "clock")
                    .foregroundStyle(.textSecondary)
                Text(appLanguage == "en" ? "Not ready yet" : "Noch nicht bereit")
                    .font(.appSubheadlineMedium)
                    .foregroundStyle(.textPrimary)
            }

            if let reason = suggestion.reason {
                Text(reason)
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .cardStyle()
    }

    private func apply() async {
        isApplying = true
        _ = await viewModel.applyProgression()
        isApplying = false
    }
}
