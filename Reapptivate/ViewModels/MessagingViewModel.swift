import SwiftUI

@Observable
@MainActor
final class MessagingViewModel {
    var threads: [ClinicalThread] = []
    var currentThread: ClinicalThread?
    var currentMessages: [ClinicalMessage] = []
    var unreadCount: Int = 0
    var isLoading = false
    var isLoadingMessages = false
    var isSending = false
    var errorMessage: String?

    private let apiClient: APIClient
    private weak var appState: AppState?
    private var unreadTimer: Timer?
    private var messageTimer: Timer?
    private var activeThreadId: String?

    init(apiClient: APIClient, appState: AppState) {
        self.apiClient = apiClient
        self.appState = appState
    }

    // MARK: - Thread List

    func fetchThreads() async {
        isLoading = true
        errorMessage = nil

        do {
            let response: ThreadListResponse = try await apiClient.request(
                APIEndpoints.clinicalThreads()
            )
            threads = response.threads.sorted {
                ($0.lastMessageAt ?? $0.createdAt) > ($1.lastMessageAt ?? $1.createdAt)
            }
            isLoading = false
        } catch {
            Log.api.error("Fetch threads failed: \(error.localizedDescription)")
            errorMessage = "Nachrichten konnten nicht geladen werden."
            isLoading = false
        }
    }

    // MARK: - Thread Detail

    func fetchThreadDetail(_ threadId: String) async {
        guard TokenManager.shared.getToken() != nil else {
            stopMessagePolling()
            return
        }

        isLoadingMessages = true
        activeThreadId = threadId

        do {
            let response: ThreadDetailResponse = try await apiClient.request(
                APIEndpoints.clinicalThreadDetail(threadId)
            )
            currentThread = response.thread
            currentMessages = response.messages
            isLoadingMessages = false
        } catch {
            Log.api.error("Fetch thread detail failed: \(error.localizedDescription)")
            errorMessage = "Nachrichten konnten nicht geladen werden."
            isLoadingMessages = false
        }
    }

    // MARK: - Send Message

    func sendMessage(threadId: String, content: String) async -> Bool {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        isSending = true

        let request = SendMessageRequest(content: content)

        do {
            let response: SendMessageResponse = try await apiClient.request(
                APIEndpoints.sendClinicalMessage(threadId: threadId, body: request)
            )
            currentMessages.append(response.message)
            isSending = false
            return true
        } catch {
            Log.api.error("Send message failed: \(error.localizedDescription)")
            errorMessage = "Nachricht konnte nicht gesendet werden."
            isSending = false
            return false
        }
    }

    // MARK: - Create Thread

    func createThread(_ request: CreateThreadRequest) async -> ClinicalThread? {
        isSending = true
        errorMessage = nil

        do {
            let response: CreateThreadResponse = try await apiClient.request(
                APIEndpoints.createClinicalThread(body: request)
            )
            threads.insert(response.thread, at: 0)
            isSending = false
            return response.thread
        } catch {
            Log.api.error("Create thread failed: \(error.localizedDescription)")
            errorMessage = "Konversation konnte nicht erstellt werden."
            isSending = false
            return nil
        }
    }

    // MARK: - Unread Count

    func fetchUnreadCount() async {
        guard TokenManager.shared.getToken() != nil else {
            stopPolling()
            return
        }

        do {
            let response: UnreadCountResponse = try await apiClient.request(
                APIEndpoints.clinicalUnreadCount()
            )
            unreadCount = response.count
            appState?.unreadMessageCount = response.count
        } catch {
            Log.api.error("Fetch unread count failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Polling

    func startUnreadPolling() {
        stopUnreadPolling()
        unreadTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                await self.fetchUnreadCount()
            }
        }
        // Initial fetch
        Task { await fetchUnreadCount() }
    }

    func startMessagePolling(threadId: String) {
        stopMessagePolling()
        activeThreadId = threadId
        messageTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                await self.fetchThreadDetail(threadId)
            }
        }
    }

    func stopUnreadPolling() {
        unreadTimer?.invalidate()
        unreadTimer = nil
    }

    func stopMessagePolling() {
        messageTimer?.invalidate()
        messageTimer = nil
        activeThreadId = nil
    }

    func stopPolling() {
        stopUnreadPolling()
        stopMessagePolling()
    }

    // MARK: - Cleanup

    func clearCurrentThread() {
        currentThread = nil
        currentMessages = []
        stopMessagePolling()
    }
}
