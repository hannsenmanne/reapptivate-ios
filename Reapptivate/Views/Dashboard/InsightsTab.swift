import SwiftUI

struct InsightsTab: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        if let subtype = appState.currentUser?.aemSubtype {
            // LBP patients: AEM analytics dashboard
            AnalyticsDashboardView(subtype: subtype)
        } else if appState.isNeck {
            // Neck patients: NDI progress, focus areas, micro-modules
            NeckInsightsSection()
        } else {
            EmptyStateView(
                icon: "chart.bar.xaxis",
                title: "Keine Insights verfugbar",
                message: "Insights werden nach dem Screening freigeschaltet."
            )
        }
    }
}

// MARK: - Neck Insights

struct NeckInsightsSection: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 20) {
            // NDI Progress / History
            NdiProgressView()

            // Focus Areas
            NeckFocusAreasView()

            // Neck Micro-Modules
            if let severity = appState.currentUser?.ndiSeverity {
                NeckMicroModulesView(severity: severity)
            }
        }
        .padding(.bottom, 32)
    }
}
