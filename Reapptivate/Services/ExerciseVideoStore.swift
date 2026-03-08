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

    func saveVideo(from sourceURL: URL, for exerciseId: String) throws -> URL {
        let destination = videosDirectory.appendingPathComponent("\(exerciseId).mov")
        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }
        try fileManager.copyItem(at: sourceURL, to: destination)
        return destination
    }

    func deleteVideo(for exerciseId: String) throws {
        let url = videosDirectory.appendingPathComponent("\(exerciseId).mov")
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
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
