import SwiftUI

struct AclScreeningView: View {
    @Environment(AppState.self) private var appState
    @Environment(APIClient.self) private var apiClient
    @Environment(\.dismiss) private var dismiss

    let isEmbedded: Bool

    @State private var viewModel: AclScreeningViewModel?
    @State private var showResult = false
    @State private var selectionTrigger = false

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    if vm.isLoading {
                        LoadingView(message: "Screening wird geladen...")
                    } else if showResult, vm.result != nil {
                        AclScreeningCompleteView {
                            appState.currentUser?.aclScreeningCompleted = true
                            dismiss()
                        }
                    } else if let step = vm.currentStep {
                        aclStepView(step: step, vm: vm)
                    } else if let error = vm.errorMessage {
                        ErrorView(message: error) {
                            await vm.loadConfig()
                        }
                    }
                } else {
                    LoadingView()
                }
            }
            .background(Color.appBg)
            .navigationTitle("Kreuzband-Screening")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if let vm = viewModel, vm.currentStepIndex > 0 && !showResult {
                        Button {
                            vm.goBack()
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                    }
                }
            }
            .interactiveDismissDisabled()
            .conditionalHaptic(.selection, trigger: selectionTrigger)
        }
        .task {
            let vm = AclScreeningViewModel(apiClient: apiClient)
            viewModel = vm
            await vm.loadConfig()
        }
    }

    // MARK: - Step View (main layout)

    @ViewBuilder
    private func aclStepView(step: AclScreeningStep, vm: AclScreeningViewModel) -> some View {
        VStack(spacing: 0) {
            ProgressView(value: vm.progress)
                .tint(.accent)
                .padding(.horizontal, 16)
                .padding(.top, 8)

            HStack {
                Spacer()
                Text("Schritt \(vm.currentStepIndex + 1) von \(vm.steps.count)")
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)

            ScrollView {
                AclStepContentView(
                    step: step,
                    vm: vm,
                    selectionTrigger: $selectionTrigger
                )
                .padding(.horizontal, 24)
                .padding(.top, 24)
            }
            .id(step.id)
            .transition(.asymmetric(
                insertion: .move(edge: .trailing),
                removal: .move(edge: .leading)
            ))

            Spacer(minLength: 0)

            AclBottomBarView(
                vm: vm,
                showResult: $showResult
            )
        }
    }
}

// MARK: - Step Content

private struct AclStepContentView: View {
    let step: AclScreeningStep
    let vm: AclScreeningViewModel
    @Binding var selectionTrigger: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(step.labelDE)
                .font(.appTitle2)
                .foregroundStyle(.textPrimary)

            if let helpText = step.helpText {
                Text(helpText)
                    .font(.appSubheadline)
                    .foregroundStyle(.textSecondary)
            }

            Spacer().frame(height: 8)

            switch step.type {
            case "date":
                AclDateStepView(vm: vm)
            case "radio":
                AclRadioStepView(step: step, vm: vm, selectionTrigger: $selectionTrigger)
            case "checkbox":
                AclCheckboxStepView(step: step, vm: vm, selectionTrigger: $selectionTrigger)
            case "text":
                AclTextStepView(step: step, vm: vm)
            default:
                EmptyView()
            }
        }
    }
}

// MARK: - Date Step

private struct AclDateStepView: View {
    let vm: AclScreeningViewModel

    var body: some View {
        let fiveYearsAgo = Calendar.current.date(byAdding: .year, value: -5, to: Date()) ?? Date()
        let twoYearsAhead = Calendar.current.date(byAdding: .year, value: 2, to: Date()) ?? Date()

        DatePicker(
            "Operationsdatum",
            selection: Binding(
                get: { vm.surgeryDate },
                set: { vm.setSurgeryDate($0) }
            ),
            in: fiveYearsAgo...twoYearsAhead,
            displayedComponents: .date
        )
        .datePickerStyle(.graphical)
        .tint(.accent)
        .environment(\.locale, Locale(identifier: "de_DE"))
    }
}

// MARK: - Radio Step

private struct AclRadioStepView: View {
    let step: AclScreeningStep
    let vm: AclScreeningViewModel
    @Binding var selectionTrigger: Bool

    private var selectedValue: String? {
        switch step.id {
        case "graft_type": return vm.graftType
        case "athlete_level": return vm.athleteLevel
        case "knee_side": return vm.kneeSide
        default: return nil
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            ForEach(step.options ?? [], id: \.value) { option in
                AclRadioOptionRow(
                    option: option,
                    isSelected: selectedValue == option.value,
                    onSelect: {
                        vm.selectRadio(stepId: step.id, value: option.value)
                        selectionTrigger.toggle()
                    }
                )
            }
        }
    }
}

