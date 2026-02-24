import SwiftUI

struct AclDailyKpiLoggerView: View {
    @Environment(APIClient.self) private var apiClient
    @Environment(\.dismiss) private var dismiss

    let onSuccess: () -> Void

    @State private var viewModel: AclDailyKpiViewModel?
    @State private var showSuccess = false
    @State private var submitSuccessTrigger = false
    @State private var showDiscardConfirmation = false

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
            .navigationTitle("Tägliche KPIs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        if let vm = viewModel, vm.hasUnsavedChanges {
                            showDiscardConfirmation = true
                        } else {
                            dismiss()
                        }
                    }
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
            let vm = AclDailyKpiViewModel(apiClient: apiClient)
            viewModel = vm
        }
        .overlay {
            if showSuccess {
                SuccessBanner(message: "Tägliche KPIs gespeichert!")
            }
        }
        .conditionalHaptic(.success, trigger: submitSuccessTrigger)
        .confirmationDialog("Änderungen verwerfen?", isPresented: $showDiscardConfirmation, titleVisibility: .visible) {
            Button("Verwerfen", role: .destructive) { dismiss() }
            Button("Weiter bearbeiten", role: .cancel) {}
        } message: {
            Text("Ihre eingegebenen KPIs wurden noch nicht gespeichert.")
        }
    }

    @ViewBuilder
    private func formContent(_ vm: AclDailyKpiViewModel) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Pain NRS
                painSection(vm)

                // Donor Site Pain
                donorSitePainSection(vm)

                // Pain Location & Activity
                painDetailSection(vm)

                // ROM
                romSection(vm)

                // Swelling
                swellingSection(vm)

                // Quads Lag
                quadsLagSection(vm)

                // Notes
                notesSection(vm)

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
                            Text("KPIs speichern")
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

    // MARK: - Pain NRS

    @ViewBuilder
    private func painSection(_ vm: AclDailyKpiViewModel) -> some View {
        VStack(spacing: 12) {
            Text("Schmerzintensität (NRS)")
                .font(.appCaption)
                .foregroundStyle(.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(vm.painNrs)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(painColor(for: vm.painNrs))
                    .contentTransition(.numericText())
                    .animation(.spring(duration: 0.2), value: vm.painNrs)
                Text("/10")
                    .font(.appTitle3)
                    .foregroundStyle(.textSecondary)
            }

            Slider(
                value: Binding(
                    get: { Double(vm.painNrs) },
                    set: { vm.painNrs = Int($0.rounded()) }
                ),
                in: 0...10,
                step: 1
            )
            .tint(painColor(for: vm.painNrs))

            HStack {
                Text("0 (kein Schmerz)")
                    .font(.appCaption2)
                    .foregroundStyle(.textSecondary)
                Spacer()
                Text("10 (stärkster)")
                    .font(.appCaption2)
                    .foregroundStyle(.textSecondary)
            }
        }
    }

    // MARK: - Donor Site Pain

    @ViewBuilder
    private func donorSitePainSection(_ vm: AclDailyKpiViewModel) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("Entnahmestellen-Schmerz (NRS)")
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
                Spacer()
                Text("\(vm.donorSitePainNrs)/10")
                    .font(.appSubheadlineMedium)
                    .foregroundStyle(painColor(for: vm.donorSitePainNrs))
            }

            Slider(
                value: Binding(
                    get: { Double(vm.donorSitePainNrs) },
                    set: { vm.donorSitePainNrs = Int($0.rounded()) }
                ),
                in: 0...10,
                step: 1
            )
            .tint(painColor(for: vm.donorSitePainNrs))
            .accessibilityLabel("Entnahmestellen-Schmerz")
            .accessibilityValue("\(vm.donorSitePainNrs) von 10")

            Text("Schmerz an der Transplantat-Entnahmestelle")
                .font(.appCaption2)
                .foregroundStyle(.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Pain Detail

    @ViewBuilder
    private func painDetailSection(_ vm: AclDailyKpiViewModel) -> some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Schmerzlokalisation (optional)")
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
                TextField("z.B. vorderes Knie, Innenseite", text: Binding(
                    get: { vm.painLocation },
                    set: { vm.painLocation = $0 }
                ))
                .inputFieldStyle()
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Schmerzauslösende Aktivität (optional)")
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
                TextField("z.B. Treppensteigen, Joggen", text: Binding(
                    get: { vm.painActivity },
                    set: { vm.painActivity = $0 }
                ))
                .inputFieldStyle()
            }
        }
    }

    // MARK: - ROM

    @ViewBuilder
    private func romSection(_ vm: AclDailyKpiViewModel) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Flexion (0-160°)")
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
                TextField("z.B. 90", text: Binding(
                    get: { "\(vm.kneeFlexionDeg)" },
                    set: { newValue in
                        if let val = Int(newValue) {
                            vm.kneeFlexionDeg = min(160, max(0, val))
                        } else if newValue.isEmpty {
                            vm.kneeFlexionDeg = 0
                        }
                    }
                ))
                .keyboardType(.numberPad)
                .inputFieldStyle()
                .accessibilityLabel("Knieflexion in Grad")
                .accessibilityValue("\(vm.kneeFlexionDeg) Grad")
            }
            .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 6) {
                Text("Ext.-Defizit (0-30°)")
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
                TextField("z.B. 5", text: Binding(
                    get: { "\(vm.extensionDeficitDeg)" },
                    set: { newValue in
                        if let val = Int(newValue) {
                            vm.extensionDeficitDeg = min(30, max(0, val))
                        } else if newValue.isEmpty {
                            vm.extensionDeficitDeg = 0
                        }
                    }
                ))
                .keyboardType(.numberPad)
                .inputFieldStyle()
                .accessibilityLabel("Extensionsdefizit in Grad")
                .accessibilityValue("\(vm.extensionDeficitDeg) Grad")
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Swelling

    @ViewBuilder
    private func swellingSection(_ vm: AclDailyKpiViewModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Erguss (Stroke Test)")
                .font(.appCaption)
                .foregroundStyle(.textSecondary)

            HStack(spacing: 0) {
                ForEach(0..<4, id: \.self) { grade in
                    Button {
                        vm.swellingGrade = grade
                    } label: {
                        Text(swellingLabel(for: grade))
                            .font(.appCaption)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(vm.swellingGrade == grade ? Color.textPrimary : Color.cardBg)
                            .foregroundStyle(vm.swellingGrade == grade ? Color.appBg : .textPrimary)
                    }
                    .accessibilityAddTraits(vm.swellingGrade == grade ? .isSelected : [])
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.inputRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.inputRadius, style: .continuous)
                    .stroke(Color.gray300, lineWidth: 1)
            )
        }
    }

    // MARK: - Quads Lag

    @ViewBuilder
    private func quadsLagSection(_ vm: AclDailyKpiViewModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quadrizeps-Lag")
                .font(.appCaption)
                .foregroundStyle(.textSecondary)

            HStack(spacing: 0) {
                Button {
                    vm.quadsLag = false
                } label: {
                    Text("Nein")
                        .font(.appSubheadlineMedium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(!vm.quadsLag ? Color.textPrimary : Color.cardBg)
                        .foregroundStyle(!vm.quadsLag ? Color.appBg : .textPrimary)
                }
                .accessibilityAddTraits(!vm.quadsLag ? .isSelected : [])

                Button {
                    vm.quadsLag = true
                } label: {
                    Text("Ja")
                        .font(.appSubheadlineMedium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(vm.quadsLag ? Color.textPrimary : Color.cardBg)
                        .foregroundStyle(vm.quadsLag ? Color.appBg : .textPrimary)
                }
                .accessibilityAddTraits(vm.quadsLag ? .isSelected : [])
            }
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.inputRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.inputRadius, style: .continuous)
                    .stroke(Color.gray300, lineWidth: 1)
            )
        }
    }

    // MARK: - Notes

    @ViewBuilder
    private func notesSection(_ vm: AclDailyKpiViewModel) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Notizen (optional)")
                .font(.appCaption)
                .foregroundStyle(.textSecondary)
            TextField("Optionale Anmerkungen...", text: Binding(
                get: { vm.notes },
                set: { vm.notes = $0 }
            ), axis: .vertical)
            .inputFieldStyle()
            .lineLimit(3...5)
        }
    }

    // MARK: - Submit

    private func submit(_ vm: AclDailyKpiViewModel) async {
        let success = await vm.submit()
        if success {
            showSuccess = true
            submitSuccessTrigger.toggle()
            onSuccess()
            try? await Task.sleep(for: .seconds(1.5))
            dismiss()
        }
    }

    // MARK: - Helpers

    private func painColor(for level: Int) -> Color {
        if level <= 3 { return .painGreen }
        if level <= 6 { return .painAmber }
        return .painRed
    }

    private func swellingLabel(for grade: Int) -> String {
        switch grade {
        case 0: "0 Keine"
        case 1: "1 Gering"
        case 2: "2 Mässig"
        case 3: "3 Stark"
        default: "\(grade)"
        }
    }
}
