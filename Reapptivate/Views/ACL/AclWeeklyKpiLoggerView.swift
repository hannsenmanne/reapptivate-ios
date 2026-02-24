import SwiftUI

struct AclWeeklyKpiLoggerView: View {
    @Environment(APIClient.self) private var apiClient
    @Environment(\.dismiss) private var dismiss

    let onSuccess: () -> Void

    @State private var viewModel: AclWeeklyKpiViewModel?
    @State private var showSuccess = false
    @State private var submitSuccessTrigger = false

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    formContent(viewModel)
                } else {
                    ProgressView("Laden...")
                }
            }
            .background(Color.appBg)
            .navigationTitle("Wöchentliche KPIs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Fertig") {
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
                SuccessBanner(message: "Wöchentliche KPIs gespeichert!")
            }
        }
        .conditionalHaptic(.success, trigger: submitSuccessTrigger)
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
                if vm.isTampaElevated {
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
                            Text("Wöchentliche KPIs speichern")
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
            Text("IKDC-Score (0-100)")
                .font(.appCaption)
                .foregroundStyle(.textSecondary)
            TextField("z.B. 65", text: Binding(
                get: { vm.ikdcScoreText },
                set: { vm.ikdcScoreText = $0 }
            ))
            .keyboardType(.numberPad)
            .textFieldStyle(.roundedBorder)

            Text("International Knee Documentation Committee \u{2014} subjektive Kniefunktion")
                .font(.appCaption2)
                .foregroundStyle(.textTertiary)
        }
    }

    // MARK: - Tampa

    @ViewBuilder
    private func tampaSection(_ vm: AclWeeklyKpiViewModel) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Tampa-Score (11-44)")
                .font(.appCaption)
                .foregroundStyle(.textSecondary)
            TextField("z.B. 28", text: Binding(
                get: { vm.tampaScoreText },
                set: { vm.tampaScoreText = $0 }
            ))
            .keyboardType(.numberPad)
            .textFieldStyle(.roundedBorder)

            Text("Tampa Scale of Kinesiophobia \u{2014} Bewegungsangst")
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
                Text("Erhöhte Bewegungsangst erkannt")
                    .font(.appCaptionMedium)
                    .foregroundStyle(.textPrimary)
                Text("Sprechen Sie mit Ihrem Therapeuten und nutzen Sie die Edukationsmodule zu Bewegungsangst.")
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
                Text("Oberschenkelumfang 5 cm (cm)")
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
                TextField("z.B. 48.5", text: Binding(
                    get: { vm.thighCirc5cmText },
                    set: { vm.thighCirc5cmText = $0 }
                ))
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)

                Text("5 cm suprapatellär")
                    .font(.appCaption2)
                    .foregroundStyle(.textTertiary)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Oberschenkelumfang 10 cm (cm)")
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
                TextField("z.B. 52.0", text: Binding(
                    get: { vm.thighCirc10cmText },
                    set: { vm.thighCirc10cmText = $0 }
                ))
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)

                Text("10 cm suprapatellär")
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
