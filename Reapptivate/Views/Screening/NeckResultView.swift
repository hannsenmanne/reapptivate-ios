import SwiftUI

struct NeckResultView: View {
    @AppStorage("appLanguage") private var appLanguage = "de"
    let result: NeckScreeningResult
    let onContinue: () -> Void

    var severity: NdiSeverityGrade {
        NdiSeverityGrade.from(ndiScore: result.ndiScore)
    }

    var body: some View {
        let isEn = appLanguage == "en"

        ScrollView {
            VStack(spacing: 24) {
                // Score display
                VStack(spacing: 12) {
                    Circle()
                        .fill(Color.severityColor(for: severity))
                        .frame(width: 72, height: 72)
                        .overlay {
                            Text("\(result.ndiScore)")
                                .font(.appTitle)
                                .foregroundStyle(.white)
                        }

                    Text("NDI-Score: \(result.ndiScore)/50")
                        .font(.appTitle3)
                        .foregroundStyle(.textPrimary)

                    Text(severity.displayName)
                        .font(.appHeadline)
                        .foregroundStyle(Color.severityColor(for: severity))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color.severityColor(for: severity).opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.badgeRadius, style: .continuous))
                }
                .padding(.top, 32)

                // Severity description
                VStack(alignment: .leading, spacing: 12) {
                    Text(isEn ? "Your Classification" : "Ihre Einstufung")
                        .font(.appHeadline)
                        .foregroundStyle(.textPrimary)

                    Text(severityDescription)
                        .font(.appBody)
                        .foregroundStyle(.textSecondary)

                    Text(result.ndiCategory)
                        .font(.appSubheadlineMedium)
                        .foregroundStyle(.textPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle()

                // Subtype result
                if result.subtype == "NECK_RADICULOPATHY" {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundStyle(.painAmber)
                        Text(isEn ? "Radiculopathy detected. Your exercise program has been adjusted accordingly." : "Radiculopathie erkannt. Ihr Übungsprogramm ist entsprechend angepasst.")
                            .font(.appSubheadline)
                            .foregroundStyle(.textPrimary)
                    }
                    .infoBoxStyle(color: .painAmber)
                }

                // Continue button
                Button {
                    onContinue()
                } label: {
                    Text(isEn ? "Continue to Dashboard" : "Weiter zum Dashboard")
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                }
                .buttonStyle(.accentFilled)
            }
            .padding(24)
        }
        .background(Color.appBg)
    }

    var severityDescription: String {
        let isEn = appLanguage == "en"
        switch severity {
        case .LEICHT:
            return isEn ? "Mild limitation. Your program follows the standard exercise progression with all intensity levels." : "Leichte Einschränkung. Ihr Programm folgt der Standard-Übungsprogression mit allen Intensitätsstufen."
        case .MITTEL:
            return isEn ? "Moderate limitation. Your program includes adapted exercises with slower progression." : "Moderate Einschränkung. Ihr Programm enthält angepasste Übungen mit langsamerer Steigerung."
        case .SCHWER, .unknown:
            return isEn ? "Significant limitation. Your program starts gently with extended phases and reduced load." : "Deutliche Einschränkung. Ihr Programm beginnt sanft mit verlängerten Phasen und reduzierter Belastung."
        }
    }
}
