import SwiftUI

struct LoginView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel: AuthViewModel

    @FocusState private var focusedField: Field?

    enum Field {
        case email, password
    }

    init(apiClient: APIClient) {
        _viewModel = State(initialValue: AuthViewModel(apiClient: apiClient))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Logo & Header — branded "re**app**tivate" wordmark
                    VStack(spacing: 8) {
                        HStack(spacing: 0) {
                            Text("re")
                                .font(.outfit(.extraBold, size: 34))
                                .foregroundStyle(.textPrimary)
                            Text("app")
                                .font(.outfit(.extraBold, size: 34))
                                .foregroundStyle(.accent)
                            Text("tivate")
                                .font(.outfit(.extraBold, size: 34))
                                .foregroundStyle(.textPrimary)
                        }

                        Text("Evidenzbasierte Physiotherapie")
                            .font(.appSubheadline)
                            .foregroundStyle(.textSecondary)
                    }
                    .padding(.top, 60)

                    // Login Form
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("E-Mail")
                                .font(.appSubheadlineMedium)
                                .foregroundStyle(.textSecondary)

                            TextField("ihre@email.de", text: $viewModel.email)
                                .inputFieldStyle()
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .focused($focusedField, equals: .email)
                                .submitLabel(.next)
                                .onSubmit { focusedField = .password }
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Passwort")
                                .font(.appSubheadlineMedium)
                                .foregroundStyle(.textSecondary)

                            SecureField("Passwort", text: $viewModel.password)
                                .inputFieldStyle()
                                .textContentType(.password)
                                .focused($focusedField, equals: .password)
                                .submitLabel(.go)
                                .onSubmit {
                                    Task { await viewModel.login(appState: appState) }
                                }
                        }

                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.appCaption)
                                .foregroundStyle(.painRed)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Button {
                            Task { await viewModel.login(appState: appState) }
                        } label: {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Anmelden")
                            }
                        }
                        .buttonStyle(.primary)
                        .disabled(viewModel.isLoading || viewModel.email.isEmpty || viewModel.password.isEmpty)
                    }
                    .padding(.horizontal, 24)

                    // Divider
                    HStack {
                        Rectangle().frame(height: 1).foregroundStyle(.gray200)
                        Text("oder")
                            .font(.appCaption)
                            .foregroundStyle(.textSecondary)
                        Rectangle().frame(height: 1).foregroundStyle(.gray200)
                    }
                    .padding(.horizontal, 24)

                    // Onboarding Option
                    VStack(spacing: 12) {
                        Text("Haben Sie einen Einladungscode?")
                            .font(.appSubheadline)
                            .foregroundStyle(.textSecondary)

                        HStack(spacing: 12) {
                            Button {
                                viewModel.showQRScanner = true
                            } label: {
                                Label("QR-Code scannen", systemImage: "qrcode.viewfinder")
                            }
                            .buttonStyle(.secondary)

                            NavigationLink {
                                TokenEntryView(viewModel: viewModel)
                            } label: {
                                Label("Code eingeben", systemImage: "keyboard")
                                    .font(.appSubheadlineMedium)
                                    .foregroundStyle(.textPrimary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(Color.cardBg)
                                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.buttonRadius, style: .continuous))
                                    .overlay(RoundedRectangle(cornerRadius: DesignTokens.buttonRadius, style: .continuous).stroke(Color.gray300, lineWidth: 1))
                            }
                        }
                    }

                    Spacer()
                }
            }
            .background(Color.appBg)
            .sheet(isPresented: $viewModel.showQRScanner) {
                QRScannerView { code in
                    viewModel.handleScannedCode(code)
                }
            }
            .navigationDestination(isPresented: $viewModel.showOnboarding) {
                OnboardingView(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Token Entry (Manual Code)

struct TokenEntryView: View {
    @Bindable var viewModel: AuthViewModel

    var body: some View {
        VStack(spacing: 24) {
            Text("Einladungscode eingeben")
                .font(.appTitle2)
                .foregroundStyle(.textPrimary)

            Text("Geben Sie den Code ein, den Sie von Ihrem Therapeuten erhalten haben.")
                .font(.appBody)
                .foregroundStyle(.textSecondary)
                .multilineTextAlignment(.center)

            TextField("Einladungscode", text: $viewModel.invitationToken)
                .inputFieldStyle()
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.appCaption)
                    .foregroundStyle(.painRed)
            }

            Button {
                Task { await viewModel.validateInvitationToken() }
            } label: {
                if viewModel.isValidatingToken {
                    ProgressView().tint(.white)
                } else {
                    Text("Weiter")
                }
            }
            .buttonStyle(.primary)
            .disabled(viewModel.invitationToken.isEmpty || viewModel.isValidatingToken)

            Spacer()
        }
        .padding(24)
        .background(Color.appBg)
    }
}
