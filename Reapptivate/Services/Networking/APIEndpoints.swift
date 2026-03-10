import Foundation

enum APIEndpoints {
    #if DEBUG
    static let baseURL = URL(string: "http://localhost:3000/api")!
    #else
    static let baseURL = URL(string: "https://physio-app-server-production.up.railway.app/api")!
    #endif

    // MARK: - Auth & Onboarding

    static func login(email: String, password: String) -> URLRequest {
        post("onboarding/login", body: ["email": email, "password": password])
    }

    static func validateToken(_ token: String) -> URLRequest {
        get("onboarding/\(token)/validate")
    }

    static func completeOnboarding(token: String, body: [String: Any]) -> URLRequest {
        post("onboarding/\(token)/complete", body: body)
    }

    // MARK: - Patient Profile

    static func me() -> URLRequest {
        get("patient/me")
    }

    // MARK: - Account Deletion

    static func deleteAccount() -> URLRequest {
        delete("patient/account")
    }

    // MARK: - Schedule

    static func getSchedule() -> URLRequest {
        get("patient/schedule")
    }

    static func updateSchedule(body: ScheduleUpdateRequest) -> URLRequest {
        put("patient/schedule", encodable: body)
    }

    // MARK: - Progress

    static func logProgress(body: ProgressLogRequest) -> URLRequest {
        post("patient/progress", encodable: body)
    }

    static func getProgress(limit: Int = 20, offset: Int = 0) -> URLRequest {
        get("patient/progress", query: ["limit": "\(limit)", "offset": "\(offset)"])
    }

    static func getProgressStats() -> URLRequest {
        get("patient/progress/stats")
    }

    static func getTodayProgress() -> URLRequest {
        get("patient/progress/today")
    }

    // MARK: - Phase Adaptation

    static func phaseStatus() -> URLRequest {
        get("patient/phase-status")
    }

    static func phaseHistory() -> URLRequest {
        get("patient/phase-history")
    }

    // MARK: - Education

    static func education() -> URLRequest {
        get("patient/education")
    }

    // MARK: - AEM Screening

    static func aemConfig() -> URLRequest {
        get("aem/config")
    }

    static func submitAemScreening(body: AemScreeningSubmission) -> URLRequest {
        post("aem/screening", encodable: body)
    }

    static func aemResult() -> URLRequest {
        get("aem/result")
    }

    // MARK: - Neck Screening

    static func neckConfig() -> URLRequest {
        get("neck/config")
    }

    static func submitNeckScreening(body: NeckScreeningSubmission) -> URLRequest {
        post("neck/screening", encodable: body)
    }

    static func neckResult() -> URLRequest {
        get("neck/result")
    }

    static func neckHistory() -> URLRequest {
        get("neck/history")
    }

    static func neckFocusAreas() -> URLRequest {
        get("neck/focus-areas")
    }

    static func submitNeckRescreening(body: NeckScreeningSubmission) -> URLRequest {
        post("neck/rescreening", encodable: body)
    }

    static func neckMicroModules(severity: String? = nil) -> URLRequest {
        var query: [String: String] = [:]
        if let severity { query["severity"] = severity }
        return get("neck/micro-modules", query: query)
    }

    static func neckCompletedModules() -> URLRequest {
        get("neck/micro-modules/completed")
    }

    static func startNeckModule(key: String) -> URLRequest {
        post("neck/micro-modules/\(key)/start")
    }

    static func completeNeckModule(completionId: String) -> URLRequest {
        post("neck/micro-modules/\(completionId)/complete")
    }

    // MARK: - Tension Screening

    static func tensionConfig() -> URLRequest {
        get("tension/config")
    }

    static func submitTsiScreening(body: TsiScreeningSubmission) -> URLRequest {
        post("tension/screening", encodable: body)
    }

    static func tensionResult() -> URLRequest {
        get("tension/result")
    }

    static func tensionHistory() -> URLRequest {
        get("tension/history")
    }

    static func tensionFocusAreas() -> URLRequest {
        get("tension/focus-areas")
    }

    static func submitTsiRescreening(body: TsiScreeningSubmission) -> URLRequest {
        post("tension/rescreening", encodable: body)
    }

    static func tensionMicroModules(severity: String? = nil) -> URLRequest {
        var query: [String: String] = [:]
        if let severity { query["severity"] = severity }
        return get("tension/micro-modules", query: query)
    }

