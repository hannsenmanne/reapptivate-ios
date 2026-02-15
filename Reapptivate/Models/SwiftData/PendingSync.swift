import Foundation
import SwiftData

@Model
final class PendingSync {
    @Attribute(.unique) var syncId: String
    var endpoint: String
    var method: String
    var body: Data?
    var createdAt: Date
    var retryCount: Int

    static let maxRetries = 5

    init(
        endpoint: String,
        method: String,
        body: Data? = nil
    ) {
        self.syncId = UUID().uuidString
        self.endpoint = endpoint
        self.method = method
        self.body = body
        self.createdAt = .now
        self.retryCount = 0
    }

    var canRetry: Bool {
        retryCount < Self.maxRetries
    }
}
