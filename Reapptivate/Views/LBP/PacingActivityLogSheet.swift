import SwiftUI

struct PacingActivityLogSheet: View {
    @Bindable var viewModel: LbpEnhancementsViewModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appLanguage") private var appLanguage = "de"

    @State private var selectedActivityKey: String?
    @State private var doneQuota: Int = 0
    @State private var donePauses: Int = 0
    @State private var notes: String = ""
    @State private var isSubmitting = false
    @State private var showSuccess = false

    var selectedActivity: TargetActivity? {
        viewModel.pacingPlan?.targetActivities.first { $0.key == selectedActivityKey }
    }

    var compliancePercentage: Double {
        guard let quota = selectedActivity?.quota, quota > 0 else { return 0 }
        return Double(doneQuota) / Double(quota) * 100
    }

    var complianceColor: Color {
        if compliancePercentage <= 90 { return .painGreen }
        if compliancePercentage <= 110 { return .farBlue }
        return .painAmber
    }

    var complianceLabel: String {
        if compliancePercentage <= 90 { return appLanguage == "en" ? "Well dosed" : "Gut dosiert" }
        if compliancePercentage <= 110 { return appLanguage == "en" ? "On target" : "Im Zielbereich" }
        return appLanguage == "en" ? "Over quota" : "Über der Quote"
    }

    private var hasUnsavedChanges: Bool {
        selectedActivityKey != nil || !notes.isEmpty
    }

    var body: some View {
        NavigationStack {
            if showSuccess {
                successView
            } else {
                formView
            }
        }
        .interactiveDismissDisabled(hasUnsavedChanges)
    }

    // MARK: - Form View

