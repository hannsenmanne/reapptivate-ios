import SwiftUI

struct TsiScreeningView: View {
    @Environment(AppState.self) private var appState
    @Environment(APIClient.self) private var apiClient
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appLanguage") private var appLanguage = "de"

    let isRescreening: Bool
    var isEmbedded = false
    @State private var viewModel: TsiScreeningViewModel?
    @State private var showResult = false
    @State private var selectionTrigger = false

    var body: some View {
        let isEn = appLanguage == "en"

        NavigationStack {
            Group {
                if let vm = viewModel {
                    if vm.isLoading {
                        LoadingView(message: isEn ? "Loading TSI questionnaire..." : "TSI-Fragebogen laden...")
                    } else if showResult, let result = vm.result {
                        TsiResultView(result: result) {
                            // Update AppState immediately - screening was successfully submitted
                            appState.currentUser?.tensionScreeningCompleted = true
                            appState.currentUser?.tsiSeverity = TsiSeverityGrade.from(tsiScore: result.tsiScore)
                            dismiss()
                        }
                    } else if let item = vm.currentItem {
                        VStack(spacing: 0) {
                            // Progress bar
                            ProgressView(value: vm.progress)
                                .tint(.accent)
                                .padding(.horizontal, 16)
                                .padding(.top, 8)

                            HStack {
                                Spacer()
                                Text(isEn ? "\(vm.currentItemIndex + 1) of \(vm.items.count)" : "\(vm.currentItemIndex + 1) von \(vm.items.count)")
                                    .font(.appCaption)
                                    .foregroundStyle(.textSecondary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 4)

                            // Question
                            TsiQuestionView(
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
            .navigationTitle(isRescreening ? (isEn ? "TSI Rescreening" : "TSI-Rescreening") : (isEn ? "TSI Screening" : "TSI-Screening"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if let vm = viewModel, vm.currentItemIndex > 0 && !showResult {
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
            let vm = TsiScreeningViewModel(apiClient: apiClient, isRescreening: isRescreening)
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
