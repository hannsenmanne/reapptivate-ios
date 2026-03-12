import SwiftUI

struct AclWeeklyKpiLoggerView: View {
    @Environment(APIClient.self) private var apiClient
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appLanguage") private var appLanguage = "de"

    let onSuccess: () -> Void

    @State private var viewModel: AclWeeklyKpiViewModel?
    @State private var showSuccess = false
    @State private var submitSuccessTrigger = false
    @State private var showDiscardConfirmation = false

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    formContent(viewModel)
                } else {
                    ProgressView(appLanguage == "en" ? "Loading..." : "Laden...")
                }
            }
            .background(Color.appBg)
            .navigationTitle(appLanguage == "en" ? "Weekly KPIs" : "Wöchentliche KPIs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(appLanguage == "en" ? "Cancel" : "Abbrechen") {
                        if let vm = viewModel, vm.hasAnyValue {
                            showDiscardConfirmation = true
                        } else {
                            dismiss()
                        }
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(appLanguage == "en" ? "Done" : "Fertig") {
                        UIApplication.shared.sendAction(
                            #selector(UIResponder.resignFirstResponder),
                            to: nil, from: nil, for: nil
                        )
                    }
                    .font(.appSubheadlineMedium)
                    .foregroundStyle(.accent)
                }
            }
        }
        .task {
            let vm = AclWeeklyKpiViewModel(apiClient: apiClient)
            viewModel = vm
        }
        .overlay {
            if showSuccess {
                SuccessBanner(message: appLanguage == "en" ? "Weekly KPIs saved!" : "Wöchentliche KPIs gespeichert!")
            }
        }
        .conditionalHaptic(.success, trigger: submitSuccessTrigger)
        .confirmationDialog(appLanguage == "en" ? "Discard changes?" : "Änderungen verwerfen?", isPresented: $showDiscardConfirmation, titleVisibility: .visible) {
            Button(appLanguage == "en" ? "Discard" : "Verwerfen", role: .destructive) { dismiss() }
            Button(appLanguage == "en" ? "Continue editing" : "Weiter bearbeiten", role: .cancel) {}
        } message: {
            Text(appLanguage == "en" ? "Your entered KPIs have not been saved yet." : "Ihre eingegebenen KPIs wurden noch nicht gespeichert.")
        }
    }

    @ViewBuilder
    private func formContent(_ vm: AclWeeklyKpiViewModel) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // IKDC Score
                ikdcSection(vm)

                // Tampa Score
                tampaSection(vm)

                // Tampa Alert
                if vm.isTampaElevated || vm.showTampaAlert {
                    tampaAlertBanner
                }

                // Thigh Circumference
                thighSection(vm)

                // Error
                if let error = vm.errorMessage {
                    Text(error)
                        .font(.appCaption)
                        .foregroundStyle(.painRed)
                }

                // Submit
                Button {
                    Task { await submit(vm) }
                } label: {
                    Group {
                        if vm.isSubmitting {
                            ProgressView().tint(.white)
                        } else {
                            Text(appLanguage == "en" ? "Save Weekly KPIs" : "Wöchentliche KPIs speichern")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                }
                .buttonStyle(.accentFilled)
                .disabled(vm.isSubmitting)
            }
            .padding(20)
        }
    }

    // MARK: - IKDC

    @ViewBuilder
    private func ikdcSection(_ vm: AclWeeklyKpiViewModel) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(appLanguage == "en" ? "IKDC Score (0-100)" : "IKDC-Score (0-100)")
                .font(.appCaption)
                .foregroundStyle(.textSecondary)
            TextField(appLanguage == "en" ? "e.g. 65" : "z.B. 65", text: Binding(
                get: { vm.ikdcScoreText },
                set: { vm.ikdcScoreText = $0 }
            ))
            .keyboardType(.numberPad)
            .inputFieldStyle()
            .accessibilityLabel(appLanguage == "en" ? "IKDC score, 0 to 100" : "IKDC-Score, 0 bis 100")

            Text(appLanguage == "en" ? "International Knee Documentation Committee \u{2014} subjective knee function" : "International Knee Documentation Committee \u{2014} subjektive Kniefunktion")
                .font(.appCaption2)
                .foregroundStyle(.textTertiary)
        }
    }

    // MARK: - Tampa

    @ViewBuilder
    private func tampaSection(_ vm: AclWeeklyKpiViewModel) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(appLanguage == "en" ? "Tampa Score (11-44)" : "Tampa-Score (11-44)")
                .font(.appCaption)
                .foregroundStyle(.textSecondary)
            TextField(appLanguage == "en" ? "e.g. 28" : "z.B. 28", text: Binding(
                get: { vm.tampaScoreText },
                set: { vm.tampaScoreText = $0 }
            ))
            .keyboardType(.numberPad)
            .inputFieldStyle()
            .accessibilityLabel(appLanguage == "en" ? "Tampa score, 11 to 44" : "Tampa-Score, 11 bis 44")

            Text(appLanguage == "en" ? "Tampa Scale of Kinesiophobia \u{2014} fear of movement" : "Tampa Scale of Kinesiophobia \u{2014} Bewegungsangst")
                .font(.appCaption2)
                .foregroundStyle(.textTertiary)
        }
    }

    private var tampaAlertBanner: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.painAmber)
                .font(.appBody)

            VStack(alignment: .leading, spacing: 4) {
                Text(appLanguage == "en" ? "Elevated fear of movement detected" : "Erhöhte Bewegungsangst erkannt")
                    .font(.appCaptionMedium)
                    .foregroundStyle(.textPrimary)
                Text(appLanguage == "en" ? "Talk to your therapist and use the education modules on fear of movement." : "Sprechen Sie mit Ihrem Therapeuten und nutzen Sie die Edukationsmodule zu Bewegungsangst.")
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .infoBoxStyle(color: .painAmber)
    }

    // MARK: - Thigh Circumference

    @ViewBuilder
    private func thighSection(_ vm: AclWeeklyKpiViewModel) -> some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(appLanguage == "en" ? "Thigh circumference 5 cm (cm)" : "Oberschenkelumfang 5 cm (cm)")
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
                TextField(appLanguage == "en" ? "e.g. 48.5" : "z.B. 48.5", text: Binding(
                    get: { vm.thighCirc5cmText },
                    set: { vm.thighCirc5cmText = $0 }
                ))
                .keyboardType(.decimalPad)
                .inputFieldStyle()
                .accessibilityLabel(appLanguage == "en" ? "Thigh circumference 5 cm suprapatellar in centimeters" : "Oberschenkelumfang 5 cm suprapatellär in Zentimetern")

                Text(appLanguage == "en" ? "5 cm suprapatellar" : "5 cm suprapatellär")
                    .font(.appCaption2)
                    .foregroundStyle(.textTertiary)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(appLanguage == "en" ? "Thigh circumference 10 cm (cm)" : "Oberschenkelumfang 10 cm (cm)")
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
                TextField(appLanguage == "en" ? "e.g. 52.0" : "z.B. 52.0", text: Binding(
                    get: { vm.thighCirc10cmText },
                    set: { vm.thighCirc10cmText = $0 }
                ))
                .keyboardType(.decimalPad)
                .inputFieldStyle()
                .accessibilityLabel(appLanguage == "en" ? "Thigh circumference 10 cm suprapatellar in centimeters" : "Oberschenkelumfang 10 cm suprapatellär in Zentimetern")

                Text(appLanguage == "en" ? "10 cm suprapatellar" : "10 cm suprapatellär")
                    .font(.appCaption2)
                    .foregroundStyle(.textTertiary)
            }
        }
    }

    // MARK: - Submit

    private func submit(_ vm: AclWeeklyKpiViewModel) async {
        let success = await vm.submit()
        if success {
            showSuccess = true
            submitSuccessTrigger.toggle()
            onSuccess()
            try? await Task.sleep(for: .seconds(1.5))
            dismiss()
        }
    }
}
