import SwiftUI

struct MicroModulesList: View {
    @Bindable var viewModel: LbpEnhancementsViewModel
    @State private var markingReadKey: String?

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
                    .font(.title3)
                    .foregroundStyle(.farBlue)
                Text("Psychoedukation & Module")
                    .font(.headline)
                    .foregroundStyle(.textPrimary)
                Spacer()
            }

            // Progress card
            VStack(spacing: 8) {
                HStack {
                    Text("Fortschritt")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.textSecondary)
                    Spacer()
                    Text("\(completedCount) / \(totalCount) Module")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.farBlue)
                }

                ProgressView(value: Double(completedCount), total: max(1, Double(totalCount)))
                    .tint(.farBlue)

                Text("\(progressPercent)% abgeschlossen")
                    .font(.caption2)
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
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Module cards
            if viewModel.microModules.isEmpty {
                VStack(spacing: 8) {
                    Text("Keine Module verfugbar")
                        .font(.subheadline)
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
    }

    private func markRead(key: String) async {
        markingReadKey = key
        _ = await viewModel.markModuleRead(key: key)
        markingReadKey = nil
    }
}
