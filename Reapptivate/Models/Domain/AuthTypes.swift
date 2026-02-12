import Foundation

// MARK: - Login

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct LoginResponse: Codable {
    let user: LoginUser
    let token: String
}

struct LoginUser: Codable {
    let id: String
    let name: String
    let email: String
    let tendinopathyType: TendinopathyType
    let adaptivePhase: Int?
    let aemScreeningCompleted: Bool?
    let aemSubtype: AemSubtype?
    let neckScreeningCompleted: Bool?
    let neckSubtype: NeckSubtype?

    func toUserProfile() -> UserProfile {
        UserProfile(
            id: id,
            email: email,
            name: name,
            tendinopathyType: tendinopathyType,
            protocolId: nil,
            startDate: "",
            createdAt: "",
            adaptivePhase: adaptivePhase,
            phaseStartedAt: nil,
            adaptationEnabled: true,
            aemScreeningCompleted: aemScreeningCompleted,
            aemSubtype: aemSubtype,
            neckScreeningCompleted: neckScreeningCompleted,
            ndiSeverity: nil
        )
    }
}

// MARK: - Onboarding

struct InvitationDetails: Codable {
    let invitation: InvitationInfo
}

struct InvitationInfo: Codable {
    let id: String
    let patientName: String
    let email: String?
    let phone: String?
    let tendinopathyType: TendinopathyType
    let expiresAt: String
}

struct OnboardingRequest: Codable {
    let email: String
    let password: String
    let phone: String?
    let timezone: String
    let startDate: String
}

struct OnboardingResponse: Codable {
    let user: LoginUser
    let token: String
}
