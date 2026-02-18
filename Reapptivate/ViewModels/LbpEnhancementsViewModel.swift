import SwiftUI

@Observable
@MainActor
final class LbpEnhancementsViewModel {
    // MARK: - Dependencies
    private let apiClient: APIClient
    let subtype: AemSubtype

    // MARK: - Fear Hierarchy (FAR)
    var fearHierarchy: FearHierarchy?
    var exposureLogs: [String: [ExposureLog]] = [:] // itemId -> logs

    // MARK: - Pacing Plan (DER/EER)
    var pacingPlan: PacingPlan?
    var pacingTemplate: PacingTemplate?
    var pacingLogs: [PacingLog] = []
    var planAdjustments: [PlanAdjustment] = []
    var quotaSuggestion: QuotaProgressionSuggestion?

    // MARK: - Micro-Modules (All)
    var microModules: [MicroModule] = []
    var completedModuleKeys: Set<String> = []

    // MARK: - UI State
    var isLoading = false
    var errorMessage: String?
    var successMessage: String?

    init(apiClient: APIClient, subtype: AemSubtype) {
        self.apiClient = apiClient
        self.subtype = subtype
    }

    // MARK: - Load All Data

    func loadData() async {
        isLoading = true
        errorMessage = nil

        async let modulesTask: () = loadMicroModules()

        switch subtype {
        case .FAR:
            async let fearTask: () = loadFearHierarchy()
            _ = await (fearTask, modulesTask)
        case .DER, .EER:
            async let pacingTask: () = loadPacingPlan()
            async let logsTask: () = loadPacingLogs()
            _ = await (pacingTask, logsTask, modulesTask)
        case .AR:
            await modulesTask
        }

        isLoading = false
    }

    // MARK: - Fear Hierarchy

    func loadFearHierarchy() async {
        do {
            let response: FearHierarchyResponse = try await apiClient.request(APIEndpoints.fearHierarchy())
            fearHierarchy = response.hierarchy
        } catch {
            if case .notFound = error as? APIError {
                fearHierarchy = nil
            }
            // No hierarchy yet is fine
        }
    }

    func saveFearHierarchy(items: [FearHierarchyItemInput]) async -> Bool {
        do {
            let request = FearHierarchyCreateRequest(items: items)
            let response: FearHierarchyResponse = try await apiClient.request(APIEndpoints.createFearHierarchy(body: request))
            fearHierarchy = response.hierarchy
            successMessage = "Hierarchie gespeichert"
            return true
        } catch {
            errorMessage = "Hierarchie konnte nicht gespeichert werden."
            return false
        }
    }

    func logExposure(itemId: String, request: ExposureLogRequest) async -> Bool {
        do {
            let response: ExposureLogResponse = try await apiClient.request(APIEndpoints.logExposure(itemId: itemId, body: request))
            exposureLogs[itemId, default: []].append(response.log)
            successMessage = "Exposition protokolliert"
            return true
        } catch {
            errorMessage = "Exposition konnte nicht gespeichert werden."
            return false
        }
    }

    func loadExposures(itemId: String) async {
        do {
            let response: ExposureLogsResponse = try await apiClient.request(APIEndpoints.getExposures(itemId: itemId))
            exposureLogs[itemId] = response.logs
        } catch {
            Log.api.error("Failed to load exposures for item \(itemId): \(error.localizedDescription)")
        }
    }

    // MARK: - Pacing Plan

    func loadPacingPlan() async {
        do {
            let response: PacingPlanResponse = try await apiClient.request(APIEndpoints.pacingPlan())
            pacingPlan = response.plan
        } catch {
            pacingPlan = nil
            Log.api.error("Failed to load pacing plan: \(error.localizedDescription)")
        }
    }

    func loadPacingTemplate() async {
        do {
            let response: PacingTemplateResponse = try await apiClient.request(APIEndpoints.pacingTemplate(subtype: subtype.rawValue))
            pacingTemplate = response.template
        } catch {
            errorMessage = "Vorlage konnte nicht geladen werden."
        }
    }

    func activateTemplate() async -> Bool {
        do {
            let response: PacingPlanResponse = try await apiClient.request(APIEndpoints.createPacingPlanFromTemplate())
            pacingPlan = response.plan
            successMessage = "Pacing-Plan aktiviert"
            return true
        } catch {
            errorMessage = "Plan konnte nicht aktiviert werden."
            return false
        }
    }

    func startBaseline() async -> Bool {
        do {
            let response: PacingPlanResponse = try await apiClient.request(APIEndpoints.startBaseline())
            pacingPlan = response.plan
            successMessage = "Baseline-Phase gestartet"
            return true
        } catch {
            errorMessage = "Baseline konnte nicht gestartet werden."
            return false
        }
    }