    static func tensionCompletedModules() -> URLRequest {
        get("tension/micro-modules/completed")
    }

    static func startTensionModule(key: String) -> URLRequest {
        post("tension/micro-modules/\(key)/start")
    }

    static func completeTensionModule(completionId: String) -> URLRequest {
        post("tension/micro-modules/\(completionId)/complete")
    }

    // MARK: - Shoulder Impingement Screening

    static func siConfig() -> URLRequest {
        get("shoulder-impingement/config")
    }

    static func submitSiScreening(body: SiScreeningSubmission) -> URLRequest {
        post("shoulder-impingement/screening", encodable: body)
    }

    static func siResult() -> URLRequest {
        get("shoulder-impingement/result")
    }

    static func siHistory() -> URLRequest {
        get("shoulder-impingement/history")
    }

    static func siFocusAreas() -> URLRequest {
        get("shoulder-impingement/focus-areas")
    }

    static func submitSiRescreening(body: SiScreeningSubmission) -> URLRequest {
        post("shoulder-impingement/rescreening", encodable: body)
    }

    static func siMicroModules(severity: String? = nil) -> URLRequest {
        var query: [String: String] = [:]
        if let severity { query["severity"] = severity }
        return get("shoulder-impingement/micro-modules", query: query)
    }

    static func siCompletedModules() -> URLRequest {
        get("shoulder-impingement/micro-modules/completed")
    }

    static func startSiModule(key: String) -> URLRequest {
        post("shoulder-impingement/micro-modules/\(key)/start")
    }

    static func completeSiModule(completionId: String) -> URLRequest {
        post("shoulder-impingement/micro-modules/\(completionId)/complete")
    }

    // MARK: - Frozen Shoulder Screening

    static func fsConfig() -> URLRequest {
        get("frozen-shoulder/config")
    }

    static func submitFsScreening(body: FsScreeningSubmission) -> URLRequest {
        post("frozen-shoulder/screening", encodable: body)
    }

    static func fsResult() -> URLRequest {
        get("frozen-shoulder/result")
    }

    static func fsHistory() -> URLRequest {
        get("frozen-shoulder/history")
    }

    static func fsFocusAreas() -> URLRequest {
        get("frozen-shoulder/focus-areas")
    }

    static func submitFsRescreening(body: FsScreeningSubmission) -> URLRequest {
        post("frozen-shoulder/rescreening", encodable: body)
    }

    static func fsMicroModules(severity: String? = nil) -> URLRequest {
        var query: [String: String] = [:]
        if let severity { query["severity"] = severity }
        return get("frozen-shoulder/micro-modules", query: query)
    }

    static func fsCompletedModules() -> URLRequest {
        get("frozen-shoulder/micro-modules/completed")
    }

    static func startFsModule(key: String) -> URLRequest {
        post("frozen-shoulder/micro-modules/\(key)/start")
    }

    static func completeFsModule(completionId: String) -> URLRequest {
        post("frozen-shoulder/micro-modules/\(completionId)/complete")
    }

    // MARK: - LBP Fear Hierarchy

    static func fearHierarchy() -> URLRequest {
        get("lbp-enhancements/fear-hierarchy")
    }

    static func createFearHierarchy(body: FearHierarchyCreateRequest) -> URLRequest {
        post("lbp-enhancements/fear-hierarchy", encodable: body)
    }

    static func logExposure(itemId: String, body: ExposureLogRequest) -> URLRequest {
        post("lbp-enhancements/fear-hierarchy/items/\(itemId)/exposure", encodable: body)
    }

    static func getExposures(itemId: String) -> URLRequest {
        get("lbp-enhancements/fear-hierarchy/items/\(itemId)/exposures")
    }

    // MARK: - LBP Pacing Plans

    static func pacingPlan() -> URLRequest {
        get("lbp-enhancements/pacing-plan")
    }

    static func createPacingPlan(body: [String: Any]) -> URLRequest {
        post("lbp-enhancements/pacing-plan", body: body)
    }

    static func pacingTemplate(subtype: String) -> URLRequest {
        get("lbp-enhancements/pacing-templates/\(subtype)")
    }

    static func createPacingPlanFromTemplate() -> URLRequest {
        post("lbp-enhancements/pacing-plan/from-template")
    }

