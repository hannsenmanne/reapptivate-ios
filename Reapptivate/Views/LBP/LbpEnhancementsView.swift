import SwiftUI

struct LbpEnhancementsView: View {
    @Environment(APIClient.self) private var apiClient
    let subtype: AemSubtype

    @State private var viewModel: LbpEnhancementsViewModel?
    @State private var showHierarchyBuilder = false
    @State private var showTemplateSelector = false
    @State private var showActivityLog = false

    var body: some View {
        Group {
            if let vm = viewModel {
                if vm.isLoading {
                    LoadingView(message: "LBP-Daten laden...")
                } else {
                    content(vm)
                }
            } else {
                LoadingView()
            }
        }
        .task {
            let vm = LbpEnhancementsViewModel(apiClient: apiClient, subtype: subtype)
            viewModel = vm
            await vm.loadData()
        }
    }

    @ViewBuilder
    private func content(_ vm: LbpEnhancementsViewModel) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                switch subtype {
                case .FAR:
                    farContent(vm)
                case .DER, .EER:
                    pacingContent(vm)
                case .AR:
                    arContent(vm)
                }

                // Micro-modules (all subtypes)
                MicroModulesList(viewModel: vm)
            }
            .padding(16)
        }
        .background(Color.appBg)
        .overlay {
            // Success / error toasts
            if let msg = vm.successMessage {
                VStack {
                    ToastBanner(message: msg, style: .success)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
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
                Text(vm.fearHierarchy != nil ? "Hierarchie bearbeiten" : "Hierarchie erstellen")
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.farBlue)
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .background(Color.farBlue.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 10))
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
                        Text("Aktivitat protokollieren")
                    }
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.subtypeColor(for: subtype))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
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
                    Text("Noch kein Pacing-Plan")
                        .font(.headline)
                        .foregroundStyle(.textPrimary)
                    Text("Aktivieren Sie einen auf Ihr Profil zugeschnittenen Plan.")
                        .font(.subheadline)
                        .foregroundStyle(.textSecondary)
                        .multilineTextAlignment(.center)
                }

                Button {
                    showTemplateSelector = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                        Text("Plan aktivieren")
                    }
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.subtypeColor(for: subtype))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .sheet(isPresented: $showTemplateSelector) {
                    PacingTemplateSelector(viewModel: vm)
                }
            }
            .padding(24)
            .background(Color.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - AR Content

    @ViewBuilder
    private func arContent(_ vm: LbpEnhancementsViewModel) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "chart.bar.fill")
                    .font(.title3)
                    .foregroundStyle(.arGray)
                Text("Adaptive Ubersicht")
                    .font(.headline)
                    .foregroundStyle(.textPrimary)
                Spacer()
            }

            Text("Als Adaptive Responder haben Sie ein ausgeglichenes Bewältigungsmuster. Ihr Programm folgt der Standard-Progression.")
                .font(.subheadline)
                .foregroundStyle(.textSecondary)
        }
        .padding(16)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
            Spacer()
        }
        .padding(14)
        .background(style.color)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}
