import SwiftUI

struct PacingTemplateSelector: View {
    @Bindable var viewModel: LbpEnhancementsViewModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appLanguage") private var appLanguage = "de"
    @State private var isActivating = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header card
                    VStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 36))
                            .foregroundStyle(Color.subtypeColor(for: viewModel.subtype))

                        Text(appLanguage == "en" ? "Your pacing plan is being prepared" : "Ihr Pacing-Plan wird vorbereitet")
                            .font(.appTitle3)
                            .foregroundStyle(.textPrimary)
                            .multilineTextAlignment(.center)

                        Text(appLanguage == "en"
                            ? "Based on your \(viewModel.subtype.displayName) profile"
                            : "Basierend auf Ihrem \(viewModel.subtype.displayName)-Profil")
                            .font(.appSubheadline)
                            .foregroundStyle(.textSecondary)
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            colors: [
                                Color.subtypeColor(for: viewModel.subtype).opacity(0.1),
                                Color.subtypeColor(for: viewModel.subtype).opacity(0.03)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cardRadius, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: DesignTokens.cardRadius, style: .continuous).stroke(Color.gray200, lineWidth: 1))

                    if let template = viewModel.pacingTemplate {
                        // Activities
                        VStack(alignment: .leading, spacing: 12) {
                            Text(appLanguage == "en" ? "Included Activities" : "Enthaltene Aktivitäten")
                                .font(.appSubheadlineMedium)
                                .foregroundStyle(.textPrimary)

                            if let activities = template.targetActivities {
                                ForEach(activities, id: \.key) { activity in
                                    HStack(spacing: 10) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.painGreen)
                                            .font(.appCaption)
                                        Text(activity.label)
                                            .font(.appSubheadline)
                                            .foregroundStyle(.textPrimary)
                                        Spacer()
                                        if let baseline = activity.defaultBaseline {
                                            Text(appLanguage == "en"
                                                ? "\(baseline) min"
                                                : "\(baseline) Min")
                                                .font(.appCaption)
                                                .foregroundStyle(.textSecondary)
                                        }
                                    }
                                }
                            }
                        }
                        .cardStyle()

                        // Rules
                        if let rules = template.rules {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(appLanguage == "en" ? "Rules & Safety Mechanisms" : "Regeln & Sicherheitsmechanismen")
                                    .font(.appSubheadlineMedium)
                                    .foregroundStyle(.textPrimary)

                                if let increment = rules.quotaIncrementPercent {
                                    RuleRow(icon: "chart.line.uptrend.xyaxis", text: appLanguage == "en"
                                        ? "Increase: \(increment)% per week"
                                        : "Steigerung: \(increment)% pro Woche")
                                }
                                if let pause = rules.mandatoryPauseMinutes, pause > 0 {
                                    RuleRow(icon: "pause.circle.fill", text: appLanguage == "en"
                                        ? "Mandatory break: \(pause) min"
                                        : "Obligatorische Pause: \(pause) Min")
                                }
                                if let cap = rules.weeklySessionCap {
                                    RuleRow(icon: "calendar.badge.clock", text: appLanguage == "en"
                                        ? "Max. \(cap) session\(cap == 1 ? "" : "s")/week"
                                        : "Max. \(cap) Einheiten/Woche")
                                }
                            }
                            .cardStyle()
                        }
                    } else {
                        ProgressView(appLanguage == "en" ? "Loading template..." : "Vorlage laden...")
                            .padding()
                    }

                    // Action buttons
                    VStack(spacing: 12) {
                        Button {
                            Task { await activate() }
                        } label: {
                            HStack(spacing: 8) {
                                if isActivating {
                                    ProgressView().tint(.white)
                                } else {
                                    Image(systemName: "sparkles")
                                    Text(appLanguage == "en" ? "Activate plan" : "Plan aktivieren")
                                }
                            }
                            .font(.appBodySemibold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.subtypeColor(for: viewModel.subtype))
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.buttonRadius, style: .continuous))
                        }
                        .disabled(isActivating || viewModel.pacingTemplate == nil)
                    }
                }
                .padding(24)
            }
            .background(Color.appBg)
            .navigationTitle(appLanguage == "en" ? "Pacing Plan" : "Pacing-Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(appLanguage == "en" ? "Cancel" : "Abbrechen") { dismiss() }
                }
            }
            .task {
                await viewModel.loadPacingTemplate()
            }
        }
    }

    private func activate() async {
        isActivating = true
        if await viewModel.activateTemplate() {
            dismiss()
        }
        isActivating = false
    }
}
