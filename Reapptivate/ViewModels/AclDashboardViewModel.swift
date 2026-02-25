import Foundation

@Observable
@MainActor
final class AclDashboardViewModel {
    var milestoneStatus: AclMilestoneStatus?
    var streams: [AclStream] = []
    var dischargeProgress: AclDischargeProgress?
    var dailyTip: AclDailyTip?
    var streak: StreakResponse?
    var isLoading = false
    var errorMessage: String?

    // Milestone celebration
    var milestoneAdvanced = false
    var newMilestoneReached: Int?
    private var previousMilestone: Int?

    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    // MARK: - Data Loading

    func loadAll() async {
        isLoading = true
        errorMessage = nil

        // Remember previous milestone for celebration detection
        if previousMilestone == nil {
            previousMilestone = milestoneStatus?.currentMilestone
        }

        async let milestoneResult: AclMilestoneStatus? = loadSafely {
            try await self.apiClient.request(APIEndpoints.aclMilestoneStatus())
        }

        async let streamsResult: AclStreamsResponse? = loadSafely {
            try await self.apiClient.request(APIEndpoints.aclStreams())
        }

        async let dischargeResult: AclDischargeProgress? = loadSafely {
            try await self.apiClient.request(APIEndpoints.aclDischargeProgress())
        }

        async let tipResult: AclDailyTip? = loadSafely {
            try await self.apiClient.request(APIEndpoints.aclDailyTip())
        }

        async let streakResult: StreakResponse? = loadSafely {
            try await self.apiClient.request(APIEndpoints.streak())
        }

        async let todayProgressResult: TodayProgressResponse? = loadSafely {
            try await self.apiClient.request(APIEndpoints.getTodayProgress())
        }

        let (milestone, streamsResp, discharge, tip, streakResp, todayProgress) = await (milestoneResult, streamsResult, dischargeResult, tipResult, streakResult, todayProgressResult)

        milestoneStatus = milestone
        streams = streamsResp?.streams ?? []
        dischargeProgress = discharge
        dailyTip = tip
        streak = streakResp
        todayCompletedCount = todayProgress?.count ?? 0

        // Compute today's total from schedule streams + unlocked stream exercise counts
        let todayIds = AclScheduleData.today(forWeek: milestone?.weeksPostSurgery ?? 0)?.day.streamIds ?? []
        let allStreams = streamsResp?.streams ?? []
        todayTotalCount = todayIds.reduce(0) { total, streamId in
            total + (allStreams.first { $0.id == streamId }?.exerciseCount ?? 0)
        }

        // Detect milestone advancement
        if let prev = previousMilestone, let current = milestone?.currentMilestone, current > prev {
            newMilestoneReached = current
            milestoneAdvanced = true
        }
        previousMilestone = milestone?.currentMilestone

        isLoading = false
    }

    // MARK: - Computed

    var currentMilestone: Int {
        milestoneStatus?.currentMilestone ?? 0
    }

    var weeksPostSurgery: Int {
        milestoneStatus?.weeksPostSurgery ?? 0
    }

    var unlockedStreams: [AclStream] {
        streams.filter { $0.locked != true }
    }

    var lockedStreams: [AclStream] {
        streams.filter { $0.locked == true }
    }

    // MARK: - Today's Schedule

    var todaySchedule: AclScheduleData.ScheduleDay? {
        AclScheduleData.today(forWeek: weeksPostSurgery)?.day
    }

    var isRestDay: Bool {
        todaySchedule?.isRest ?? true
    }

    var todayStreamIds: [String] {
        todaySchedule?.streamIds ?? []
    }

    // MARK: - Today's Progress

    var todayCompletedCount = 0
    var todayTotalCount = 0

    func loadTodayProgress() async {
        do {
            let response: TodayProgressResponse = try await apiClient.request(
                APIEndpoints.getTodayProgress()
            )
            todayCompletedCount = response.count
        } catch {
            Log.api.error("ACL today progress load error: \(error.localizedDescription)")
        }
    }

    // MARK: - Private

    private func loadSafely<T: Sendable>(_ work: @Sendable () async throws -> T) async -> T? {
        do {
            return try await work()
        } catch {
            Log.api.error("ACL dashboard load error: \(error.localizedDescription)")
            if errorMessage == nil {
                errorMessage = "Daten konnten nicht geladen werden. Bitte versuchen Sie es erneut."
            }
            return nil
        }
    }
}
