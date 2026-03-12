import SwiftUI

struct TensionProfileView: View {
    let severity: TsiSeverityGrade
    @AppStorage("appLanguage") private var appLanguage = "de"

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Severity badge
                Circle()
                    .fill(Color.severityColor(for: severity))
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image(systemName: severityIcon)
                            .font(.appTitle3)
                            .foregroundStyle(.white)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text(appLanguage == "en" ? "TSI Severity" : "TSI-Schweregrad")
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                    Text(severity.displayName)
                        .font(.appHeadline)
                        .foregroundStyle(Color.severityColor(for: severity))
                }

                Spacer()

                // Severity pill
                Text(severity.displayName)
                    .font(.outfit(.medium, size: 11))
                    .foregroundStyle(Color.severityColor(for: severity))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.severityColor(for: severity).opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.badgeRadius, style: .continuous))
            }

            // Description
            Text(severityDescription)
                .font(.appCaption)
                .foregroundStyle(.textSecondary)
        }
        .cardStyle()
    }

    var severityIcon: String {
        switch severity {
        case .LEICHT: return "checkmark.circle"
        case .MITTEL: return "exclamationmark.circle"
        case .SCHWER, .unknown: return "exclamationmark.triangle"
        }
    }

    var severityDescription: String {
        switch severity {
        case .LEICHT:
            appLanguage == "en"
                ? "Mild tension. Standard exercise progression with all intensity levels."
                : "Leichte Verspannung. Standard-Übungsprogression mit allen Intensitätsstufen."
        case .MITTEL:
            appLanguage == "en"
                ? "Moderate tension. Adapted exercises with slower progression."
                : "Moderate Verspannung. Angepasste Übungen mit langsamerer Steigerung."
        case .SCHWER, .unknown:
            appLanguage == "en"
                ? "Significant tension. Gentle start with extended phases and reduced load."
                : "Deutliche Verspannung. Sanfter Beginn mit verlängerten Phasen und reduzierter Belastung."
        }
    }
}
