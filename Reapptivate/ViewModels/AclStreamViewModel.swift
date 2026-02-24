import Foundation

@Observable
@MainActor
final class AclStreamViewModel {
    var streamDetail: AclStreamDetail?
    var exercises: [AclStreamExercise] = []
    var isLoading = false
    var errorMessage: String?

    private let apiClient: APIClient
    private let streamId: String

    init(apiClient: APIClient, streamId: String) {
        self.apiClient = apiClient
        self.streamId = streamId
    }

    func loadDetail() async {
        isLoading = true
        errorMessage = nil

        do {
            let response: AclStreamDetailResponse = try await apiClient.request(
                APIEndpoints.aclStreamDetail(streamId: streamId)
            )
            streamDetail = response.stream
            // Backend may send exercises in stream.exercises or at top level
            exercises = response.exercises.isEmpty
                ? (response.stream.exercises ?? [])
                : response.exercises
        } catch {
            Log.api.error("ACL stream detail load error: \(error.localizedDescription)")
            errorMessage = "Stream konnte nicht geladen werden."
        }

        isLoading = false
    }
}