    func logBaselineActivity(activityKey: String, duration: Int, painLevel: Int) async -> Bool {
        let body: [String: Any] = [
            "activityKey": activityKey,
            "duration": duration,
            "painLevel": painLevel
        ]
        do {
            let response: PacingPlanResponse = try await apiClient.request(APIEndpoints.logBaseline(body: body))
            pacingPlan = response.plan
            successMessage = "Baseline-Aktivität protokolliert"
            return true
        } catch {
            errorMessage = "Aktivität konnte nicht gespeichert werden."
            return false
        }
    }

    func calculateBaseline() async -> Bool {
        do {
            let response: PacingPlanResponse = try await apiClient.request(APIEndpoints.calculateBaseline())
            pacingPlan = response.plan
            successMessage = "Quoten berechnet"
            return true
        } catch {
            errorMessage = "Berechnung fehlgeschlagen."
            return false
        }
    }

    func logPacingActivity(request: PacingLogRequest) async -> Bool {
        do {
            let response: PacingLogFullResponse = try await apiClient.request(APIEndpoints.logPacing(body: request))
            pacingLogs.insert(response.log, at: 0)
            successMessage = "Aktivität protokolliert"
            return true
        } catch {
            errorMessage = "Aktivität konnte nicht gespeichert werden."
            return false
        }
    }

    func loadPacingLogs() async {
        do {
            let response: PacingLogsResponse = try await apiClient.request(APIEndpoints.pacingLogs())
            pacingLogs = response.logs
        } catch {
            pacingLogs = []
            Log.api.error("Failed to load pacing logs: \(error.localizedDescription)")
        }
    }

    func loadQuotaSuggestion() async {
        do {
            quotaSuggestion = try await apiClient.request(APIEndpoints.suggestProgression())
        } catch {
            quotaSuggestion = nil
            Log.api.error("Failed to load quota suggestion: \(error.localizedDescription)")
        }
    }

    func applyProgression() async -> Bool {
        do {
            let response: PacingPlanResponse = try await apiClient.request(APIEndpoints.applyProgression())
            pacingPlan = response.plan
            successMessage = "Quoten angepasst"
            quotaSuggestion = nil
            return true
        } catch {
            errorMessage = "Anpassung fehlgeschlagen."
            return false
        }
    }

    // MARK: - Plan Adjustments

    func loadPlanAdjustments() async {
        do {
            let response: PlanAdjustmentsResponse = try await apiClient.request(APIEndpoints.planAdjustments())
            planAdjustments = response.adjustments
        } catch {
            planAdjustments = []
            Log.api.error("Failed to load plan adjustments: \(error.localizedDescription)")
        }
    }

    // MARK: - Micro-Modules

    func loadMicroModules() async {
        do {
            async let modulesResp: MicroModulesResponse = apiClient.request(APIEndpoints.lbpMicroModules(subtype: subtype.rawValue))
            async let completedResp: CompletedModulesResponse = apiClient.request(APIEndpoints.lbpCompletedModules())

            let (loadedModules, loadedCompleted) = try await (modulesResp, completedResp)

            // Client-side defensive filtering: Only show LBP modules (no targetCondition)
            // Excludes Neck (NECK_PAIN) and Tension (NECK_SHOULDER_TENSION) modules
            microModules = loadedModules.modules.filter { module in
                module.targetCondition == nil || module.targetCondition == "LBP_NONSPECIFIC"
            }

            completedModuleKeys = Set(loadedCompleted.completedModules)
        } catch {
            errorMessage = "Module konnten nicht geladen werden."
            Log.api.error("Failed to load micro-modules: \(error.localizedDescription)")
        }
    }

    func markModuleRead(key: String) async -> Bool {
        do {
            // Start
            let startResponse: ModuleCompletionResponse = try await apiClient.request(APIEndpoints.startLbpModule(key: key))
            // Complete
            let _: [String: Bool] = try await apiClient.request(APIEndpoints.completeLbpModule(completionId: startResponse.completion.id))
            completedModuleKeys.insert(key)
            return true
        } catch {
            errorMessage = "Modul konnte nicht als gelesen markiert werden."
            return false
        }
    }

    // MARK: - Helpers

    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }

    var baselineDaysLogged: Int {
        guard let logs = pacingPlan?.baselineLogs else { return 0 }
        let uniqueDates = Set(logs.map { $0.date })
        return uniqueDates.count
    }

    var isBaselineReady: Bool {
        baselineDaysLogged >= 5
    }
}