import SwiftUI

struct EdukationTab: View {
    @Environment(AppState.self) private var appState
    @Environment(APIClient.self) private var apiClient

    var body: some View {
        VStack(spacing: 20) {
            if appState.isLbp, let subtype = appState.currentUser?.aemSubtype {
                LbpMicroModulesSection(subtype: subtype)
            } else if appState.isNeck, let severity = appState.currentUser?.ndiSeverity {
                NeckMicroModulesView(severity: severity)
            } else if let user = appState.currentUser {
                WissenAllCardsView(phase: user.currentPhase)
            }
        }
        .padding(.bottom, 32)
    }
}

// MARK: - LBP Micro Modules Section

struct LbpMicroModulesSection: View {
    @Environment(APIClient.self) private var apiClient
    let subtype: AemSubtype

    @State private var viewModel: LbpEnhancementsViewModel?

    var body: some View {
        Group {
            if let vm = viewModel {
                MicroModulesList(viewModel: vm)
            } else {
                ProgressView()
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
    }
}

// MARK: - All Wissen Cards (Tendinopathy)

struct WissenAllCardsView: View {
    let phase: Int

    private var cards: [EducationCard] {
        EducationCardLoader.shared.cardsForPhase(phase, isLbp: false)
    }

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: "book.fill")
                    .font(.appTitle3)
                    .foregroundStyle(.accent)
                Text("Wissen")
                    .font(.appHeadline)
                    .foregroundStyle(.textPrimary)
                Spacer()
                Text("\(cards.count) Artikel")
                    .font(.appCaptionMedium)
                    .foregroundStyle(.textSecondary)
            }

            if cards.isEmpty {
                Text("Keine Artikel fur diese Phase verfugbar")
                    .font(.appSubheadline)
                    .foregroundStyle(.textSecondary)
                    .padding(.vertical, 16)
            } else {
                ForEach(cards) { card in
                    WissenExpandableCard(card: card)
                }
            }
        }
    }
}

struct WissenExpandableCard: View {
    let card: EducationCard
    @State private var isExpanded = false

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
                        Text("Quelle: \(source)")
                            .font(.appCaption2)
                            .foregroundStyle(.textSecondary.opacity(0.7))
                    }
                }
                .padding(14)
            }
        }
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cardRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: DesignTokens.cardRadius, style: .continuous).stroke(Color.gray200, lineWidth: 1))
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
