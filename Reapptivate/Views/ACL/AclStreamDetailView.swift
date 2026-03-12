import SwiftUI

struct AclStreamDetailView: View {
    @Environment(APIClient.self) private var apiClient
    @Environment(AppState.self) private var appState
    @AppStorage("appLanguage") private var appLanguage = "de"

    let streamId: String

    @State private var viewModel: AclStreamViewModel?
    @State private var selectedExercise: AclStreamExercise?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let vm = viewModel {
                    if vm.isLoading {
                        ProgressView("Stream laden...")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                    } else if let error = vm.errorMessage {
                        InlineErrorView(
                            message: error,
                            errorType: .network,
                            onRetry: { Task { await vm.loadDetail() } }
                        )
                    } else {
                        streamContent(vm: vm)
                    }
                } else {
                    ProgressView("Stream laden...")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                }
            }
            .padding(16)
        }
        .background(Color.appBg)
        .navigationTitle(viewModel?.streamDetail?.nameDE ?? viewModel?.streamDetail?.name ?? "Stream")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedExercise) { exercise in
            NavigationStack {
                AclExerciseDetailView(
                    exercise: exercise,
                    isCompleted: false,
                    onToggle: { selectedExercise = nil }
                )
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Fertig") { selectedExercise = nil }
                    }
                }
            }
        }
        .task {
            if viewModel == nil {
                let vm = AclStreamViewModel(apiClient: apiClient, streamId: streamId)
                viewModel = vm
                await vm.loadDetail()
            }
        }
    }

    @ViewBuilder
    private func streamContent(vm: AclStreamViewModel) -> some View {
        // Stream header
        if let detail = vm.streamDetail {
            VStack(alignment: .leading, spacing: 8) {
                if let milestone = detail.milestone {
                    Text("Meilenstein \(milestone)")
                        .font(.appCaptionMedium)
                        .foregroundStyle(.accent)
                }

                if let desc = detail.descriptionDE ?? detail.description {
                    Text(desc)
                        .font(.appSubheadline)
                        .foregroundStyle(.textSecondary)
                }

                Text(appLanguage == "en"
                    ? "\(vm.exercises.count) exercise\(vm.exercises.count == 1 ? "" : "s")"
                    : "\(vm.exercises.count) Übungen")
                    .font(.appCaptionMedium)
                    .foregroundStyle(.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accent.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.badgeRadius, style: .continuous))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardEntryAnimation(index: 0)
        }

        // Exercise list
        ForEach(Array(vm.exercises.enumerated()), id: \.element.id) { index, exercise in
            AclExerciseCard(
                exercise: exercise,
                index: index,
                userGraftType: appState.currentUser?.aclGraftType?.rawValue,
                userConcomitantInjuries: Set(appState.currentUser?.aclConcomitantInjuries?.map(\.rawValue) ?? [])
            )
            .contentShape(Rectangle())
            .onTapGesture { selectedExercise = exercise }
            .cardEntryAnimation(index: index + 1)
        }
    }
}

// MARK: - Exercise Card

struct AclExerciseCard: View {
    let exercise: AclStreamExercise
    let index: Int
    let userGraftType: String?
    let userConcomitantInjuries: Set<String>
    @AppStorage("appLanguage") private var appLanguage = "de"

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(alignment: .top, spacing: 12) {
                Text(String(format: "%02d", index + 1))
                    .font(.appCaptionMedium)
                    .foregroundStyle(.textSecondary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.nameDE ?? exercise.name)
                        .font(.appSubheadlineSemibold)
                        .foregroundStyle(.textPrimary)

                    if let desc = exercise.descriptionDE ?? exercise.description {
                        Text(desc)
                            .font(.appCaption)
                            .foregroundStyle(.textSecondary)
                            .lineSpacing(2)
                    }
                }
            }

            // Video Thumbnail
            if let videoUrl = exercise.videoUrl {
                VideoThumbnailView(urlString: videoUrl)
            }

            // Graft modifier warning — prefer enriched flat field, fall back to dictionary lookup
            if let note = exercise.graftNote, !note.isEmpty {
                graftModifierView(note)
            } else if let graftModifier = exercise.graftModifier, let graft = userGraftType,
               let note = graftModifier[graft], !note.isEmpty {
                graftModifierView(note)
            }

            // Concomitant precaution — prefer enriched flat field, fall back to dictionary lookup
            if let notes = exercise.precautions, !notes.isEmpty {
                precautionView(notes)
            } else if let precaution = exercise.concomitantPrecaution {
                let relevant = precaution.filter { userConcomitantInjuries.contains($0.key) }
                let notes = relevant.values.filter { !$0.isEmpty }.joined(separator: ". ")
                if !notes.isEmpty {
                    precautionView(notes)
                }
            }

            // Parameters
            parameterBadges
        }
        .cardStyle()
    }

    @ViewBuilder
    private func graftModifierView(_ note: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle.fill")
                .font(.appCaption)
                .foregroundStyle(.farBlue)

            VStack(alignment: .leading, spacing: 2) {
                Text("Transplantat-Hinweis")
                    .font(.appCaption2)
                    .foregroundStyle(.farBlue)
                Text(note)
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
            }
        }
        .infoBoxStyle(color: .farBlue)
    }

    @ViewBuilder
    private func precautionView(_ notes: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.appCaption)
                .foregroundStyle(.painAmber)

            VStack(alignment: .leading, spacing: 2) {
                Text("Vorsicht")
                    .font(.appCaption2)
                    .foregroundStyle(.painAmber)
                Text(notes)
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
            }
        }
        .infoBoxStyle(color: .painAmber)
    }

    @ViewBuilder
    private var parameterBadges: some View {
        let params = buildParameterList()
        if !params.isEmpty {
            FlowLayout(spacing: 6) {
                ForEach(params, id: \.label) { param in
                    Text(param.label)
                        .font(.appCaption2)
                        .foregroundStyle(param.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(param.color.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                }
            }
        }
    }

    private struct ParameterTag: Identifiable {
        let label: String
        let color: Color
        var id: String { label }
    }

    private func buildParameterList() -> [ParameterTag] {
        var tags: [ParameterTag] = []

        if let sets = exercise.sets {
            tags.append(ParameterTag(label: appLanguage == "en"
                ? "\(sets) set\(sets == 1 ? "" : "s")"
                : "\(sets) Sätze", color: .farBlue))
        }
        if let reps = exercise.reps {
            tags.append(ParameterTag(label: "\(reps)x Wdh.", color: .accent))
        }
        if let hold = exercise.holdTime, hold > 0 {
            tags.append(ParameterTag(label: "\(hold)s Halten", color: .phaseInitial))
        }
        if let tempo = exercise.tempo {
            tags.append(ParameterTag(label: "Tempo \(tempo)", color: .painAmber))
        }
        if let intensity = exercise.intensity {
            tags.append(ParameterTag(label: intensity, color: .painRed))
        }
        if let weekRange = exercise.weekRange, weekRange.count >= 2 {
            tags.append(ParameterTag(label: "Woche \(weekRange[0])-\(weekRange[1])", color: .textSecondary))
        }

        return tags
    }
}

// FlowLayout is defined in ExerciseCardView.swift and reused here
