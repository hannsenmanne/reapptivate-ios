import SwiftUI
import SwiftData

@Observable
@MainActor
final class SyncService {
    private let apiClient: APIClient
    private let networkMonitor: NetworkMonitor
    private let modelContext: ModelContext
    private var isSyncing = false

    var pendingCount: Int = 0

    init(apiClient: APIClient, networkMonitor: NetworkMonitor, modelContext: ModelContext) {
        self.apiClient = apiClient
        self.networkMonitor = networkMonitor
        self.modelContext = modelContext
        updateCount()
    }

    // MARK: - Queue Offline Request

    func queueRequest(endpoint: String, method: String, body: Data?) {
        let pending = PendingSync(endpoint: endpoint, method: method, body: body)
        modelContext.insert(pending)
        try? modelContext.save()
        updateCount()
    }

    // MARK: - Drain Queue

    func drainQueue() async {
        guard networkMonitor.isConnected, !isSyncing else { return }

        isSyncing = true

        let descriptor = FetchDescriptor<PendingSync>(
            sortBy: [SortDescriptor(\.createdAt)]
        )

        guard let pending = try? modelContext.fetch(descriptor), !pending.isEmpty else {
            isSyncing = false
            return
        }

        for item in pending {
            guard item.retryCount < 5 else {
                modelContext.delete(item)
                continue
            }

            do {
                var request = URLRequest(url: APIEndpoints.baseURL.appendingPathComponent(item.endpoint))
                request.httpMethod = item.method
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue("application/json", forHTTPHeaderField: "Accept")
                request.httpBody = item.body

                let _: Data = try await apiClient.requestData(request)
                modelContext.delete(item)
            } catch {
                item.retryCount += 1
            }
        }

        try? modelContext.save()
        updateCount()
        isSyncing = false
    }

    // MARK: - Cache User Profile

    func cacheUser(_ profile: UserProfile) {
        let descriptor = FetchDescriptor<CachedUser>()
        let existing = (try? modelContext.fetch(descriptor))?.first

        if let cached = existing {
            cached.update(from: profile)
        } else {
            let cached = CachedUser(
                userId: profile.id,
                email: profile.email,
                name: profile.name,
                tendinopathyType: profile.tendinopathyType.rawValue,
                adaptivePhase: profile.currentPhase,
                aemSubtype: profile.aemSubtype?.rawValue,
                ndiSeverity: profile.ndiSeverity?.rawValue,
                protocolId: profile.protocolId,
                aemScreeningCompleted: profile.aemScreeningCompleted ?? false,
                neckScreeningCompleted: profile.neckScreeningCompleted ?? false,
                startDate: profile.startDate
            )
            modelContext.insert(cached)
        }
        try? modelContext.save()
    }

    // MARK: - Cache Progress Entries

    func cacheProgress(_ entries: [ProgressEntry]) {
        for entry in entries {
            let cached = CachedProgress(from: entry)
            modelContext.insert(cached)
        }
        try? modelContext.save()
    }

    // MARK: - Clear All Cached Data (Logout)

    func clearAllData() {
        do {
            try modelContext.delete(model: CachedUser.self)
            try modelContext.delete(model: CachedProgress.self)
            try modelContext.delete(model: PendingSync.self)
            try modelContext.save()
            pendingCount = 0
            Log.sync.info("All cached data cleared")
        } catch {
            Log.sync.error("Failed to clear cached data: \(error)")
        }
    }

    // MARK: - Helpers

    private func updateCount() {
        let descriptor = FetchDescriptor<PendingSync>()
        pendingCount = (try? modelContext.fetchCount(descriptor)) ?? 0
    }
}
