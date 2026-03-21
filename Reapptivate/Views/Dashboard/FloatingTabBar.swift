import SwiftUI

struct FloatingTabBar: View {
    @Binding var selectedTab: DashboardTab
    let showInsights: Bool
    @Namespace private var tabNamespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("appLanguage") private var appLanguage = "de"

    private var tabs: [DashboardTab] {
        var result: [DashboardTab] = [.overview, .program, .edukation, .progress]
        if showInsights {
            result.append(.insights)
        }
        return result
    }

    // MARK: - Glass Colors

    private var glassFill: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.06)
            : Color.white.opacity(0.55)
    }

    private var glassStroke: LinearGradient {
        LinearGradient(
            colors: [
                colorScheme == .dark
                    ? Color.white.opacity(0.14)
                    : Color.white.opacity(0.6),
                colorScheme == .dark
                    ? Color.white.opacity(0.03)
                    : Color.white.opacity(0.1)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var selectionFill: some ShapeStyle {
        colorScheme == .dark
            ? Color.white.opacity(0.12)
            : Color.white.opacity(0.7)
    }

    private var selectionStroke: some ShapeStyle {
        colorScheme == .dark
            ? Color.white.opacity(0.18)
            : Color.white.opacity(0.5)
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.self) { tab in
                let isSelected = selectedTab == tab

                Button {
                    if reduceMotion {
                        selectedTab = tab
                    } else {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.78)) {
                            selectedTab = tab
                        }
                    }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: isSelected ? tab.iconFilled : tab.icon)
                            .font(.system(size: 17, weight: isSelected ? .semibold : .regular))
                            .frame(width: 40, height: 30)
                            .background {
                                if isSelected {
                                    Capsule()
                                        .fill(selectionFill)
                                        .overlay {
                                            Capsule()
                                                .strokeBorder(selectionStroke, lineWidth: 0.5)
                                        }
                                        .shadow(
                                            color: colorScheme == .dark
                                                ? Color.white.opacity(0.04)
                                                : Color.black.opacity(0.06),
                                            radius: 4, y: 1
                                        )
                                        .matchedGeometryEffect(id: "tabIndicator", in: tabNamespace)
                                }
                            }

                        Text(tab.displayName)
                            .font(.outfit(.medium, size: 10))
                            .lineLimit(1)
                    }
                    .foregroundStyle(isSelected ? .accent : .textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 48)
                    .contentShape(Rectangle())
                }
                .accessibilityLabel(tab.displayName)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay {
                    Capsule()
                        .fill(glassFill)
                }
                .overlay {
                    Capsule()
                        .strokeBorder(glassStroke, lineWidth: 0.5)
                }
        }
        .clipShape(Capsule())
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.35 : 0.08), radius: 16, y: 6)
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.15 : 0.04), radius: 2, y: 1)
        .padding(.horizontal, 16)
        .conditionalHaptic(.selection, trigger: selectedTab)
    }
}
