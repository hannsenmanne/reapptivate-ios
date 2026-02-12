import SwiftUI

struct NeckScreeningView: View {
    @Environment(APIClient.self) private var apiClient
    @Environment(\.dismiss) private var dismiss

    let isRescreening: Bool
    @State private var viewModel: NeckScreeningViewModel?
    @State private var showResult = false

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    if vm.isLoading {
                        LoadingView(message: "NDI-Fragebogen laden...")
                    } else if showResult, let result = vm.result {
                        NeckResultView(result: result) {
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
                                Text("Teil \(vm.currentPart)")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.accent)
                                Spacer()
                                Text("\(vm.currentItemIndex + 1) von \(vm.items.count)")
                                    .font(.caption)
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
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
            .navigationTitle(isRescreening ? "NDI-Rescreening" : "NDI-Screening")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if let vm = viewModel, (vm.currentItemIndex > 0 || vm.currentPart == "B") && !showResult {
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
            let vm = NeckScreeningViewModel(apiClient: apiClient, isRescreening: isRescreening)
            viewModel = vm
            await vm.loadConfig()
        }
    }
}

// MARK: - Part Transition

struct PartTransitionView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.painGreen)

            Text("Teil A abgeschlossen!")
                .font(.title2.bold())
                .foregroundStyle(.textPrimary)

            Text("Jetzt folgt Teil B: Der Neck Disability Index (NDI) bewertet die Auswirkung Ihrer Nackenschmerzen auf den Alltag.")
                .font(.body)
                .foregroundStyle(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                onContinue()
            } label: {
                Text("Weiter zu Teil B")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
            }
            .buttonStyle(.borderedProminent)
            .tint(.accent)
            .padding(.horizontal, 24)

            Spacer()
        }
    }
}
