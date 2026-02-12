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
    private var completionIds: [String: String] = [:] // moduleKey -> completionId

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
            fearHierarchy = try await apiClient.request(APIEndpoints.fearHierarchy())
        } catch let error as APIError where error == .notFound {
            fearHierarchy = nil
        } catch {
            // No hierarchy yet is fine
        }
    }

    func saveFearHierarchy(items: [FearHierarchyItemInput]) async -> Bool {
        do {
            let request = FearHierarchyCreateRequest(items: items)
            fearHierarchy = try await apiClient.request(APIEndpoints.createFearHierarchy(body: request))
            successMessage = "Hierarchie gespeichert"
            return true
        } catch {
            errorMessage = "Hierarchie konnte nicht gespeichert werden."
            return false
        }
    }

    func logExposure(itemId: String, fearBefore: Int, fearAfter: Int, notes: String?) async -> Bool {
        do {
            let request = ExposureLogRequest(fearBefore: fearBefore, fearAfter: fearAfter, notes: notes)
            let log: ExposureLog = try await apiClient.request(APIEndpoints.logExposure(itemId: itemId, body: request))
            exposureLogs[itemId, default: []].append(log)
            successMessage = "Exposition protokolliert"
            return true
        } catch {
            errorMessage = "Exposition konnte nicht gespeichert werden."
            return false
        }
    }

    func loadExposures(itemId: String) async {
        do {
            let logs: [ExposureLog] = try await apiClient.request(APIEndpoints.getExposures(itemId: itemId))
            exposureLogs[itemId] = logs
        } catch {
            // Silent fail
        }
    }

    // MARK: - Pacing Plan

    func loadPacingPlan() async {
        do {
            pacingPlan = try await apiClient.request(APIEndpoints.pacingPlan())
        } catch {
            pacingPlan = nil
        }
    }

    func loadPacingTemplate() async {
        do {
            pacingTemplate = try await apiClient.request(APIEndpoints.pacingTemplate(subtype: subtype.rawValue))
        } catch {
            errorMessage = "Vorlage konnte nicht geladen werden."
        }
    }

    func activateTemplate() async -> Bool {
        do {
            pacingPlan = try await apiClient.request(APIEndpoints.createPacingPlanFromTemplate())
            successMessage = "Pacing-Plan aktiviert"
            return true
        } catch {
            errorMessage = "Plan konnte nicht aktiviert werden."
            return false
        }
    }

    func startBaseline() async -> Bool {
        do {
            pacingPlan = try await apiClient.request(APIEndpoints.startBaseline())
            successMessage = "Baseline-Phase gestartet"
            return true
        } catch {
            errorMessage = "Baseline konnte nicht gestartet werden."
            return false
        }
    }

    func logBaselineActivity(activityKey: String, duration: Int, painLevel: Int) async -> Bool {
        let body: [String: Any] = [
            "activity_key": activityKey,
            "duration": duration,
            "pain_level": painLevel
        ]
        do {
            pacingPlan = try await apiClient.request(APIEndpoints.logBaseline(body: body))
            successMessage = "Baseline-Aktivitat protokolliert"
            return true
        } catch {
            errorMessage = "Aktivitat konnte nicht gespeichert werden."
            return false
        }
    }

    func calculateBaseline() async -> Bool {
        do {
            pacingPlan = try await apiClient.request(APIEndpoints.calculateBaseline())
            successMessage = "Quoten berechnet"
            return true
        } catch {
            errorMessage = "Berechnung fehlgeschlagen."
            return false
        }
    }

    func logPacingActivity(request: PacingLogRequest) async -> Bool {
        do {
            let log: PacingLog = try await apiClient.request(APIEndpoints.logPacing(body: request))
            pacingLogs.insert(log, at: 0)
            successMessage = "Aktivitat protokolliert"
            return true
        } catch {
            errorMessage = "Aktivitat konnte nicht gespeichert werden."
            return false
        }
    }

    func loadPacingLogs() async {
        do {
            pacingLogs = try await apiClient.request(APIEndpoints.pacingLogs())
        } catch {
            pacingLogs = []
        }
    }

    func loadQuotaSuggestion() async {
        do {
            quotaSuggestion = try await apiClient.request(APIEndpoints.suggestProgression())
        } catch {
            quotaSuggestion = nil
        }
    }

    func applyProgression() async -> Bool {
        do {
            pacingPlan = try await apiClient.request(APIEndpoints.applyProgression())
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
            planAdjustments = try await apiClient.request(APIEndpoints.planAdjustments())
        } catch {
            planAdjustments = []
        }
    }

    // MARK: - Micro-Modules

    func loadMicroModules() async {
        do {
            async let modules: [MicroModule] = apiClient.request(APIEndpoints.lbpMicroModules(subtype: subtype.rawValue))
            async let completions: [MicroModuleCompletion] = apiClient.request(APIEndpoints.lbpCompletedModules())

            let (loadedModules, loadedCompletions) = try await (modules, completions)
            microModules = loadedModules
            completedModuleKeys = Set(loadedCompletions.compactMap { $0.completedAt != nil ? $0.moduleKey : nil })
            completionIds = Dictionary(loadedCompletions.map { ($0.moduleKey, $0.id) }, uniquingKeysWith: { _, last in last })
        } catch {
            // Silent fail for modules
        }
    }

    func markModuleRead(key: String) async -> Bool {
        do {
            // Start
            let startResponse: MicroModuleCompletion = try await apiClient.request(APIEndpoints.startLbpModule(key: key))
            // Complete
            let _: MicroModuleCompletion = try await apiClient.request(APIEndpoints.completeLbpModule(completionId: startResponse.id))
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

// MARK: - APIError Equatable helper
extension APIError: Equatable {
    static func == (lhs: APIError, rhs: APIError) -> Bool {
        switch (lhs, rhs) {
        case (.notFound, .notFound): return true
        case (.unauthorized, .unauthorized): return true
        case (.forbidden, .forbidden): return true
        default: return false
        }
    }
}
