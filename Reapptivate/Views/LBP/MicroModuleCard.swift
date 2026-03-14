import SwiftUI

struct MicroModuleCard: View {
    let module: MicroModule
    let isCompleted: Bool
    let isMarking: Bool
    let onMarkRead: () -> Void

    @AppStorage("appLanguage") private var appLanguage = "de"
    @State private var isExpanded = false

    var moduleIcon: String {
        let key = module.key.lowercased()
        if key.contains("expectation") || key.contains("experiment") { return "magnifyingglass" }
        if key.contains("pacing") || key.contains("dosier") { return "timer" }
        if key.contains("distress") || key.contains("regulat") { return "brain.head.profile" }
        if key.contains("fear") || key.contains("angst") { return "eye" }
        if key.contains("pain") || key.contains("schmerz") { return "waveform.path.ecg" }
        return "book.fill"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: moduleIcon)
                        .font(.appSubheadline)
                        .foregroundStyle(.farBlue)
                        .frame(width: 32, height: 32)
                        .background(Color.farBlue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.iconRadius, style: .continuous))

                    Text(module.title)
                        .font(.appSubheadlineMedium)
                        .foregroundStyle(.textPrimary)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    if isCompleted {
                        Text(appLanguage == "en" ? "Completed" : "Abgeschlossen")
                            .font(.appCaption2)
                            .foregroundStyle(.painGreen)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.painGreen.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.badgeRadius, style: .continuous))
                    }

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                }
                .padding(14)
            }
            .buttonStyle(.plain)

            // Expanded content
            if isExpanded {
                Divider()
                    .padding(.horizontal, 14)

                VStack(alignment: .leading, spacing: 16) {
                    // Body text
                    MarkdownContentView(module.content, font: .appSubheadline)

                    // Take-home message
                    if let takeHome = module.takeHome, !takeHome.isEmpty {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(.painAmber)
                                .font(.appSubheadline)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(appLanguage == "en" ? "Key takeaway" : "Kernbotschaft")
                                    .font(.appCaptionBold)
                                    .foregroundStyle(.textPrimary)
                                Text(takeHome)
                                    .font(.appCaption)
                                    .foregroundStyle(.textSecondary)
                            }
                        }
                        .infoBoxStyle(color: .painAmber)
                    }

                    // Mark as read button
                    if !isCompleted {
                        Button {
                            onMarkRead()
                        } label: {
                            HStack(spacing: 6) {
                                if isMarking {
                                    ProgressView(appLanguage == "en" ? "Loading module..." : "Modul laden...")
                                        .controlSize(.small)
                                        .tint(.white)
                                } else {
                                    Image(systemName: "checkmark")
                                    Text(appLanguage == "en" ? "Read" : "Gelesen")
                                }
                            }
                            .font(.appSubheadlineMedium)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(Color.painGreen)
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.buttonRadius, style: .continuous))
                        }
                        .disabled(isMarking)
                    }
                }
                .padding(14)
            }
        }
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cardRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: DesignTokens.cardRadius, style: .continuous).stroke(Color.gray200, lineWidth: 1))
    }
}
