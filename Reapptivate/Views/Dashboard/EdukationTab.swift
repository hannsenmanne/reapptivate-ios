import SwiftUI

struct EdukationTab: View {
    @Environment(AppState.self) private var appState
    @Environment(APIClient.self) private var apiClient

    @AppStorage("appLanguage") private var appLanguage = "de"

    var body: some View {
        VStack(spacing: 20) {
            if appState.isLbp, let subtype = appState.currentUser?.aemSubtype {
                LbpMicroModulesSection(subtype: subtype)

                if let user = appState.currentUser {
                    WissenAllCardsView(phase: user.currentPhase, isLbp: true, isNeck: false)
                }
            } else if appState.isNeck {
                if let severity = appState.currentUser?.ndiSeverity {
                    NeckMicroModulesView(severity: severity)
                } else {
                    ProgressView(appLanguage == "en" ? "Loading neck modules..." : "Nacken-Module laden...")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                }

                if let user = appState.currentUser {
                    WissenAllCardsView(phase: user.currentPhase, isLbp: false, isNeck: true)
                }
            } else if appState.isTension {
                if let severity = appState.currentUser?.tsiSeverity {
                    TensionMicroModulesView(severity: severity)
                } else {
                    ProgressView(appLanguage == "en" ? "Loading tension modules..." : "Verspannungs-Module laden...")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                }

                if let user = appState.currentUser {
                    WissenAllCardsView(phase: user.currentPhase, isLbp: false, isNeck: false, isTension: true)
                }
            } else if appState.isShoulder {
                if let severity = appState.currentUser?.siSeverity {
                    ShoulderMicroModulesView(severity: severity)
                } else {
                    ProgressView(appLanguage == "en" ? "Loading shoulder modules..." : "Schulter-Module laden...")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                }
            } else if appState.isFrozenShoulder {
                if let severity = appState.currentUser?.fsSeverity {
                    FrozenShoulderMicroModulesView(severity: severity)
                } else {
                    ProgressView(appLanguage == "en" ? "Loading frozen shoulder modules..." : "Frozen Shoulder-Module laden...")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                }
            } else if appState.isLateralAnkleSprain {
                if let severity = appState.currentUser?.lasSeverity {
                    LateralAnkleSprainMicroModulesView(severity: severity)
                } else {
                    ProgressView(appLanguage == "en" ? "Loading ankle modules..." : "Sprunggelenk-Module laden...")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                }
            } else if appState.isAcl {
                AclMicroModulesView(currentMilestone: appState.currentUser?.aclCurrentMilestone ?? 0)
            } else if let user = appState.currentUser {
                WissenAllCardsView(phase: user.currentPhase, isLbp: false, isNeck: false)
            }
        }
        .padding(.bottom, 32)
    }
}

// MARK: - LBP Micro Modules Section

struct LbpMicroModulesSection: View {
    @Environment(APIClient.self) private var apiClient
    @Environment(LanguageManager.self) private var languageManager
    let subtype: AemSubtype

    @AppStorage("appLanguage") private var appLanguage = "de"

    @State private var viewModel: LbpEnhancementsViewModel?

    var body: some View {
        Group {
            if let vm = viewModel {
                if let error = vm.errorMessage, vm.microModules.isEmpty {
                    InlineErrorView(
                        message: error,
                        errorType: .network,
                        onRetry: {
                            Task {
                                vm.errorMessage = nil
                                await vm.loadMicroModules()
                            }
                        }
                    )
                } else {
                    MicroModulesList(viewModel: vm)
                }
            } else {
                ProgressView(appLanguage == "en" ? "Loading modules..." : "Module laden...")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
        }
        .task {
            if viewModel == nil {
                let vm = LbpEnhancementsViewModel(apiClient: apiClient, subtype: subtype)
                viewModel = vm
                await vm.loadMicroModules()
            }
        }
        .onChange(of: languageManager.language) { _, _ in
            viewModel = nil
            Task {
                let vm = LbpEnhancementsViewModel(apiClient: apiClient, subtype: subtype)
                viewModel = vm
                await vm.loadMicroModules()
            }
        }
    }
}

// MARK: - All Wissen Cards

struct WissenAllCardsView: View {
    let phase: Int
    let isLbp: Bool
    let isNeck: Bool
    var isTension: Bool = false

    @AppStorage("appLanguage") private var appLanguage = "de"
    @AppStorage("readEducationCardIds") private var readCardIdsData: Data = Data()
    @State private var cachedReadCardIds: Set<String> = []

