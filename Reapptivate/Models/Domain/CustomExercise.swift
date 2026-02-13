import Foundation

struct CustomExercise: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let sets: Int
    let reps: Int
    let pauseSeconds: Int
    let extra: String
    let createdAt: String
}