private struct AclRadioOptionRow: View {
    let option: AclScreeningStepOption
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 14) {
                radioIndicator
                optionLabels
                Spacer()
            }
            .padding(16)
            .background(cardBackground)
            .overlay(cardBorder)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var radioIndicator: some View {
        Circle()
            .strokeBorder(isSelected ? Color.accent : Color.gray300, lineWidth: 2)
            .background(
                Circle().fill(isSelected ? Color.accent : Color.clear)
                    .padding(4)
            )
            .frame(width: 24, height: 24)
    }

    private var optionLabels: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(option.labelDE)
                .font(.appBody)
                .foregroundStyle(.textPrimary)

            if let description = option.description {
                Text(description)
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
            }
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: DesignTokens.cardRadius)
            .fill(Color.cardBg)
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: DesignTokens.cardRadius)
            .strokeBorder(isSelected ? Color.accent : Color.gray300, lineWidth: isSelected ? 2 : 1)
    }
}

// MARK: - Checkbox Step

private struct AclCheckboxStepView: View {
    let step: AclScreeningStep
    let vm: AclScreeningViewModel
    @Binding var selectionTrigger: Bool

    var body: some View {
        VStack(spacing: 12) {
            ForEach(step.options ?? [], id: \.value) { option in
                let isSelected = vm.concomitantInjuries.contains(option.value)
                let isDisabled = option.value != "NONE" && vm.concomitantInjuries.contains("NONE")

                AclCheckboxOptionRow(
                    option: option,
                    isSelected: isSelected,
                    isDisabled: isDisabled,
                    onToggle: {
                        vm.toggleCheckbox(value: option.value)
                        selectionTrigger.toggle()
                    }
                )
            }

            Text("Mehrfachauswahl möglich. Wählen Sie \"Keine\", wenn keine Begleitverletzungen vorliegen.")
                .font(.appCaption)
                .foregroundStyle(.textSecondary)
                .padding(.top, 4)
        }
    }
}

private struct AclCheckboxOptionRow: View {
    let option: AclScreeningStepOption
    let isSelected: Bool
    let isDisabled: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(alignment: .top, spacing: 14) {
                checkboxIndicator
                optionLabels
                Spacer()
            }
            .padding(16)
            .background(cardBackground)
            .overlay(cardBorder)
            .opacity(isDisabled ? 0.4 : 1)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var checkboxIndicator: some View {
        RoundedRectangle(cornerRadius: 4)
            .strokeBorder(isSelected ? Color.accent : Color.gray300, lineWidth: 2)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(isSelected ? Color.accent : Color.clear)
            )
            .overlay {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .frame(width: 24, height: 24)
    }

    private var optionLabels: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(option.labelDE)
                .font(.appBody)
                .foregroundStyle(.textPrimary)

            if let precaution = option.precaution, isSelected {
                Text("Hinweis: \(precaution)")
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
            }
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: DesignTokens.cardRadius)
            .fill(Color.cardBg)
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: DesignTokens.cardRadius)
            .strokeBorder(isSelected ? Color.accent : Color.gray300, lineWidth: isSelected ? 2 : 1)
    }
}

// MARK: - Text Step

private struct AclTextStepView: View {
    let step: AclScreeningStep
    let vm: AclScreeningViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField(
                step.placeholder ?? "",
                text: Binding(
                    get: { vm.sport },
                    set: { vm.sport = $0 }
                )
            )
            .inputFieldStyle()

            if step.required != true {
                Text("Optional")
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
            }
        }
    }
}

// MARK: - Bottom Bar

private struct AclBottomBarView: View {
    let vm: AclScreeningViewModel
    @Binding var showResult: Bool

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            if vm.isOnLastStep && vm.canSubmit {
                submitButton
            } else if !vm.isOnLastStep {
                forwardButton
            }

            if let error = vm.errorMessage, vm.config != nil {
                Text(error)
                    .font(.appCaption)
                    .foregroundStyle(.painRed)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
            }
        }
    }

    private var submitButton: some View {
        Button {
            Task {
                if await vm.submit() {
                    withAnimation { showResult = true }
                }
            }
        } label: {
            Group {
                if vm.isSubmitting {
                    ProgressView().tint(.white)
                } else {
                    Text("Screening abschliessen")
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
        }
        .buttonStyle(.accentFilled)
        .disabled(vm.isSubmitting)
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    @ViewBuilder
    private var forwardButton: some View {
        let stepType = vm.currentStep?.type ?? ""
        if stepType == "date" || stepType == "checkbox" || stepType == "text" {
            Button {
                vm.goForward()
            } label: {
                Text("Weiter")
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
            }
            .buttonStyle(.accentFilled)
            .disabled(!vm.canAdvance)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
    }
}

// MARK: - ACL Screening Complete (inline result)

private struct AclScreeningCompleteView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Circle()
                .fill(Color.accent.opacity(0.12))
                .frame(width: 88, height: 88)
                .overlay {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.accent)
                }

            Text("Screening abgeschlossen!")
                .font(.appTitle2)
                .foregroundStyle(.textPrimary)

            Text("Ihre Angaben wurden erfolgreich gespeichert. Ihr individuelles Rehabilitationsprogramm wird jetzt erstellt.")
                .font(.appBody)
                .foregroundStyle(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                onContinue()
            } label: {
                Text("Weiter")
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
            }
            .buttonStyle(.accentFilled)
            .padding(.horizontal, 24)

            Spacer()
        }
    }
}
