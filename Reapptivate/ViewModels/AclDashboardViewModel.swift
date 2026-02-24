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

        let (milestone, streamsResp, discharge, tip, streakResp) = await (milestoneResult, streamsResult, dischargeResult, tipResult, streakResult)

        milestoneStatus = milestone
        streams = streamsResp?.streams ?? []
        dischargeProgress = discharge
        dailyTip = tip
        streak = streakResp

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
