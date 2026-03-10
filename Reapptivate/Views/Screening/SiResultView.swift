import SwiftUI

struct SiResultView: View {
    let result: SiScreeningResult
    let onContinue: () -> Void

    var severity: SiSeverityGrade {
        result.severityGrade
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Score display
                VStack(spacing: 12) {
                    Circle()
                        .fill(Color.severityColor(for: severity))
                        .frame(width: 72, height: 72)
                        .overlay {
                            Text("\(Int(result.quickDashScore))")
                                .font(.appTitle)
                                .foregroundStyle(.white)
                        }

                    Text("QuickDASH: \(Int(result.quickDashScore))%")
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
                    Text("Ihre Einstufung")
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
                    Text("Weiter zum Dashboard")
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
        switch severity {
        case .LEICHT:
            "Leichte Einschränkung. Ihr Programm startet in Phase 2 mit aktivem Kraftaufbau und neuromuskulärer Kontrolle."
        case .MITTEL:
            "Moderate Einschränkung. Ihr Programm beginnt in Phase 1 mit sanfter Mobilisation und Schmerzlinderung."
        case .SCHWER, .unknown:
            "Deutliche Einschränkung. Ihr Programm beginnt sanft in Phase 1 mit reduzierter Belastung und verlängerten Erholungsphasen."
        }
    }
}
