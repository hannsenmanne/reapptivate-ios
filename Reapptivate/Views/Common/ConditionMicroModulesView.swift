import SwiftUI

// MARK: - Configuration

/// Configuration for condition-specific micro-modules views.
/// Each condition provides its own config with localized strings and API endpoints.
struct MicroModulesConfig {
    let titleEN: String
    let titleDE: String
    let loadingEN: String
    let loadingDE: String
    let targetCondition: String
    let accentColor: Color

    /// API endpoint closures — each condition maps to its own route
    let fetchModules: @Sendable (APIClient) async throws -> MicroModulesResponse
    let fetchCompleted: @Sendable (APIClient) async throws -> CompletedModulesResponse
    let startModule: @Sendable (APIClient, String) async throws -> ModuleCompletionResponse
    let completeModule: @Sendable (APIClient, String) async throws -> [String: Bool]
}

// MARK: - Condition Configs

extension MicroModulesConfig {
    static func neck(severity: NdiSeverityGrade) -> MicroModulesConfig {
        MicroModulesConfig(
            titleEN: "Neck Knowledge", titleDE: "Nacken-Wissen",
            loadingEN: "Loading neck modules...", loadingDE: "Nacken-Module laden...",
            targetCondition: "NECK_PAIN",
            accentColor: Color.severityColor(for: severity),
            fetchModules: { try await $0.request(APIEndpoints.neckMicroModules(severity: severity.rawValue)) },
            fetchCompleted: { try await $0.request(APIEndpoints.neckCompletedModules()) },
            startModule: { api, key in try await api.request(APIEndpoints.startNeckModule(key: key)) },
            completeModule: { api, id in try await api.request(APIEndpoints.completeNeckModule(completionId: id)) }
        )
    }

    static func tension(severity: TsiSeverityGrade) -> MicroModulesConfig {
        MicroModulesConfig(
            titleEN: "Tension Knowledge", titleDE: "Verspannungs-Wissen",
            loadingEN: "Loading tension modules...", loadingDE: "Verspannungs-Module laden...",
            targetCondition: "NECK_SHOULDER_TENSION",
            accentColor: Color.severityColor(for: severity),
            fetchModules: { try await $0.request(APIEndpoints.tensionMicroModules(severity: severity.rawValue)) },
            fetchCompleted: { try await $0.request(APIEndpoints.tensionCompletedModules()) },
            startModule: { api, key in try await api.request(APIEndpoints.startTensionModule(key: key)) },
            completeModule: { api, id in try await api.request(APIEndpoints.completeTensionModule(completionId: id)) }
        )
    }

    static func shoulder(severity: SiSeverityGrade) -> MicroModulesConfig {
        MicroModulesConfig(
            titleEN: "Shoulder Knowledge", titleDE: "Schulter-Wissen",
            loadingEN: "Loading shoulder modules...", loadingDE: "Schulter-Module laden...",
            targetCondition: "SHOULDER_IMPINGEMENT",
            accentColor: Color.severityColor(for: severity),
            fetchModules: { try await $0.request(APIEndpoints.siMicroModules(severity: severity.rawValue)) },
            fetchCompleted: { try await $0.request(APIEndpoints.siCompletedModules()) },
            startModule: { api, key in try await api.request(APIEndpoints.startSiModule(key: key)) },
            completeModule: { api, id in try await api.request(APIEndpoints.completeSiModule(completionId: id)) }
        )
    }

    static func frozenShoulder(severity: FsSeverityGrade) -> MicroModulesConfig {
        MicroModulesConfig(
            titleEN: "Frozen Shoulder Knowledge", titleDE: "Frozen Shoulder-Wissen",
            loadingEN: "Loading frozen shoulder modules...", loadingDE: "Frozen Shoulder-Module laden...",
            targetCondition: "FROZEN_SHOULDER",
            accentColor: Color.severityColor(for: severity),
            fetchModules: { try await $0.request(APIEndpoints.fsMicroModules(severity: severity.rawValue)) },
            fetchCompleted: { try await $0.request(APIEndpoints.fsCompletedModules()) },
            startModule: { api, key in try await api.request(APIEndpoints.startFsModule(key: key)) },
            completeModule: { api, id in try await api.request(APIEndpoints.completeFsModule(completionId: id)) }
        )
    }

    static func lateralAnkleSprain(severity: LasSeverityGrade) -> MicroModulesConfig {
        MicroModulesConfig(
            titleEN: "Ankle Knowledge", titleDE: "Sprunggelenk-Wissen",
            loadingEN: "Loading ankle modules...", loadingDE: "Sprunggelenk-Module laden...",
            targetCondition: "LATERAL_ANKLE_SPRAIN",
            accentColor: Color.severityColor(for: severity),
            fetchModules: { try await $0.request(APIEndpoints.lasMicroModules(severity: severity.rawValue)) },
            fetchCompleted: { try await $0.request(APIEndpoints.lasCompletedModules()) },
            startModule: { api, key in try await api.request(APIEndpoints.startLasModule(key: key)) },
            completeModule: { api, id in try await api.request(APIEndpoints.completeLasModule(completionId: id)) }
        )
    }
}

// MARK: - Generic Micro Modules View

struct ConditionMicroModulesView: View {
    @Environment(APIClient.self) private var apiClient
    @Environment(LanguageManager.self) private var languageManager
    let config: MicroModulesConfig

