import Foundation

struct ClinicalThread: Codable, Identifiable {
    let id: String
    let threadType: String
    let subject: String
    let status: String
    let lastMessage: String?
    let lastMessageAt: Date?
    let unreadCount: Int?
    let createdAt: Date

    var isOpen: Bool { status == "open" }
    var isResolved: Bool { status == "resolved" }

    var threadTypeLabel: String {
        switch threadType {
        case "flag_concern": return "Bedenken"
        case "exercise_question": return "Frage"
        case "progress_share": return "Fortschritt"
        case "free_text": return "Nachricht"
        default: return threadType
        }
    }

    var threadTypeIcon: String {
        switch threadType {
        case "flag_concern": return "exclamationmark.triangle.fill"
        case "exercise_question": return "questionmark.circle.fill"
        case "progress_share": return "chart.line.uptrend.xyaxis"
        case "free_text": return "envelope.fill"
        default: return "message.fill"
        }
    }

    var threadTypeColor: String {
        switch threadType {
        case "flag_concern": return "red"
        case "exercise_question": return "blue"
        case "progress_share": return "green"
        default: return "gray"
        }
    }
}

struct ThreadDetailResponse: Codable {
    let thread: ClinicalThread
    let messages: [ClinicalMessage]
}

struct ThreadListResponse: Codable {
    let threads: [ClinicalThread]
}

struct CreateThreadRequest: Codable {
    let threadType: String
    let subject: String
    let message: String
    let context: ThreadContext?
}

struct ThreadContext: Codable {
    let category: String?
    let severity: String?
    let exerciseId: String?
    let exerciseName: String?
}

struct CreateThreadResponse: Codable {
    let thread: ClinicalThread
    let message: ClinicalMessage
}

struct UnreadCountResponse: Codable {
    let count: Int
}
