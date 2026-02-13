import SwiftUI

struct MicroModulesList: View {
    @Bindable var viewModel: LbpEnhancementsViewModel
    @State private var markingReadKey: String?
    @State private var markReadTrigger = false

    var completedCount: Int {
        viewModel.microModules.filter { viewModel.completedModuleKeys.contains($0.key) }.count
    }

    var totalCount: Int {
        viewModel.microModules.count
    }

    var progressPercent: Int {
        guard totalCount > 0 else { return 0 }
        return Int(Double(completedCount) / Double(totalCount) * 100)
    }

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: "book.fill")
                    .font(.appTitle3)
                    .foregroundStyle(.farBlue)
                Text("Psychoedukation & Module")
                    .font(.appHeadline)
                    .foregroundStyle(.textPrimary)
                Spacer()
            }

            // Progress card
            VStack(spacing: 8) {
                HStack {
                    Text("Fortschritt")
                        .font(.appCaptionMedium)
                        .foregroundStyle(.textSecondary)
                    Spacer()
                    Text("\(completedCount) / \(totalCount) Module")
                        .font(.appCaptionBold)
                        .foregroundStyle(.farBlue)
                }

                ProgressView(value: Double(completedCount), total: max(1, Double(totalCount)))
                    .tint(.farBlue)

                Text("\(progressPercent)% abgeschlossen")
                    .font(.appCaption2)
                    .foregroundStyle(.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(14)
            .background(
                LinearGradient(
                    colors: [Color.farBlue.opacity(0.08), Color.farBlue.opacity(0.02)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cardRadius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: DesignTokens.cardRadius, style: .continuous).stroke(Color.gray200, lineWidth: 1))

            // Module cards
            if viewModel.microModules.isEmpty {
                VStack(spacing: 8) {
                    Text("Keine Module verfügbar")
                        .font(.appSubheadline)
                        .foregroundStyle(.textSecondary)
                }
                .padding(.vertical, 16)
            } else {
                ForEach(viewModel.microModules) { module in
                    MicroModuleCard(
                        module: module,
                        isCompleted: viewModel.completedModuleKeys.contains(module.key),
                        isMarking: markingReadKey == module.key,
                        onMarkRead: {
                            Task { await markRead(key: module.key) }
                        }
                    )
                }
            }
        }
        .sensoryFeedback(.success, trigger: markReadTrigger)
    }

    private func markRead(key: String) async {
        markingReadKey = key
        let success = await viewModel.markModuleRead(key: key)
        if success {
            markReadTrigger.toggle()
        }
        markingReadKey = nil
    }
}
