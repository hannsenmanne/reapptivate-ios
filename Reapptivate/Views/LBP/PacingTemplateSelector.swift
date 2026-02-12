import SwiftUI

struct PacingTemplateSelector: View {
    @Bindable var viewModel: LbpEnhancementsViewModel
    @Environment(\.dismiss) private var dismiss
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

                        Text("Ihr Pacing-Plan wird vorbereitet")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.textPrimary)
                            .multilineTextAlignment(.center)

                        Text("Basierend auf Ihrem \(viewModel.subtype.displayName)-Profil")
                            .font(.subheadline)
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
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    if let template = viewModel.pacingTemplate {
                        // Activities
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Enthaltene Aktivitaten")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.textPrimary)

                            ForEach(template.targetActivities) { activity in
                                HStack(spacing: 10) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.painGreen)
                                        .font(.caption)
                                    Text(activity.label)
                                        .font(.subheadline)
                                        .foregroundStyle(.textPrimary)
                                    Spacer()
                                    if let baseline = activity.baseline {
                                        Text("\(baseline) \(activity.unit ?? "Min")")
                                            .font(.caption)
                                            .foregroundStyle(.textSecondary)
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .background(Color.cardBg)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        // Rules
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Regeln & Sicherheitsmechanismen")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.textPrimary)

                            if let increment = template.rules.quotaIncrementPercent {
                                RuleRow(icon: "chart.line.uptrend.xyaxis", text: "Steigerung: \(increment)% pro Woche")
                            }
                            if let pause = template.rules.mandatoryPauseMinutes, pause > 0 {
                                RuleRow(icon: "pause.circle.fill", text: "Obligatorische Pause: \(pause) Min")
                            }
                            if let cap = template.rules.weeklySessionCap {
                                RuleRow(icon: "calendar.badge.clock", text: "Max. \(cap) Einheiten/Woche")
                            }
                        }
                        .padding(16)
                        .background(Color.cardBg)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        ProgressView("Vorlage laden...")
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
                                    Text("Plan aktivieren")
                                }
                            }
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.subtypeColor(for: viewModel.subtype))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(isActivating || viewModel.pacingTemplate == nil)
                    }
                }
                .padding(24)
            }
            .background(Color.appBg)
            .navigationTitle("Pacing-Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
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
