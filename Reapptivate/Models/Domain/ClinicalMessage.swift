import Foundation

struct ClinicalMessage: Codable, Identifiable {
    let id: String
    let senderType: String
    let messageType: String
    let content: String
    let createdAt: Date
    let readAt: Date?

    var isFromPatient: Bool { senderType == "patient" }
    var isFromTherapist: Bool { senderType == "therapist" }
    var isSystem: Bool { senderType == "system" }
}

struct SendMessageRequest: Codable {
    let content: String
    let messageType: String?

    init(content: String, messageType: String? = nil) {
        self.content = content
        self.messageType = messageType
    }
}

struct SendMessageResponse: Codable {
    let message: ClinicalMessage
}