    @AppStorage("appLanguage") private var appLanguage = "de"

    @State private var modules: [MicroModule] = []
    @State private var completedKeys: Set<String> = []
    @State private var markingKey: String?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var markReadError: String?
    @State private var markReadTrigger = false

    private var isEn: Bool { appLanguage == "en" }

    var completedCount: Int {
        modules.filter { completedKeys.contains($0.key) }.count
    }

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: "book.fill")
                    .font(.appTitle3)
                    .foregroundStyle(config.accentColor)
                    .accessibilityHidden(true)
                Text(isEn ? config.titleEN : config.titleDE)
                    .font(.appHeadline)
                    .foregroundStyle(.textPrimary)
                Spacer()
            }

            // Progress
            if !modules.isEmpty {
                VStack(spacing: 6) {
                    HStack {
                        Text(isEn ? "Progress" : "Fortschritt")
                            .font(.appCaptionMedium)
                            .foregroundStyle(.textSecondary)
                        Spacer()
                        Text("\(completedCount) / \(modules.count)")
                            .font(.appCaptionBold)
                            .foregroundStyle(config.accentColor)
                    }
                    ProgressView(value: Double(completedCount), total: max(1, Double(modules.count)))
                        .tint(config.accentColor)
                        .accessibilityLabel(isEn ? "Module progress" : "Modulfortschritt")
                        .accessibilityValue(isEn ? "\(completedCount) of \(modules.count) completed" : "\(completedCount) von \(modules.count) abgeschlossen")
                }
                .padding(12)
                .background(config.accentColor.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.smallRadius, style: .continuous))
            }

            if let markError = markReadError {
                InlineErrorView(
                    message: markError,
                    errorType: .server,
                    onDismiss: { markReadError = nil }
                )
            }

            if isLoading {
                ProgressView(isEn ? config.loadingEN : config.loadingDE)
                    .padding(.vertical, 16)
            } else if let error = errorMessage {
                InlineErrorView(
                    message: error,
                    errorType: .network,
                    onRetry: { Task { await loadModules() } }
                )
            } else if modules.isEmpty {
                Text(isEn ? "No modules available" : "Keine Module verfügbar")
                    .font(.appSubheadline)
                    .foregroundStyle(.textSecondary)
                    .padding(.vertical, 16)
            } else {
                ForEach(modules) { module in
                    ConditionModuleCard(
                        module: module,
                        isCompleted: completedKeys.contains(module.key),
                        isMarking: markingKey == module.key,
                        onMarkRead: { Task { await markRead(key: module.key) } }
                    )
                }
            }
        }
        .conditionalHaptic(.success, trigger: markReadTrigger)
        .task {
            await loadModules()
        }
        .onChange(of: languageManager.language) { _, _ in
            modules = []
            completedKeys = []
            Task { await loadModules() }
        }
    }

    private func loadModules() async {
        isLoading = true
        errorMessage = nil
        do {
            async let modsResp = config.fetchModules(apiClient)
            async let completedResp = config.fetchCompleted(apiClient)

            let (loadedModules, loadedCompleted) = try await (modsResp, completedResp)

            // Client-side defensive filtering: only show modules for this condition
            modules = loadedModules.modules.filter { module in
                module.targetCondition == nil || module.targetCondition == config.targetCondition
            }
            completedKeys = Set(loadedCompleted.completedModules ?? [])
        } catch {
            errorMessage = isEn ? "Could not load modules." : "Module konnten nicht geladen werden."
        }
        isLoading = false
    }

    private func markRead(key: String) async {
        markingKey = key
        markReadError = nil
        do {
            let start = try await config.startModule(apiClient, key)
            let _ = try await config.completeModule(apiClient, start.completion.id)
            completedKeys.insert(key)
            markReadTrigger.toggle()
        } catch {
            markReadError = isEn ? "Error saving. Please try again." : "Fehler beim Speichern. Bitte erneut versuchen."
        }
        markingKey = nil
    }
}

// MARK: - Shared Module Card

struct ConditionModuleCard: View {
    let module: MicroModule
    let isCompleted: Bool
    let isMarking: Bool
    let onMarkRead: () -> Void

    @AppStorage("appLanguage") private var appLanguage = "de"
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    GlowingIconContainer(
                        icon: "book.fill",
                        color: .farBlue,
                        size: 28,
                        iconSize: 12,
                        radius: DesignTokens.smallRadius,
                        isFilled: false
                    )
                    .accessibilityHidden(true)

                    Text(module.title)
                        .font(.appSubheadlineMedium)
                        .foregroundStyle(.textPrimary)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    if isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.painGreen)
                            .font(.appCaption)
                            .accessibilityLabel(appLanguage == "en" ? "Completed" : "Abgeschlossen")
                    }

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.appCaption2)
                        .foregroundStyle(.textSecondary)
                        .accessibilityHidden(true)
                }
                .padding(12)
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider().padding(.horizontal, 12)

                VStack(alignment: .leading, spacing: 12) {
                    MarkdownContentView(module.content, font: .appCaption)

                    if let takeHome = module.takeHome, !takeHome.isEmpty {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(.painAmber)
                                .font(.appCaption)
                                .accessibilityHidden(true)
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
                                    Text(appLanguage == "en" ? "Read" : "Gelesen")
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
