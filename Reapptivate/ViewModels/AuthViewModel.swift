import SwiftUI

@Observable
@MainActor
final class AuthViewModel {
    // Login state
    var email = ""
    var password = ""
    var isLoading = false
    var errorMessage: String?

    // Onboarding state
    var invitationToken = ""
    var invitationDetails: InvitationInfo?
    var onboardingEmail = ""
    var onboardingPassword = ""
    var onboardingPasswordConfirm = ""
    var onboardingPhone = ""
    var onboardingStartDate = Date.now
    var isValidatingToken = false
    var isOnboarding = false

    // Navigation
    var showOnboarding = false
    var showQRScanner = false

    private let apiClient: APIClient
    private let tokenManager: TokenManager

    init(apiClient: APIClient, tokenManager: TokenManager = .shared) {
        self.apiClient = apiClient
        self.tokenManager = tokenManager
    }

    // MARK: - Login

    func login(appState: AppState) async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Bitte geben Sie E-Mail und Passwort ein."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let response: LoginResponse = try await apiClient.request(
                APIEndpoints.login(email: email, password: password)
            )

            tokenManager.saveToken(response.token)
            tokenManager.saveUserId(response.user.id)

            // Fetch full profile for complete data
            let userResponse: UserResponse = try await apiClient.request(APIEndpoints.me())
            apiClient.resetLogoutGuard()
            appState.handleLogin(user: userResponse.user)

            Log.auth.info("Login successful for \(response.user.name)")
        } catch let error as APIError {
            switch error {
            case .unauthorized:
                errorMessage = "E-Mail oder Passwort ist falsch."
            case .networkError:
                errorMessage = "Keine Verbindung zum Server. Bitte überprüfen Sie Ihre Internetverbindung."
            default:
                errorMessage = error.localizedDescription
            }
        } catch {
            errorMessage = "Ein unerwarteter Fehler ist aufgetreten."
        }

        isLoading = false
    }

    // MARK: - Auto-login

    func checkExistingAuth(appState: AppState) async {
        #if DEBUG
        // Dev auto-login: launch with --dev-token <jwt> --dev-user-id <id>
        let args = ProcessInfo.processInfo.arguments
        if let tokenIdx = args.firstIndex(of: "--dev-token"), tokenIdx + 1 < args.count,
           let userIdx = args.firstIndex(of: "--dev-user-id"), userIdx + 1 < args.count {
            let token = args[tokenIdx + 1]
            let userId = args[userIdx + 1]
            tokenManager.saveToken(token)
            tokenManager.saveUserId(userId)
            Log.auth.info("Dev token injected via launch args")
        }
        #endif

        guard tokenManager.hasToken, !tokenManager.isTokenExpired() else {
            appState.isCheckingAuth = false
            return
        }

        do {
            let userResponse: UserResponse = try await apiClient.request(APIEndpoints.me())
            appState.handleLogin(user: userResponse.user)
            Log.auth.info("Auto-login successful for \(userResponse.user.name)")
        } catch {
            Log.auth.warning("Auto-login failed, clearing token: \(error.localizedDescription)")
            tokenManager.clearAll()
        }

        appState.isCheckingAuth = false
    }

    // MARK: - Logout

    func logout(appState: AppState) {
        appState.performLogout(apiClient: apiClient)
        // Reset form state
        email = ""
        password = ""
        errorMessage = nil
        Log.auth.info("User logged out")
    }

    // MARK: - Token Validation (Onboarding)

    func validateInvitationToken() async {
        guard !invitationToken.isEmpty else {
            errorMessage = "Bitte geben Sie einen Einladungscode ein."
            return
        }

        isValidatingToken = true
        errorMessage = nil

        do {
            let details: InvitationDetails = try await apiClient.request(
                APIEndpoints.validateToken(invitationToken)
            )
            invitationDetails = details.invitation
            onboardingEmail = details.invitation.email ?? ""
            onboardingPhone = details.invitation.phone ?? ""
            showOnboarding = true
        } catch let error as APIError {
            switch error {
            case .notFound:
                errorMessage = "Ungultiger Einladungscode."
            default:
                errorMessage = error.localizedDescription
            }
        } catch {
            errorMessage = "Fehler bei der Validierung."
        }

        isValidatingToken = false
    }

    // MARK: - Complete Onboarding

    var onboardingPasswordValid: Bool {
        onboardingPassword.count >= 8
    }

    var onboardingPasswordsMatch: Bool {
        onboardingPassword == onboardingPasswordConfirm
    }

    func completeOnboarding(appState: AppState) async {
        guard onboardingPasswordValid else {
            errorMessage = "Passwort muss mindestens 8 Zeichen lang sein."
            return
        }
        guard onboardingPasswordsMatch else {
            errorMessage = "Passwörter stimmen nicht überein."
            return
        }

        isOnboarding = true
        errorMessage = nil

        let body: [String: Any] = [
            "email": onboardingEmail,
            "password": onboardingPassword,
            "phone": onboardingPhone,
            "timezone": "Europe/Berlin",
            "startDate": onboardingStartDate.dateOnlyString, // UTC "yyyy-MM-dd"
        ]

        do {
            let response: OnboardingResponse = try await apiClient.request(
                APIEndpoints.completeOnboarding(token: invitationToken, body: body)
            )

            tokenManager.saveToken(response.token)
            tokenManager.saveUserId(response.user.id)

            let userResponse: UserResponse = try await apiClient.request(APIEndpoints.me())
            appState.handleLogin(user: userResponse.user)

            Log.auth.info("Onboarding completed for \(response.user.name)")
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Registrierung fehlgeschlagen."
        }

        isOnboarding = false
    }

    // MARK: - QR Code Handling

    func handleScannedCode(_ code: String) {
        // Extract token from QR URL or use raw code
        if let url = URL(string: code),
           let pathToken = url.pathComponents.last {
            invitationToken = pathToken
        } else {
            invitationToken = code
        }
        showQRScanner = false
        Task { await validateInvitationToken() }
    }
}