    static func startBaseline() -> URLRequest {
        post("lbp-enhancements/pacing-plan/baseline/start")
    }

    static func logBaseline(body: [String: Any]) -> URLRequest {
        post("lbp-enhancements/pacing-plan/baseline/log", body: body)
    }

    static func calculateBaseline() -> URLRequest {
        post("lbp-enhancements/pacing-plan/baseline/calculate")
    }

    static func logPacing(body: PacingLogRequest) -> URLRequest {
        post("lbp-enhancements/pacing-log", encodable: body)
    }

    static func pacingLogs(days: Int = 30) -> URLRequest {
        get("lbp-enhancements/pacing-logs", query: ["days": "\(days)"])
    }

    static func adjustQuota(body: [String: Any]) -> URLRequest {
        post("lbp-enhancements/pacing-plan/adjust-quota", body: body)
    }

    static func suggestProgression() -> URLRequest {
        get("lbp-enhancements/pacing-plan/suggest-progression")
    }

    static func applyProgression() -> URLRequest {
        post("lbp-enhancements/pacing-plan/apply-progression")
    }

    // MARK: - LBP Plan Adjustments

    static func planAdjustments() -> URLRequest {
        get("lbp-enhancements/plan-adjustments")
    }

    // MARK: - LBP Micro-Modules

    static func lbpMicroModules(subtype: String? = nil) -> URLRequest {
        var query: [String: String] = [:]
        if let subtype { query["subtype"] = subtype }
        return get("lbp-enhancements/micro-modules", query: query)
    }

    static func lbpCompletedModules() -> URLRequest {
        get("lbp-enhancements/micro-modules/completed")
    }

    static func startLbpModule(key: String) -> URLRequest {
        post("lbp-enhancements/micro-modules/\(key)/start")
    }

    static func completeLbpModule(completionId: String) -> URLRequest {
        post("lbp-enhancements/micro-modules/\(completionId)/complete")
    }

    // MARK: - LBP Analytics

    static func analyticsSummary() -> URLRequest {
        get("lbp-enhancements/analytics/summary")
    }

    static func fearReductionAnalytics() -> URLRequest {
        get("lbp-enhancements/analytics/fear-reduction")
    }

    static func pacingComplianceAnalytics() -> URLRequest {
        get("lbp-enhancements/analytics/pacing-compliance")
    }

    // MARK: - Work Timer

    static func getWorkTimerSettings() -> URLRequest {
        get("work-timer/settings")
    }

    static func updateWorkTimerSettings(body: WorkTimerSettings) -> URLRequest {
        put("work-timer/settings", encodable: body)
    }

    static func getWorkTimerExercises() -> URLRequest {
        get("work-timer/exercises")
    }

    static func logWorkTimerBreak(body: WorkTimerBreakLog) -> URLRequest {
        post("work-timer/breaks", encodable: body)
    }

    static func getWorkTimerTodaySummary() -> URLRequest {
        get("work-timer/breaks/today")
    }

    static func getWorkTimerHistory() -> URLRequest {
        get("work-timer/history")
    }

    // MARK: - ACL Screening

    static func aclConfig() -> URLRequest {
        get("acl/config")
    }

    static func submitAclScreening(body: AclScreeningSubmission) -> URLRequest {
        post("acl/screening", encodable: body)
    }

    static func aclResult() -> URLRequest {
        get("acl/screening")
    }

    // MARK: - ACL Streams

    static func aclStreams() -> URLRequest {
        get("acl/streams")
    }

    static func aclStreamDetail(streamId: String) -> URLRequest {
        get("acl/streams/\(streamId)")
    }

    // MARK: - ACL Milestone

    static func aclMilestoneStatus() -> URLRequest {
        get("acl/milestone-status")
    }

    // MARK: - ACL Daily KPIs

    static func submitAclDailyKpi(body: AclDailyKpiRequest) -> URLRequest {
        post("acl/daily-kpi", encodable: body)
    }

    static func aclDailyKpiHistory(limit: Int = 30, date: String? = nil) -> URLRequest {
        var query: [String: String] = ["limit": "\(limit)"]
        if let date { query["date"] = date }
        return get("acl/daily-kpi", query: query)
    }

    // MARK: - ACL Weekly KPIs