    private var formView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Activity selection
                VStack(alignment: .leading, spacing: 8) {
                    Text(appLanguage == "en" ? "Which activity did you do?" : "Welche Aktivität haben Sie gemacht?")
                        .font(.appSubheadlineMedium)
                        .foregroundStyle(.textPrimary)

                    if let activities = viewModel.pacingPlan?.targetActivities {
                        ForEach(activities) { activity in
                            Button {
                                selectedActivityKey = activity.key
                                if let quota = activity.quota {
                                    doneQuota = quota
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: selectedActivityKey == activity.key ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(selectedActivityKey == activity.key ? .accent : .textSecondary)

                                    Text(activity.label)
                                        .font(.appSubheadline)
                                        .foregroundStyle(.textPrimary)

                                    Spacer()

                                    if let quota = activity.quota {
                                        Text(appLanguage == "en"
                                            ? "Target: \(quota) \(activity.unit ?? "min")"
                                            : "Ziel: \(quota) \(activity.unit ?? "Min")")
                                            .font(.appCaption)
                                            .foregroundStyle(.textSecondary)
                                    }
                                }
                                .padding(12)
                                .background(selectedActivityKey == activity.key ? Color.accent.opacity(0.06) : Color.cardBg)
                                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.smallRadius, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: DesignTokens.smallRadius, style: .continuous)
                                        .stroke(selectedActivityKey == activity.key ? Color.accent : Color.gray200, lineWidth: selectedActivityKey == activity.key ? 1.5 : 1)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Duration input
                if let activity = selectedActivity {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(appLanguage == "en"
                            ? "Duration (\(activity.unit ?? "min"))"
                            : "Dauer (\(activity.unit ?? "Min"))")
                            .font(.appSubheadlineMedium)
                            .foregroundStyle(.textPrimary)

                        HStack(spacing: 16) {
                            Button {
                                doneQuota = max(0, doneQuota - 5)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.appTitle2)
                                    .foregroundStyle(.textSecondary)
                            }

                            Text("\(doneQuota)")
                                .font(.system(size: 28, weight: .bold, design: .monospaced))
                                .foregroundStyle(complianceColor)
                                .frame(width: 60)

                            Button {
                                doneQuota += 5
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.appTitle2)
                                    .foregroundStyle(.textSecondary)
                            }
                        }
                        .frame(maxWidth: .infinity)

                        // Compliance feedback
                        if let quota = activity.quota, quota > 0 {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(complianceColor)
                                    .frame(width: 8, height: 8)
                                Text("\(Int(compliancePercentage))% — \(complianceLabel)")
                                    .font(.appCaption)
                                    .foregroundStyle(complianceColor)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }

                    // Pauses (if mandatory)
                    if let pauseMinutes = viewModel.pacingPlan?.rules.mandatoryPauseMinutes, pauseMinutes > 0 {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(appLanguage == "en" ? "Number of breaks" : "Anzahl Pausen")
                                .font(.appSubheadlineMedium)
                                .foregroundStyle(.textPrimary)

                            Stepper(appLanguage == "en"
                                ? "\(donePauses) break\(donePauses == 1 ? "" : "s")"
                                : "\(donePauses) Pausen", value: $donePauses, in: 0...20)
                                .font(.appSubheadline)
                        }
                    }

                    // Notes
                    VStack(alignment: .leading, spacing: 6) {
                        Text(appLanguage == "en" ? "Notes (optional)" : "Notizen (optional)")
                            .font(.appSubheadlineMedium)
                            .foregroundStyle(.textPrimary)

                        TextEditor(text: $notes)
                            .font(.appSubheadline)
                            .frame(minHeight: 60)
                            .padding(8)
                            .background {
                                RoundedRectangle(cornerRadius: DesignTokens.inputRadius, style: .continuous)
                                    .fill(.ultraThinMaterial)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: DesignTokens.inputRadius, style: .continuous)
                                            .fill(Color.cardBg.opacity(0.65))
                                    }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.inputRadius, style: .continuous))
                    }

                    // Info box
                    HStack(spacing: 10) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(.farBlue)
                        Text(appLanguage == "en"
                            ? "Pacing principle: Better to stay below the quota than above it."
                            : "Pacing-Prinzip: Besser unter der Quote bleiben als darüber.")
                            .font(.appCaption)
                            .foregroundStyle(.textSecondary)
                    }
                    .infoBoxStyle(color: .farBlue)
                }

                // Submit button
                if selectedActivityKey != nil {
                    Button {
                        Task { await submit() }
                    } label: {
                        Group {
                            if isSubmitting {
                                ProgressView().tint(.white)
                            } else {
                                Text(appLanguage == "en" ? "Log activity" : "Aktivität protokollieren")
                            }
                        }
                        .font(.appBodySemibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.accent)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.buttonRadius, style: .continuous))
                    }
                    .disabled(isSubmitting)
                }
            }
            .padding(24)
        }
        .background(Color.appBg)
        .navigationTitle(appLanguage == "en" ? "Log Activity" : "Aktivität protokollieren")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(appLanguage == "en" ? "Cancel" : "Abbrechen") { dismiss() }
            }
        }
    }

    // MARK: - Success View

    private var successView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.painGreen)

            Text(appLanguage == "en" ? "Saved successfully!" : "Erfolgreich gespeichert!")
                .font(.appTitle3)
                .foregroundStyle(.textPrimary)

            if compliancePercentage > 110 {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.painAmber)
                    Text(appLanguage == "en"
                        ? "Quota exceeded. Try shorter sessions next time."
                        : "Quote überschritten. Versuchen Sie beim nächsten Mal etwas kürzere Einheiten.")
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                }
                .infoBoxStyle(color: .painAmber)
                .padding(.horizontal, 24)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Text(appLanguage == "en" ? "Done" : "Fertig")
                    .font(.appBodySemibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.accent)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.buttonRadius, style: .continuous))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(Color.appBg)
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Submit

    private func submit() async {
        guard let key = selectedActivityKey, let quota = selectedActivity?.quota else { return }
        isSubmitting = true

        let request = PacingLogRequest(
            activityKey: key,
            logDate: nil,
            plannedQuota: quota,
            doneQuota: doneQuota,
            plannedPauses: viewModel.pacingPlan?.rules.mandatoryPauseMinutes != nil ? expectedPauses : nil,
            donePauses: viewModel.pacingPlan?.rules.mandatoryPauseMinutes != nil ? donePauses : nil,
            notes: notes.isEmpty ? nil : notes
        )

        if await viewModel.logPacingActivity(request: request) {
            withAnimation { showSuccess = true }
        }
        isSubmitting = false
    }

    private var expectedPauses: Int {
        guard let freq = viewModel.pacingPlan?.rules.pauseFrequencyMinutes, freq > 0,
              let quota = selectedActivity?.quota else { return 0 }
        return max(0, quota / freq - 1)
    }
}
