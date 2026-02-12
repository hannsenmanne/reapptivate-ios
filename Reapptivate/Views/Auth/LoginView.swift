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
                    // Logo & Header
                    VStack(spacing: 8) {
                        Text("Reapptivate")
                            .font(.largeTitle.bold())
                            .foregroundStyle(.textPrimary)

                        Text("Evidenzbasierte Physiotherapie")
                            .font(.subheadline)
                            .foregroundStyle(.textSecondary)
                    }
                    .padding(.top, 60)

                    // Login Form
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("E-Mail")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.textSecondary)

                            TextField("ihre@email.de", text: $viewModel.email)
                                .textFieldStyle(.roundedBorder)
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
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.textSecondary)

                            SecureField("Passwort", text: $viewModel.password)
                                .textFieldStyle(.roundedBorder)
                                .textContentType(.password)
                                .focused($focusedField, equals: .password)
                                .submitLabel(.go)
                                .onSubmit {
                                    Task { await viewModel.login(appState: appState) }
                                }
                        }

                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.painRed)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Button {
                            Task { await viewModel.login(appState: appState) }
                        } label: {
                            Group {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Anmelden")
                                }
                            }
                            .font(.body.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.accent)
                        .disabled(viewModel.isLoading || viewModel.email.isEmpty || viewModel.password.isEmpty)
                    }
                    .padding(.horizontal, 24)

                    // Divider
                    HStack {
                        Rectangle().frame(height: 1).foregroundStyle(.textSecondary.opacity(0.3))
                        Text("oder")
                            .font(.caption)
                            .foregroundStyle(.textSecondary)
                        Rectangle().frame(height: 1).foregroundStyle(.textSecondary.opacity(0.3))
                    }
                    .padding(.horizontal, 24)

                    // Onboarding Option
                    VStack(spacing: 12) {
                        Text("Haben Sie einen Einladungscode?")
                            .font(.subheadline)
                            .foregroundStyle(.textSecondary)

                        HStack(spacing: 12) {
                            Button {
                                viewModel.showQRScanner = true
                            } label: {
                                Label("QR-Code scannen", systemImage: "qrcode.viewfinder")
                                    .font(.subheadline.weight(.medium))
                            }
                            .buttonStyle(.bordered)

                            NavigationLink {
                                TokenEntryView(viewModel: viewModel)
                            } label: {
                                Label("Code eingeben", systemImage: "keyboard")
                                    .font(.subheadline.weight(.medium))
                            }
                            .buttonStyle(.bordered)
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
                .font(.title2.bold())
                .foregroundStyle(.textPrimary)

            Text("Geben Sie den Code ein, den Sie von Ihrem Therapeuten erhalten haben.")
                .font(.body)
                .foregroundStyle(.textSecondary)
                .multilineTextAlignment(.center)

            TextField("Einladungscode", text: $viewModel.invitationToken)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.painRed)
            }

            Button {
                Task { await viewModel.validateInvitationToken() }
            } label: {
                Group {
                    if viewModel.isValidatingToken {
                        ProgressView().tint(.white)
                    } else {
                        Text("Weiter")
                    }
                }
                .font(.body.weight(.semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
            }
            .buttonStyle(.borderedProminent)
            .tint(.accent)
            .disabled(viewModel.invitationToken.isEmpty || viewModel.isValidatingToken)

            Spacer()
        }
        .padding(24)
        .background(Color.appBg)
    }
}