    static func submitAclWeeklyKpi(body: AclWeeklyKpiRequest) -> URLRequest {
        post("acl/weekly-kpi", encodable: body)
    }

    static func aclWeeklyKpiHistory(limit: Int = 30, currentWeek: Bool = false) -> URLRequest {
        var query: [String: String] = ["limit": "\(limit)"]
        if currentWeek { query["current_week"] = "true" }
        return get("acl/weekly-kpi", query: query)
    }

    // MARK: - ACL Lab Assessments

    static func aclLabAssessmentHistory() -> URLRequest {
        get("acl/lab-assessment")
    }

    // MARK: - ACL Discharge

    static func aclDischargeProgress() -> URLRequest {
        get("acl/discharge-progress")
    }

    // MARK: - ACL Analytics

    static func aclAnalytics() -> URLRequest {
        get("acl/analytics")
    }

    // MARK: - ACL Micro-Modules

    static func aclMicroModules(milestone: Int? = nil) -> URLRequest {
        var query: [String: String] = [:]
        if let milestone { query["milestone"] = "\(milestone)" }
        return get("acl/micro-modules", query: query)
    }

    static func aclCompletedModules() -> URLRequest {
        get("acl/micro-modules/completed")
    }

    static func startAclModule(key: String) -> URLRequest {
        post("acl/micro-modules/\(key)/start")
    }

    static func completeAclModule(completionId: String) -> URLRequest {
        post("acl/micro-modules/\(completionId)/complete")
    }

    static func aclDailyTip() -> URLRequest {
        get("acl/daily-tip")
    }

    // MARK: - Streak

    static func streak() -> URLRequest {
        get("patient/streak")
    }

    // MARK: - Custom Exercises

    static func customExercises() -> URLRequest {
        get("patient/custom-exercises")
    }

    // MARK: - Bridge (Morning Check-In + Smart Day)

    static func submitMorningCheckin(body: MorningCheckinRequest) -> URLRequest {
        post("bridge/morning-checkin", encodable: body)
    }

    static func morningCheckinToday() -> URLRequest {
        get("bridge/morning-checkin/today")
    }

    static func smartDay() -> URLRequest {
        get("bridge/smart-day", query: ["tz": TimeZone.current.identifier])
    }

    // MARK: - Clinical Channel

    static func createClinicalThread(body: CreateThreadRequest) -> URLRequest {
        post("clinical-channel/threads", encodable: body)
    }

    static func clinicalThreads() -> URLRequest {
        get("clinical-channel/threads")
    }

    static func clinicalThreadDetail(_ id: String) -> URLRequest {
        get("clinical-channel/threads/\(id)")
    }

    static func sendClinicalMessage(threadId: String, body: SendMessageRequest) -> URLRequest {
        post("clinical-channel/threads/\(threadId)/messages", encodable: body)
    }

    static func clinicalUnreadCount() -> URLRequest {
        get("clinical-channel/unread")
    }

    // MARK: - Config

    static func features() -> URLRequest {
        get("config/features")
    }

    static func healthCheck() -> URLRequest {
        get("health")
    }
}

// MARK: - Request Builders

private extension APIEndpoints {
    static func get(_ path: String, query: [String: String] = [:]) -> URLRequest {
        guard var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false) else {
            return URLRequest(url: baseURL)
        }
        if !query.isEmpty {
            components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        var request = URLRequest(url: components.url ?? baseURL)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 30
        return request
    }

    static func post(_ path: String, body: [String: Any]? = nil) -> URLRequest {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 30
        if let body {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }
        return request
    }

    static func post<T: Encodable>(_ path: String, encodable: T) -> URLRequest {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 30
        do {
            request.httpBody = try JSONEncoder().encode(encodable)
        } catch {
            Log.api.error("Failed to encode POST body for \(path): \(error)")
        }
        return request
    }

    static func put(_ path: String, body: [String: Any]? = nil) -> URLRequest {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 30
        if let body {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }
        return request
    }

    static func delete(_ path: String) -> URLRequest {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 30
        return request
    }

    static func put<T: Encodable>(_ path: String, encodable: T) -> URLRequest {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 30
        do {
            request.httpBody = try JSONEncoder().encode(encodable)
        } catch {
            Log.api.error("Failed to encode PUT body for \(path): \(error)")
        }
        return request
    }
}
