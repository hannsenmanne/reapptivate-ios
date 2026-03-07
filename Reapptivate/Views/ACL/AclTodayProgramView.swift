import SwiftUI

struct AclTodayProgramView: View {
    @Environment(APIClient.self) private var apiClient
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let streamIds: [String]
    let dayLabel: String
    let onComplete: () -> Void

    @State private var viewModel: AclTodayProgramViewModel?
    @State private var completionHaptic = false
    @State private var selectedExercise: AclStreamExercise?

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    if vm.isLoading && vm.streamGroups.isEmpty {
                        todayProgramSkeleton
                    } else if let error = vm.errorMessage, vm.streamGroups.isEmpty {
                        errorContent(error: error, vm: vm)
                    } else {
                        exerciseList(vm: vm)
                    }
                } else {
                    todayProgramSkeleton
                }
            }
            .background(Color.appBg)
            .navigationTitle("Heutiges Programm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Fertig") {
                        onComplete()
                        dismiss()
                    }
                    .font(.appSubheadlineMedium)
                }
            }
        }
        .sheet(item: $selectedExercise) { exercise in
            NavigationStack {
                AclExerciseDetailView(
                    exercise: exercise,
                    isCompleted: viewModel?.isCompleted(exercise.id) ?? false,
                    onToggle: {
                        guard let vm = viewModel else { return }
                        Task {
                            await vm.toggleExercise(exercise)
                            if vm.allDone {
                                completionHaptic.toggle()
                            }
                        }
                        selectedExercise = nil
                    }
                )
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Fertig") { selectedExercise = nil }
                    }
                }
            }
        }
        .conditionalHaptic(.success, trigger: completionHaptic)
        .task {
            if viewModel == nil {
                let vm = AclTodayProgramViewModel(
                    apiClient: apiClient,
                    streamIds: streamIds,
                    userGraftType: appState.currentUser?.aclGraftType?.rawValue,
                    userConcomitantInjuries: Set(appState.currentUser?.aclConcomitantInjuries?.map(\.rawValue) ?? [])
                )
                viewModel = vm
                await vm.loadAll()
            }
        }
    }

    // MARK: - Exercise List

    @ViewBuilder
    private func exerciseList(vm: AclTodayProgramViewModel) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                // Progress header
                todayProgressHeader(vm: vm)
                    .padding(.horizontal, 16)

                // Stream-grouped exercises
                ForEach(Array(vm.streamGroups.enumerated()), id: \.element.id) { groupIndex, group in
                    VStack(alignment: .leading, spacing: 10) {
                        // Stream header
                        HStack(spacing: 8) {
                            Image(systemName: aclStreamIcon(for: group.streamId))
                                .font(.appCaption)
                                .foregroundStyle(.accent)
                                .accessibilityHidden(true)
                            Text(group.streamName)
                                .font(.appCaptionBold)
                                .foregroundStyle(.textSecondary)
                        }
                        .padding(.horizontal, 16)

                        // Exercises
                        ForEach(Array(group.exercises.enumerated()), id: \.element.id) { index, exercise in
                            AclTodayExerciseRow(
                                exercise: exercise,
                                index: vm.globalIndex(for: exercise),
                                isCompleted: vm.isCompleted(exercise.id),
                                isSubmitting: vm.isSubmitting(exercise.id),
                                userGraftType: vm.userGraftType,
                                userConcomitantInjuries: vm.userConcomitantInjuries,
                                onToggle: {
                                    Task {
                                        await vm.toggleExercise(exercise)
                                        if vm.allDone {
                                            completionHaptic.toggle()
                                        }
                                    }
                                },
                                onTap: { selectedExercise = exercise }
                            )
                            .padding(.horizontal, 16)
                            .cardEntryAnimation(index: groupIndex * 5 + index)
                        }
                    }
                }

                // Completion celebration
                if vm.allDone && vm.totalCount > 0 {
                    allDoneBanner
                        .padding(.horizontal, 16)
                        .padding(.bottom, 32)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(.vertical, 16)
        }
        .refreshable {
            await viewModel?.loadAll()
        }
    }

    // MARK: - Progress Header

    private func todayProgressHeader(vm: AclTodayProgramViewModel) -> some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(dayLabel)
                        .font(.appSubheadlineSemibold)
                        .foregroundStyle(.textPrimary)
                    Text("\(vm.completedCount)/\(vm.totalCount) Übungen erledigt")
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                }

                Spacer()

                if vm.allDone {
                    Text("Fertig!")
                        .font(.appCaptionBold)
                        .foregroundStyle(.painGreen)
                } else {
                    let remaining = vm.totalCount - vm.completedCount
                    let minutes = remaining * 5
                    Text("ca. \(minutes) Min.")
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                }
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: DesignTokens.progressBarRadius)
                        .fill(Color.textSecondary.opacity(0.15))
                        .frame(height: 4)
                    RoundedRectangle(cornerRadius: DesignTokens.progressBarRadius)
                        .fill(vm.allDone ? Color.painGreen : Color.accent)
                        .frame(
                            width: geo.size.width * CGFloat(vm.progress),
                            height: 4
                        )
                        .animation(.spring(duration: 0.4), value: vm.progress)
                }
            }
            .frame(height: 4)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Fortschritt")
            .accessibilityValue("\(vm.completedCount) von \(vm.totalCount) Übungen erledigt")
        }
    }

    // MARK: - All Done Banner

    private var allDoneBanner: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 40))
                .foregroundStyle(.painGreen)

            Text("Alle Übungen erledigt!")
                .font(.appHeadline)
                .foregroundStyle(.textPrimary)

            Text("Gut gemacht. Gönnen Sie sich Erholung bis zum nächsten Training.")
                .font(.appSubheadline)
                .foregroundStyle(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .accentCardStyle(color: .painGreen, padding: 0)
    }

    // MARK: - Skeleton

    private var todayProgramSkeleton: some View {
        VStack(spacing: 16) {
            SkeletonView(variant: .card(height: 60))
            ForEach(0..<4, id: \.self) { _ in
                SkeletonView(variant: .card(height: 100))
            }
        }
        .padding(16)
    }

    // MARK: - Error

    @ViewBuilder
    private func errorContent(error: String, vm: AclTodayProgramViewModel) -> some View {
        VStack(spacing: 16) {
            InlineErrorView(
                message: error,
                errorType: .network,
                onRetry: { Task { await vm.loadAll() } }
            )
        }
        .padding(16)
    }
}
