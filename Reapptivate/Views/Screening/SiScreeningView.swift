import SwiftUI

struct SiScreeningView: View {
    @Environment(AppState.self) private var appState
    @Environment(APIClient.self) private var apiClient
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appLanguage") private var appLanguage = "de"

    let isRescreening: Bool
    var isEmbedded = false
    @State private var viewModel: SiScreeningViewModel?
    @State private var showResult = false
    @State private var selectionTrigger = false

    var body: some View {
        let isEn = appLanguage == "en"

        NavigationStack {
            Group {
                if let vm = viewModel {
                    if vm.isLoading {
                        LoadingView(message: isEn ? "Loading QuickDASH questionnaire..." : "QuickDASH-Fragebogen laden...")
                    } else if showResult, let result = vm.result {
                        SiResultView(result: result) {
                            appState.currentUser?.siScreeningCompleted = true
                            appState.currentUser?.siSeverity = result.severityGrade
                            dismiss()
                        }
                    } else if let item = vm.currentItem {
                        VStack(spacing: 0) {
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

                            SiQuestionView(
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
            .navigationTitle(isRescreening ? (isEn ? "QuickDASH Rescreening" : "QuickDASH-Rescreening") : (isEn ? "QuickDASH Screening" : "QuickDASH-Screening"))
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
        }
        .task {
            guard viewModel == nil else { return }
            let vm = SiScreeningViewModel(apiClient: apiClient, isRescreening: isRescreening)
            viewModel = vm
            await vm.loadConfig()
        }
    }
}
