import SwiftUI

struct PacingActivityLogSheet: View {
    @Bindable var viewModel: LbpEnhancementsViewModel
    @Environment(\.dismiss) private var dismiss

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
        if compliancePercentage <= 90 { return "Gut dosiert" }
        if compliancePercentage <= 110 { return "Im Zielbereich" }
        return "Uber der Quote"
    }

    var body: some View {
        NavigationStack {
            if showSuccess {
                successView
            } else {
                formView
            }
        }
    }

    // MARK: - Form View

    private var formView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Activity selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Welche Aktivitat haben Sie gemacht?")
                        .font(.subheadline.weight(.medium))
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
                                        .font(.subheadline)
                                        .foregroundStyle(.textPrimary)

                                    Spacer()

                                    if let quota = activity.quota {
                                        Text("Ziel: \(quota) \(activity.unit ?? "Min")")
                                            .font(.caption)
                                            .foregroundStyle(.textSecondary)
                                    }
                                }
                                .padding(12)
                                .background(selectedActivityKey == activity.key ? Color.accent.opacity(0.06) : Color.cardBg)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(selectedActivityKey == activity.key ? Color.accent : .clear, lineWidth: 1.5)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Duration input
                if let activity = selectedActivity {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Dauer (\(activity.unit ?? "Min"))")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.textPrimary)

                        HStack(spacing: 16) {
                            Button {
                                doneQuota = max(0, doneQuota - 5)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.textSecondary)
                            }

                            Text("\(doneQuota)")
                                .font(.title.weight(.bold).monospacedDigit())
                                .foregroundStyle(complianceColor)
                                .frame(width: 60)

                            Button {
                                doneQuota += 5
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
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
                                    .font(.caption)
                                    .foregroundStyle(complianceColor)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }

                    // Pauses (if mandatory)
                    if let pauseMinutes = viewModel.pacingPlan?.rules.mandatoryPauseMinutes, pauseMinutes > 0 {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Anzahl Pausen")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.textPrimary)

                            Stepper("\(donePauses) Pausen", value: $donePauses, in: 0...20)
                                .font(.subheadline)
                        }
                    }

                    // Notes
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Notizen (optional)")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.textPrimary)

                        TextEditor(text: $notes)
                            .font(.subheadline)
                            .frame(minHeight: 60)
                            .padding(8)
                            .background(Color.cardBg)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    // Info box
                    HStack(spacing: 10) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(.farBlue)
                        Text("Pacing-Prinzip: Besser unter der Quote bleiben als daruber.")
                            .font(.caption)
                            .foregroundStyle(.textSecondary)
                    }
                    .padding(12)
                    .background(Color.farBlue.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
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
                                Text("Aktivitat protokollieren")
                            }
                        }
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(isSubmitting)
                }
            }
            .padding(24)
        }
        .background(Color.appBg)
        .navigationTitle("Aktivitat protokollieren")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Abbrechen") { dismiss() }
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

            Text("Erfolgreich gespeichert!")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.textPrimary)

            if compliancePercentage > 110 {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.painAmber)
                    Text("Quote uberschritten. Versuchen Sie beim nachsten Mal etwas kurzere Einheiten.")
                        .font(.caption)
                        .foregroundStyle(.textSecondary)
                }
                .padding(12)
                .background(Color.painAmber.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal, 24)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("Fertig")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
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
