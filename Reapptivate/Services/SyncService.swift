import SwiftUI
import SwiftData

@Observable
@MainActor
final class SyncService {
    private let apiClient: APIClient
    private let networkMonitor: NetworkMonitor
    private let modelContext: ModelContext
    init(apiClient: APIClient, networkMonitor: NetworkMonitor, modelContext: ModelContext) {
        self.apiClient = apiClient
        self.networkMonitor = networkMonitor
        self.modelContext = modelContext
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
                tsiSeverity: profile.tsiSeverity?.rawValue,
                protocolId: profile.protocolId,
                aemScreeningCompleted: profile.aemScreeningCompleted ?? false,
                neckScreeningCompleted: profile.neckScreeningCompleted ?? false,
                tensionScreeningCompleted: profile.tensionScreeningCompleted ?? false,
                startDate: profile.startDate
            )
            modelContext.insert(cached)
        }
        try? modelContext.save()
    }

    // MARK: - Cache Progress Entries

    func cacheProgress(_ entries: [ProgressEntry]) {
        for entry in entries {
            let entryId = entry.id
            let descriptor = FetchDescriptor<CachedProgress>(
                predicate: #Predicate { $0.entryId == entryId }
            )
            let existing = (try? modelContext.fetch(descriptor))?.first
            if existing != nil { continue }

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
            Log.sync.info("All cached data cleared")
        } catch {
            Log.sync.error("Failed to clear cached data: \(error)")
        }
    }
}
