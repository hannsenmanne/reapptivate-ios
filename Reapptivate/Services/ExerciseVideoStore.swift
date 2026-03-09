import Foundation

@Observable @MainActor
final class ExerciseVideoStore {
    static let shared = ExerciseVideoStore()

    private let fileManager = FileManager.default
    private let videosDirectory: URL

    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("ExerciseVideos", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        // Exclude from iCloud backup to avoid large video uploads
        var mutableDir = dir
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        try? mutableDir.setResourceValues(resourceValues)
        videosDirectory = dir
    }

    func videoURL(for exerciseId: String) -> URL? {
        let url = videosDirectory.appendingPathComponent("\(exerciseId).mov")
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }

    func saveVideo(from sourceURL: URL, for exerciseId: String) async throws -> URL {
        let destination = videosDirectory.appendingPathComponent("\(exerciseId).mov")
        let source = sourceURL
        return try await Task.detached {
            let fm = FileManager.default
            if fm.fileExists(atPath: destination.path) {
                try fm.removeItem(at: destination)
            }
            try fm.copyItem(at: source, to: destination)
            return destination
        }.value
    }

    func deleteVideo(for exerciseId: String) async throws {
        let url = videosDirectory.appendingPathComponent("\(exerciseId).mov")
        try await Task.detached {
            let fm = FileManager.default
            if fm.fileExists(atPath: url.path) {
                try fm.removeItem(at: url)
            }
        }.value
    }

    /// Deletes the entire ExerciseVideos directory and recreates it empty.
    /// Called on logout to prevent videos from one user leaking to another.
    func deleteAllVideos() {
        if fileManager.fileExists(atPath: videosDirectory.path) {
            try? fileManager.removeItem(at: videosDirectory)
        }
        try? fileManager.createDirectory(at: videosDirectory, withIntermediateDirectories: true)
        var mutableDir = videosDirectory
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        try? mutableDir.setResourceValues(resourceValues)
    }
}
