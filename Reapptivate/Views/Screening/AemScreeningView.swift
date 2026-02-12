import SwiftUI

struct AemScreeningView: View {
    @Environment(AppState.self) private var appState
    @Environment(APIClient.self) private var apiClient
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: AemScreeningViewModel?
    @State private var showResult = false

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    if vm.isLoading {
                        LoadingView(message: "Fragebogen laden...")
                    } else if showResult, let result = vm.result {
                        AemResultView(result: result) {
                            dismiss()
                        }
                    } else if let item = vm.currentItem {
                        VStack(spacing: 0) {
                            // Progress bar
                            ProgressView(value: vm.progress)
                                .tint(.accent)
                                .padding(.horizontal, 16)
                                .padding(.top, 8)

                            Text("\(vm.currentItemIndex + 1) von \(vm.items.count)")
                                .font(.caption)
                                .foregroundStyle(.textSecondary)
                                .padding(.top, 4)

                            // Question
                            AemQuestionView(
                                item: item,
                                selectedValue: vm.responses[item.id],
                                onSelect: { value in
                                    vm.selectResponse(itemId: item.id, value: value)
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                }
                            )
                            .id(item.id) // Force re-render on question change
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing),
                                removal: .move(edge: .leading)
                            ))

                            Spacer()

                            // Submit button (last question)
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
                                            Text("Auswertung anzeigen")
                                        }
                                    }
                                    .font(.body.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.accent)
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
            .navigationTitle("AEM-Screening")
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
        }
        .task {
            let vm = AemScreeningViewModel(apiClient: apiClient)
            viewModel = vm
            await vm.loadConfig()
        }
    }
}
