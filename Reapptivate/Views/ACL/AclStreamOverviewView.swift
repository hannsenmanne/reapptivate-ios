import SwiftUI

struct AclStreamOverviewView: View {
    @Environment(APIClient.self) private var apiClient

    @State private var streams: [AclStream] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var hapticTrigger = false

    var body: some View {
        VStack(spacing: 20) {
            if isLoading {
                streamSkeletons
            } else if let error = errorMessage {
                InlineErrorView(
                    message: error,
                    errorType: .network,
                    onRetry: { Task { await loadStreams() } }
                )
            } else if streams.isEmpty {
                EmptyStateView(
                    icon: "figure.strengthtraining.traditional",
                    title: "Keine Streams",
                    message: "Trainings-Streams werden nach dem Screening freigeschaltet."
                )
            } else {
                streamContent
            }
        }
        .padding(.bottom, 32)
        .task {
            await loadStreams()
        }
        .sensoryFeedback(.selection, trigger: hapticTrigger)
    }

    @ViewBuilder
    private var streamContent: some View {
        // Header
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Trainings-Streams")
                    .font(.appHeadline)
                    .foregroundStyle(.textPrimary)
                Text("\(streams.filter { $0.locked != true }.count) von \(streams.count) freigeschaltet")
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
            }
            Spacer()
        }
        .cardEntryAnimation(index: 0)

        // Stream cards
        ForEach(Array(streams.enumerated()), id: \.element.id) { index, stream in
            let isLocked = stream.locked == true

            if isLocked {
                AclStreamCard(stream: stream, isLocked: true)
                    .cardEntryAnimation(index: index + 1)
            } else {
                NavigationLink {
                    AclStreamDetailView(streamId: stream.id)
                } label: {
                    AclStreamCard(stream: stream, isLocked: false)
                }
                .buttonStyle(.plain)
                .simultaneousGesture(TapGesture().onEnded { hapticTrigger.toggle() })
                .cardEntryAnimation(index: index + 1)
            }
        }
    }

    private var streamSkeletons: some View {
        VStack(spacing: 12) {
            ForEach(0..<5, id: \.self) { _ in
                SkeletonView(variant: .card(height: 100))
            }
        }
    }

    private func loadStreams() async {
        isLoading = true
        errorMessage = nil

        do {
            let response: AclStreamsResponse = try await apiClient.request(
                APIEndpoints.aclStreams()
            )
            streams = response.streams
        } catch {
            errorMessage = "Streams konnten nicht geladen werden."
        }

        isLoading = false
    }
}

// MARK: - Stream Card

struct AclStreamCard: View {
    let stream: AclStream
    let isLocked: Bool
    @AppStorage("appLanguage") private var appLanguage = "de"

    @ScaledMetric(relativeTo: .body) private var iconContainerSize: CGFloat = 40

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: DesignTokens.iconRadius, style: .continuous)
                .fill(isLocked ? Color.gray300 : Color.accent)
                .frame(width: iconContainerSize, height: iconContainerSize)
                .overlay {
                    Image(systemName: isLocked ? "lock.fill" : aclStreamIcon(for: stream.id))
                        .font(.appSubheadline)
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(stream.nameDE ?? stream.name)
                        .font(.appSubheadlineSemibold)
                        .foregroundStyle(isLocked ? .textTertiary : .textPrimary)

                    if let milestone = stream.milestone ?? stream.unlockMilestone {
                        Text("M\(milestone)")
                            .font(.appCaption2)
                            .foregroundStyle(isLocked ? .textTertiary : .accent)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                (isLocked ? Color.gray200 : Color.accent.opacity(0.1))
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    }
                }

                if let desc = stream.descriptionDE ?? stream.description {
                    Text(desc)
                        .font(.appCaption)
                        .foregroundStyle(isLocked ? .textTertiary : .textSecondary)
                        .lineLimit(2)
                }

                Text(appLanguage == "en"
                    ? "\(stream.exerciseCount ?? 0) exercise\((stream.exerciseCount ?? 0) == 1 ? "" : "s")"
                    : "\(stream.exerciseCount ?? 0) Übungen")
                    .font(.appCaption2)
                    .foregroundStyle(isLocked ? .textTertiary : .accent)
            }

            Spacer()

            if !isLocked {
                Image(systemName: "chevron.right")
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
            }
        }
        .cardStyle()
        .opacity(isLocked ? 0.7 : 1.0)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(streamAccessibilityLabel)
    }

    private var streamAccessibilityLabel: String {
        let name = stream.nameDE ?? stream.name
        let exerciseCount = stream.exerciseCount ?? 0
        let isEn = appLanguage == "en"
        let exerciseWord = isEn
            ? "\(exerciseCount) exercise\(exerciseCount == 1 ? "" : "s")"
            : "\(exerciseCount) Übungen"
        if isLocked {
            let milestone = stream.milestone ?? stream.unlockMilestone
            let unlockInfo = milestone.map {
                isEn ? "Unlocks at milestone \($0)." : "Wird ab Meilenstein \($0) freigeschaltet."
            } ?? ""
            return isEn
                ? "\(name), locked, \(exerciseWord). \(unlockInfo)"
                : "\(name), gesperrt, \(exerciseWord). \(unlockInfo)"
        }
        return "\(name), \(exerciseWord)"
    }
}

// MARK: - Shared Stream Icon Helper

func aclStreamIcon(for streamId: String) -> String {
    switch streamId {
    case let id where id.contains("CLINICAL"), let id where id.contains("ROM"):
        "figure.walk"
    case let id where id.contains("MOTOR_CONTROL"):
        "figure.mind.and.body"
    case let id where id.contains("REACTIVE"), let id where id.contains("PLYO"), let id where id.contains("AGILITY"):
        "figure.jumprope"
    case let id where id.contains("EXPLOSIVE"):
        "bolt.fill"
    case let id where id.contains("CHANGE_OF_DIRECTION"):
        "arrow.triangle.swap"
    case let id where id.contains("CONDITIONING"):
        "heart.circle"
    case let id where id.contains("STRENGTH"):
        "figure.strengthtraining.functional"
    case let id where id.contains("RUNNING"):
        "figure.run"
    case let id where id.contains("BALANCE"), let id where id.contains("NEURO"):
        "figure.cooldown"
    case let id where id.contains("SPORT"):
        "sportscourt"
    default:
        "figure.strengthtraining.traditional"
    }
}
