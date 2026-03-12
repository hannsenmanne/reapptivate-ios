import SwiftUI

struct LasResultView: View {
    @AppStorage("appLanguage") private var appLanguage = "de"
    let result: LasScreeningResult
    let onContinue: () -> Void

    var severity: LasSeverityGrade {
        result.severityGrade
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
                            Text("\(result.caitScore)")
                                .font(.appTitle)
                                .foregroundStyle(.white)
                        }

                    Text("CAIT-Score: \(result.caitScore)/30")
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
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle()

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
            return isEn ? "Good ankle stability (CAIT \u{2265}24). Your program starts directly in Phase 2 with early mobilization and strengthening." : "Gute Sprunggelenksstabilität (CAIT \u{2265}24). Ihr Programm startet direkt in Phase 2 mit früher Mobilisation und Kräftigung."
        case .MITTEL:
            return isEn ? "Moderate instability (CAIT 12-23). Your program begins in Phase 1 with protection, reduction of swelling, and pain-free mobilization." : "Mäßige Instabilität (CAIT 12-23). Ihr Programm beginnt in Phase 1 mit Schutz, Entstauung und schmerzfreier Mobilisation."
        case .SCHWER, .unknown:
            return isEn ? "Chronic instability (CAIT \u{2264}11). Your program starts very gently in Phase 1 following the PEACE & LOVE protocol." : "Chronische Instabilität (CAIT \u{2264}11). Ihr Programm beginnt sehr sanft in Phase 1 nach dem PEACE & LOVE-Protokoll."
        }
    }
}
