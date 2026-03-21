import SwiftUI

struct NeckScreeningView: View {
    @Environment(AppState.self) private var appState
    @Environment(APIClient.self) private var apiClient
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appLanguage") private var appLanguage = "de"

    let isRescreening: Bool
    var isEmbedded = false
    @State private var viewModel: NeckScreeningViewModel?
    @State private var showResult = false
    @State private var selectionTrigger = false

    var body: some View {
        let isEn = appLanguage == "en"

        NavigationStack {
            Group {
                if let vm = viewModel {
                    if vm.isLoading {
                        LoadingView(message: isEn ? "Loading NDI questionnaire..." : "NDI-Fragebogen laden...")
                    } else if showResult, let result = vm.result {
                        NeckResultView(result: result) {
                            // Update AppState immediately - screening was successfully submitted
                            appState.currentUser?.neckScreeningCompleted = true
                            appState.currentUser?.ndiSeverity = NdiSeverityGrade.from(ndiScore: result.ndiScore)
                            dismiss()
                        }
                    } else if vm.showPartTransition {
                        PartTransitionView {
                            vm.continueToPartB()
                        }
                    } else if let item = vm.currentItem {
                        VStack(spacing: 0) {
                            // Progress bar
                            ProgressView(value: vm.progress)
                                .tint(.accent)
                                .padding(.horizontal, 16)
                                .padding(.top, 8)

                            HStack {
                                Text(isEn ? "Part \(vm.currentPart)" : "Teil \(vm.currentPart)")
                                    .font(.appCaptionMedium)
                                    .foregroundStyle(.accent)
                                Spacer()
                                Text(isEn ? "\(vm.currentItemIndex + 1) of \(vm.items.count)" : "\(vm.currentItemIndex + 1) von \(vm.items.count)")
                                    .font(.appCaption)
                                    .foregroundStyle(.textSecondary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 4)

                            // Question
                            NeckQuestionView(
                                item: item,
                                selectedValue: vm.responses[item.id],
                                onSelect: { value in
                                    vm.selectResponse(itemId: item.id, value: value)
                                    selectionTrigger.toggle()
                                }
                            )
                            .id(item.id)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing),
                                removal: .move(edge: .leading)
                            ))

                            Spacer()

                            // Submit button
                            if vm.canSubmit {
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
                                            Text(isEn ? "Show results" : "Auswertung anzeigen")
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                }
                                .buttonStyle(.accentFilled)
                                .disabled(vm.isSubmitting)
                                .padding(.horizontal, 24)
                                .padding(.bottom, 24)
                            }
                        }
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
            .navigationTitle(isRescreening ? (isEn ? "NDI Rescreening" : "NDI-Rescreening") : (isEn ? "NDI Screening" : "NDI-Screening"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if let vm = viewModel, (vm.currentItemIndex > 0 || (vm.currentPart == "B" && !vm.isRescreening)) && !showResult {
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
            .alert(isEn ? "Error" : "Fehler", isPresented: Binding(
                get: { refreshError != nil },
                set: { if !$0 { refreshError = nil } }
            )) {
                Button(isEn ? "Try again" : "Erneut versuchen") {
                    Task { await refreshProfile() }
                }
                Button(isEn ? "Cancel" : "Abbrechen", role: .cancel) {
                    refreshError = nil
                }
            } message: {
                Text(refreshError ?? "")
            }
        }
        .task {
            guard viewModel == nil else { return }
            let vm = NeckScreeningViewModel(apiClient: apiClient, isRescreening: isRescreening)
            viewModel = vm
            await vm.loadConfig()
        }
    }

    @State private var refreshError: String?

    private func refreshProfile() async {
        do {
            let response: UserResponse = try await apiClient.request(APIEndpoints.me())
            appState.handleLogin(user: response.user)
        } catch {
            refreshError = appLanguage == "en" ? "Could not update profile. Please try again." : "Profil konnte nicht aktualisiert werden. Bitte versuchen Sie es erneut."
        }
    }
}

// MARK: - Part Transition

struct PartTransitionView: View {
    @AppStorage("appLanguage") private var appLanguage = "de"
    let onContinue: () -> Void

    var body: some View {
        let isEn = appLanguage == "en"

        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.painGreen)

            Text(isEn ? "Part A completed!" : "Teil A abgeschlossen!")
                .font(.appTitle2)
                .foregroundStyle(.textPrimary)

            Text(isEn ? "Now follows Part B: The Neck Disability Index (NDI) assesses the impact of your neck pain on daily life." : "Jetzt folgt Teil B: Der Neck Disability Index (NDI) bewertet die Auswirkung Ihrer Nackenschmerzen auf den Alltag.")
                .font(.appBody)
                .foregroundStyle(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                onContinue()
            } label: {
                Text(isEn ? "Continue to Part B" : "Weiter zu Teil B")
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
            }
            .buttonStyle(.accentFilled)
            .padding(.horizontal, 24)

            Spacer()
        }
    }
}
