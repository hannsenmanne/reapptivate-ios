import SwiftUI

struct NeckMicroModulesView: View {
    @Environment(APIClient.self) private var apiClient
    let severity: NdiSeverityGrade

    @State private var modules: [MicroModule] = []
    @State private var completedKeys: Set<String> = []
    @State private var markingKey: String?
    @State private var isLoading = true

    var completedCount: Int {
        modules.filter { completedKeys.contains($0.key) }.count
    }

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: "book.fill")
                    .font(.appTitle3)
                    .foregroundStyle(Color.severityColor(for: severity))
                Text("Nacken-Wissen")
                    .font(.appHeadline)
                    .foregroundStyle(.textPrimary)
                Spacer()
            }

            // Progress
            if !modules.isEmpty {
                VStack(spacing: 6) {
                    HStack {
                        Text("Fortschritt")
                            .font(.appCaptionMedium)
                            .foregroundStyle(.textSecondary)
                        Spacer()
                        Text("\(completedCount) / \(modules.count)")
                            .font(.appCaptionBold)
                            .foregroundStyle(Color.severityColor(for: severity))
                    }
                    ProgressView(value: Double(completedCount), total: max(1, Double(modules.count)))
                        .tint(Color.severityColor(for: severity))
                }
                .padding(12)
                .background(Color.severityColor(for: severity).opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.smallRadius, style: .continuous))
            }

            if isLoading {
                ProgressView()
                    .padding(.vertical, 16)
            } else if modules.isEmpty {
                Text("Keine Module verfügbar")
                    .font(.appSubheadline)
                    .foregroundStyle(.textSecondary)
                    .padding(.vertical, 16)
            } else {
                ForEach(modules) { module in
                    NeckModuleCard(
                        module: module,
                        isCompleted: completedKeys.contains(module.key),
                        isMarking: markingKey == module.key,
                        onMarkRead: { Task { await markRead(key: module.key) } }
                    )
                }
            }
        }
        .task {
            await loadModules()
        }
    }

    private func loadModules() async {
        isLoading = true
        do {
            async let modsResp: MicroModulesResponse = apiClient.request(APIEndpoints.neckMicroModules(severity: severity.rawValue))
            async let completedResp: CompletedModulesResponse = apiClient.request(APIEndpoints.neckCompletedModules())

            let (loadedModules, loadedCompleted) = try await (modsResp, completedResp)
            modules = loadedModules.modules
            completedKeys = Set(loadedCompleted.completedModules)
        } catch {
            modules = []
        }
        isLoading = false
    }

    private func markRead(key: String) async {
        markingKey = key
        do {
            let start: ModuleCompletionResponse = try await apiClient.request(APIEndpoints.startNeckModule(key: key))
            let _: [String: Bool] = try await apiClient.request(APIEndpoints.completeNeckModule(completionId: start.completion.id))
            completedKeys.insert(key)
        } catch {
            // Silent fail
        }
        markingKey = nil
    }
}

// MARK: - Neck Module Card

struct NeckModuleCard: View {
    let module: MicroModule
    let isCompleted: Bool
    let isMarking: Bool
    let onMarkRead: () -> Void

    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "book.fill")
                        .font(.appCaption)
                        .foregroundStyle(.farBlue)
                        .frame(width: 28, height: 28)
                        .background(Color.farBlue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.smallRadius, style: .continuous))

                    Text(module.title)
                        .font(.appSubheadlineMedium)
                        .foregroundStyle(.textPrimary)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    if isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.painGreen)
                            .font(.appCaption)
                    }

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.appCaption2)
                        .foregroundStyle(.textSecondary)
                }
                .padding(12)
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider().padding(.horizontal, 12)

                VStack(alignment: .leading, spacing: 12) {
                    Text(module.content)
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                        .lineSpacing(3)

                    if let takeHome = module.takeHome, !takeHome.isEmpty {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(.painAmber)
                                .font(.appCaption)
                            Text(takeHome)
                                .font(.appCaption)
                                .foregroundStyle(.textSecondary)
                        }
                        .padding(10)
                        .background(Color.painAmber.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.smallRadius, style: .continuous))
                    }

                    if !isCompleted {
                        Button(action: onMarkRead) {
                            HStack(spacing: 6) {
                                if isMarking {
                                    ProgressView().controlSize(.small).tint(.white)
                                } else {
                                    Image(systemName: "checkmark")
                                    Text("Gelesen")
                                }
                            }
                            .font(.outfit(.semibold, size: 12))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(Color.painGreen)
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.buttonRadius, style: .continuous))
                        }
                        .disabled(isMarking)
                    }
                }
                .padding(12)
            }
        }
        .cardStyle(padding: 0)
    }
}
