import SwiftUI

struct FloatingTabBar: View {
    @Binding var selectedTab: DashboardTab
    let showInsights: Bool
    @Namespace private var tabNamespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("appLanguage") private var appLanguage = "de"

    private var tabs: [DashboardTab] {
        var result: [DashboardTab] = [.overview, .program, .edukation, .progress]
        if showInsights {
            result.append(.insights)
        }
        return result
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.self) { tab in
                Button {
                    if reduceMotion {
                        selectedTab = tab
                    } else {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            selectedTab = tab
                        }
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 18))
                            .frame(width: 36, height: 28)
                            .background {
                                if selectedTab == tab {
                                    Capsule()
                                        .fill(Color.accent.opacity(0.15))
                                        .matchedGeometryEffect(id: "tabIndicator", in: tabNamespace)
                                }
                            }

                        Text(tab.displayName)
                            .font(.outfit(.medium, size: 10))
                            .lineLimit(1)
                    }
                    .foregroundStyle(selectedTab == tab ? .accent : .textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 48)
                    .contentShape(Rectangle())
                }
                .accessibilityLabel(tab.displayName)
                .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(.regularMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
        .padding(.horizontal, 16)
        .conditionalHaptic(.selection, trigger: selectedTab)
    }
}
