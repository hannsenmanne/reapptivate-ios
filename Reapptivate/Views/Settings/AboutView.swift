import SwiftUI

struct AboutView: View {
    @AppStorage("appLanguage") private var appLanguage = "de"

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        let isEn = appLanguage == "en"

        ScrollView {
            VStack(spacing: 20) {
                // Brand
                VStack(spacing: 12) {
                    Circle()
                        .fill(Color.accent.opacity(0.12))
                        .frame(width: 80, height: 80)
                        .overlay {
                            Image(systemName: "figure.strengthtraining.traditional")
                                .font(.system(size: 32))
                                .foregroundStyle(.accent)
                        }

                    Text(brandWordmark)
                        .font(.outfit(.bold, size: 24))

                    Text("Version \(appVersion) (\(buildNumber))")
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                }
                .padding(.top, 8)

                // Description
                VStack(alignment: .leading, spacing: 8) {
                    Text(isEn ? "About the App" : "Über die App")
                        .font(.appHeadline)
                        .foregroundStyle(.textPrimary)

                    Text(isEn
                        ? "Reapptivate is an evidence-based physiotherapy app that provides individualized training programs for various musculoskeletal conditions. The app adapts to your progress and pain level."
                        : "Reapptivate ist eine evidenzbasierte Physiotherapie-App, die individuelle Trainingsprogramme für verschiedene muskuloskelettale Beschwerden bietet. Die App passt sich adaptiv an Ihren Fortschritt und Schmerzlevel an.")
                        .font(.appSubheadline)
                        .foregroundStyle(.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle()

                // Credits
                VStack(alignment: .leading, spacing: 8) {
                    Text(isEn ? "Development" : "Entwicklung")
                        .font(.appHeadline)
                        .foregroundStyle(.textPrimary)

                    CreditRow(icon: "person.fill", label: isEn ? "Concept & Development" : "Konzept & Entwicklung", value: "Marc Toschew")
                    CreditRow(icon: "stethoscope", label: isEn ? "Clinical Advisor" : "Fachliche Beratung", value: isEn ? "Physiotherapy Team" : "Physiotherapie-Team")
                    CreditRow(icon: "graduationcap.fill", label: isEn ? "Evidence Base" : "Evidenzbasis", value: isEn ? "Current Guidelines" : "Aktuelle Leitlinien")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle()

                // Technology
                VStack(alignment: .leading, spacing: 8) {
                    Text(isEn ? "Technology" : "Technologie")
                        .font(.appHeadline)
                        .foregroundStyle(.textPrimary)

                    TechRow(label: "Platform", value: "iOS 17+")
                    TechRow(label: "Framework", value: "SwiftUI")
                    TechRow(label: isEn ? "Language" : "Sprache", value: "Swift 6.0")
                    TechRow(label: isEn ? "Architecture" : "Architektur", value: "MVVM + @Observable")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle()
            }
            .padding(16)
        }
        .background(Color.appBg)
        .navigationTitle(isEn ? "About the App" : "Über die App")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var brandWordmark: AttributedString {
        var re = AttributedString("re")
        re.foregroundColor = UIColor(.textPrimary)
        var app = AttributedString("app")
        app.foregroundColor = UIColor(.accent)
        var tivate = AttributedString("tivate")
        tivate.foregroundColor = UIColor(.textPrimary)
        return re + app + tivate
    }
}

private struct CreditRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.appCaption)
                .foregroundStyle(.accent)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
                Text(value)
                    .font(.appSubheadlineMedium)
                    .foregroundStyle(.textPrimary)
            }
        }
    }
}

private struct TechRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.appSubheadline)
                .foregroundStyle(.textSecondary)
            Spacer()
            Text(value)
                .font(.appSubheadlineMedium)
                .foregroundStyle(.textPrimary)
        }
    }
}
