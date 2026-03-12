import SwiftUI

struct LbpEnhancementsView: View {
    @Environment(APIClient.self) private var apiClient
    @Environment(LanguageManager.self) private var languageManager
    let subtype: AemSubtype

    @AppStorage("appLanguage") private var appLanguage = "de"

    @State private var viewModel: LbpEnhancementsViewModel?
    @State private var showHierarchyBuilder = false
    @State private var showTemplateSelector = false
    @State private var showActivityLog = false

    var body: some View {
        Group {
            if let vm = viewModel {
                if vm.isLoading {
                    LoadingView(message: appLanguage == "en" ? "Loading LBP data..." : "LBP-Daten laden...")
                } else {
                    content(vm)
                }
            } else {
                LoadingView()
            }
        }
        .task {
            if viewModel == nil {
                let vm = LbpEnhancementsViewModel(apiClient: apiClient, subtype: subtype)
                viewModel = vm
                await vm.loadData()
            }
        }
        .onChange(of: languageManager.language) { _, _ in
            viewModel = nil
            Task {
                let vm = LbpEnhancementsViewModel(apiClient: apiClient, subtype: subtype)
                viewModel = vm
                await vm.loadData()
            }
        }
    }

    @ViewBuilder
    private func content(_ vm: LbpEnhancementsViewModel) -> some View {
        VStack(spacing: 24) {
            switch subtype {
            case .FAR:
                farContent(vm)
            case .DER, .EER:
                pacingContent(vm)
            case .AR, .unknown:
                arContent(vm)
            }
        }
        .overlay {
            // Success / error toasts
            if let msg = vm.successMessage {
                VStack {
                    ToastBanner(message: msg, style: .success)
                        .onAppear {
                            Task { @MainActor in
                                try? await Task.sleep(for: .seconds(2))
                                vm.clearMessages()
                            }
                        }
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            if let msg = vm.errorMessage {
                VStack {
                    ToastBanner(message: msg, style: .error)
                        .onTapGesture { vm.clearMessages() }
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut, value: vm.successMessage)
        .animation(.easeInOut, value: vm.errorMessage)
    }

    // MARK: - FAR Content

    @ViewBuilder
    private func farContent(_ vm: LbpEnhancementsViewModel) -> some View {
        // Fear hierarchy
        FearHierarchyView(viewModel: vm)

        // Build/edit button
        Button {
            showHierarchyBuilder = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: vm.fearHierarchy != nil ? "pencil" : "plus.circle.fill")
                Text(vm.fearHierarchy != nil
                    ? (appLanguage == "en" ? "Edit hierarchy" : "Hierarchie bearbeiten")
                    : (appLanguage == "en" ? "Create hierarchy" : "Hierarchie erstellen"))
            }
            .font(.appSubheadlineMedium)
            .foregroundStyle(.farBlue)
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .background(Color.farBlue.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.buttonRadius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: DesignTokens.buttonRadius, style: .continuous).stroke(Color.gray200, lineWidth: 1))
        }
        .sheet(isPresented: $showHierarchyBuilder) {
            FearHierarchyBuilderView(viewModel: vm)
        }
    }

    // MARK: - Pacing Content (DER/EER)

    @ViewBuilder
    private func pacingContent(_ vm: LbpEnhancementsViewModel) -> some View {
        if let plan = vm.pacingPlan {
            if plan.baselineMode {
                // Baseline tracking mode
                BaselineTrackerView(viewModel: vm)
            } else {
                // Active pacing plan
                PacingPlanView(viewModel: vm)

                // Timer
                PacingTimerView(viewModel: vm)

                // Log activity button
                Button {
                    showActivityLog = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                        Text(appLanguage == "en" ? "Log activity" : "Aktivität protokollieren")
                    }
                    .font(.appBodySemibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.subtypeColor(for: subtype))
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.buttonRadius, style: .continuous))
                }
                .sheet(isPresented: $showActivityLog) {
                    PacingActivityLogSheet(viewModel: vm)
                }

                // Quota progression
                QuotaProgressionView(viewModel: vm)

                // Adjustment history
                PacingAdjustmentHistoryView(viewModel: vm)
            }
        } else {
            // No plan yet - show template selector
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Image(systemName: "gauge.with.dots.needle.bottom.50percent")
                        .font(.system(size: 36))
                        .foregroundStyle(Color.subtypeColor(for: subtype))
                    Text(appLanguage == "en" ? "No pacing plan yet" : "Noch kein Pacing-Plan")
                        .font(.appHeadline)
                        .foregroundStyle(.textPrimary)
                    Text(appLanguage == "en" ? "Activate a plan tailored to your profile." : "Aktivieren Sie einen auf Ihr Profil zugeschnittenen Plan.")
                        .font(.appSubheadline)
                        .foregroundStyle(.textSecondary)
                        .multilineTextAlignment(.center)
                }

                Button {
                    showTemplateSelector = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                        Text(appLanguage == "en" ? "Activate plan" : "Plan aktivieren")
                    }
                    .font(.appBodySemibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.subtypeColor(for: subtype))
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.buttonRadius, style: .continuous))
                }
                .sheet(isPresented: $showTemplateSelector) {
                    PacingTemplateSelector(viewModel: vm)
                }
            }
            .cardStyle(padding: 24)
        }
    }

    // MARK: - AR Content

    @ViewBuilder
    private func arContent(_ vm: LbpEnhancementsViewModel) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "chart.bar.fill")
                    .font(.appTitle3)
                    .foregroundStyle(.arGray)
                Text(appLanguage == "en" ? "Adaptive Overview" : "Adaptive Übersicht")
                    .font(.appHeadline)
                    .foregroundStyle(.textPrimary)
                Spacer()
            }

            Text(appLanguage == "en"
                ? "As an Adaptive Responder, you have a balanced coping pattern. Your program follows standard progression."
                : "Als Adaptive Responder haben Sie ein ausgeglichenes Bewältigungsmuster. Ihr Programm folgt der Standard-Progression.")
                .font(.appSubheadline)
                .foregroundStyle(.textSecondary)
        }
        .cardStyle()
    }
}

// MARK: - Toast Banner

struct ToastBanner: View {
    let message: String
    let style: ToastStyle

    enum ToastStyle {
        case success, error

        var color: Color {
            switch self {
            case .success: return .painGreen
            case .error: return .painRed
            }
        }

        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "exclamationmark.triangle.fill"
            }
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: style.icon)
                .foregroundStyle(.white)
            Text(message)
                .font(.appSubheadlineMedium)
                .foregroundStyle(.white)
            Spacer()
        }
        .padding(14)
        .background(style.color)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.smallRadius, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}