    private var cards: [EducationCard] {
        EducationCardLoader.shared.cardsForPhase(phase, isLbp: isLbp, isNeck: isNeck, isTension: isTension)
    }

    private var readCount: Int {
        cards.filter { cachedReadCardIds.contains($0.id) }.count
    }

    private func markRead(_ cardId: String) {
        cachedReadCardIds.insert(cardId)
        readCardIdsData = (try? JSONEncoder().encode(cachedReadCardIds)) ?? Data()
    }

    private static func decodeIds(from data: Data) -> Set<String> {
        (try? JSONDecoder().decode(Set<String>.self, from: data)) ?? []
    }

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: "book.fill")
                    .font(.appTitle3)
                    .foregroundStyle(.accent)
                Text(appLanguage == "en" ? "Knowledge" : "Wissen")
                    .font(.appHeadline)
                    .foregroundStyle(.textPrimary)
                Spacer()
                Text(appLanguage == "en" ? "\(readCount)/\(cards.count) read" : "\(readCount)/\(cards.count) gelesen")
                    .font(.appCaptionMedium)
                    .foregroundStyle(.textSecondary)
            }

            // Progress bar
            if !cards.isEmpty {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: DesignTokens.progressBarRadius)
                            .fill(Color.textSecondary.opacity(0.15))
                            .frame(height: 4)
                        RoundedRectangle(cornerRadius: DesignTokens.progressBarRadius)
                            .fill(Color.accent)
                            .frame(width: cards.isEmpty ? 0 : geo.size.width * CGFloat(readCount) / CGFloat(cards.count), height: 4)
                    }
                }
                .frame(height: 4)
            }

            if cards.isEmpty {
                Text(appLanguage == "en" ? "No articles available for this phase" : "Keine Artikel für diese Phase verfügbar")
                    .font(.appSubheadline)
                    .foregroundStyle(.textSecondary)
                    .padding(.vertical, 16)
            } else {
                ForEach(cards) { card in
                    WissenExpandableCard(
                        card: card,
                        isRead: cachedReadCardIds.contains(card.id),
                        onMarkRead: { markRead(card.id) }
                    )
                }
            }
        }
        .onAppear {
            cachedReadCardIds = Self.decodeIds(from: readCardIdsData)
        }
        .onChange(of: readCardIdsData) { _, newValue in
            cachedReadCardIds = Self.decodeIds(from: newValue)
        }
    }
}

struct WissenExpandableCard: View {
    let card: EducationCard
    let isRead: Bool
    let onMarkRead: () -> Void

    @AppStorage("appLanguage") private var appLanguage = "de"
    @State private var isExpanded = false
    @State private var hapticTrigger = false

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: iconName(for: card.icon))
                        .font(.appSubheadline)
                        .foregroundStyle(.accent)
                        .frame(width: 32, height: 32)
                        .background(Color.accent.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.iconRadius, style: .continuous))

                    Text(card.title)
                        .font(.appSubheadlineMedium)
                        .foregroundStyle(.textPrimary)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    if isRead {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.appSubheadline)
                            .foregroundStyle(.painGreen)
                    }

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                }
                .padding(14)
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider()
                    .padding(.horizontal, 14)

                VStack(alignment: .leading, spacing: 12) {
                    Text(card.body)
                        .font(.appSubheadline)
                        .foregroundStyle(.textSecondary)
                        .lineSpacing(4)

                    if let source = card.source {
                        Text(appLanguage == "en" ? "Source: \(source)" : "Quelle: \(source)")
                            .font(.appCaption2)
                            .foregroundStyle(.textSecondary.opacity(0.7))
                    }

                    if !isRead {
                        Button {
                            onMarkRead()
                            hapticTrigger.toggle()
                        } label: {
                            Text(appLanguage == "en" ? "Read" : "Gelesen")
                                .font(.appCaptionMedium)
                        }
                        .buttonStyle(.secondary)
                    }
                }
                .padding(14)
            }
        }
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cardRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: DesignTokens.cardRadius, style: .continuous).stroke(Color.gray200, lineWidth: 1))
        .conditionalHaptic(.success, trigger: hapticTrigger)
    }

    private func iconName(for icon: String) -> String {
        switch icon {
        case "biology": "flask"
        case "pain": "lightbulb"
        case "loading": "bolt"
        case "recovery": "arrow.2.circlepath"
        case "progress": "chart.line.uptrend.xyaxis"
        default: "book"
        }
    }
}
