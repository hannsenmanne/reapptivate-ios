import SwiftUI

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @Bindable var viewModel: AuthViewModel

    @FocusState private var focusedField: Field?

    enum Field {
        case email, password, confirm, phone
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Konto erstellen")
                        .font(.appTitle)
                        .foregroundStyle(.textPrimary)

                    if let details = viewModel.invitationDetails {
                        Text("Willkommen, \(details.patientName)!")
                            .font(.appBody)
                            .foregroundStyle(.textSecondary)

                        Text(details.tendinopathyType.displayName)
                            .font(.appCaptionMedium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.accent.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.badgeRadius, style: .continuous))
                    }
                }

                // Form
                VStack(spacing: 16) {
                    // Email
                    FormField(label: "E-Mail") {
                        TextField("ihre@email.de", text: $viewModel.onboardingEmail)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .focused($focusedField, equals: .email)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .password }
                    }

                    // Password
                    FormField(label: "Passwort", hint: "Mindestens 8 Zeichen") {
                        SecureField("Passwort", text: $viewModel.onboardingPassword)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.newPassword)
                            .focused($focusedField, equals: .password)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .confirm }
                    }

                    // Confirm Password
                    FormField(label: "Passwort bestätigen") {
                        SecureField("Passwort bestätigen", text: $viewModel.onboardingPasswordConfirm)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.newPassword)
                            .focused($focusedField, equals: .confirm)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .phone }
                    }

                    if !viewModel.onboardingPassword.isEmpty && !viewModel.onboardingPasswordConfirm.isEmpty && !viewModel.onboardingPasswordsMatch {
                        Text("Passwörter stimmen nicht überein")
                            .font(.appCaption)
                            .foregroundStyle(.painRed)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Phone (optional)
                    FormField(label: "Telefon (optional)") {
                        TextField("+49...", text: $viewModel.onboardingPhone)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.telephoneNumber)
                            .keyboardType(.phonePad)
                            .focused($focusedField, equals: .phone)
                    }

                    // Start Date
                    FormField(label: "Trainingsstart") {
                        DatePicker(
                            "Startdatum",
                            selection: $viewModel.onboardingStartDate,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .environment(\.locale, Locale(identifier: "de_DE"))
                    }
                }

                // Error
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.appCaption)
                        .foregroundStyle(.painRed)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Submit
                Button {
                    Task { await viewModel.completeOnboarding(appState: appState) }
                } label: {
                    Group {
                        if viewModel.isOnboarding {
                            ProgressView().tint(.white)
                        } else {
                            Text("Registrieren")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                }
                .buttonStyle(.accentFilled)
                .disabled(!canSubmit)
            }
            .padding(24)
        }
        .background(Color.appBg)
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled()
    }

    private var canSubmit: Bool {
        !viewModel.onboardingEmail.isEmpty &&
        viewModel.onboardingPasswordValid &&
        viewModel.onboardingPasswordsMatch &&
        !viewModel.isOnboarding
    }
}

// MARK: - Form Field Helper

struct FormField<Content: View>: View {
    let label: String
    var hint: String?
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.appSubheadlineMedium)
                    .foregroundStyle(.textSecondary)
                if let hint {
                    Spacer()
                    Text(hint)
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary.opacity(0.7))
                }
            }
            content
        }
    }
}
