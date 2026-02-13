import SwiftUI
import SwiftData

@Observable
@MainActor
final class SyncService {
    private let apiClient: APIClient
    private let networkMonitor: NetworkMonitor
    private var modelContext: ModelContext?
    private var isSyncing = false

    var pendingCount: Int = 0

    init(apiClient: APIClient, networkMonitor: NetworkMonitor) {
        self.apiClient = apiClient
        self.networkMonitor = networkMonitor
    }

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - Queue Offline Request

    func queueRequest(endpoint: String, method: String, body: Data?) {
        guard let context = modelContext else { return }
        let pending = PendingSync(endpoint: endpoint, method: method, body: body)
        context.insert(pending)
        try? context.save()
        updateCount()
    }

    // MARK: - Drain Queue

    func drainQueue() async {
        guard networkMonitor.isConnected, !isSyncing else { return }
        guard let context = modelContext else { return }

        isSyncing = true

        let descriptor = FetchDescriptor<PendingSync>(
            sortBy: [SortDescriptor(\.createdAt)]
        )

        guard let pending = try? context.fetch(descriptor), !pending.isEmpty else {
            isSyncing = false
            return
        }

        for item in pending {
            guard item.retryCount < 5 else {
                context.delete(item)
                continue
            }

            do {
                var request = URLRequest(url: APIEndpoints.baseURL.appendingPathComponent(item.endpoint))
                request.httpMethod = item.method
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue("application/json", forHTTPHeaderField: "Accept")
                request.httpBody = item.body

                let _: Data = try await apiClient.requestData(request)
                context.delete(item)
            } catch {
                item.retryCount += 1
            }
        }

        try? context.save()
        updateCount()
        isSyncing = false
    }

    // MARK: - Cache User Profile

    func cacheUser(_ profile: UserProfile) {
        guard let context = modelContext else { return }

        let descriptor = FetchDescriptor<CachedUser>()
        let existing = (try? context.fetch(descriptor))?.first

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
            context.insert(cached)
        }
        try? context.save()
    }

    // MARK: - Cache Progress Entries

    func cacheProgress(_ entries: [ProgressEntry]) {
        guard let context = modelContext else { return }

        for entry in entries {
            let cached = CachedProgress(from: entry)
            context.insert(cached)
        }
        try? context.save()
    }

    // MARK: - Clear All Cached Data (Logout)

    func clearAllData() {
        guard let context = modelContext else { return }

        do {
            try context.delete(model: CachedUser.self)
            try context.delete(model: CachedProgress.self)
            try context.delete(model: PendingSync.self)
            try context.save()
            pendingCount = 0
            Log.sync.info("All cached data cleared")
        } catch {
            Log.sync.error("Failed to clear cached data: \(error)")
        }
    }

    // MARK: - Helpers

    private func updateCount() {
        guard let context = modelContext else {
            pendingCount = 0
            return
        }
        let descriptor = FetchDescriptor<PendingSync>()
        pendingCount = (try? context.fetchCount(descriptor)) ?? 0
    }
}
