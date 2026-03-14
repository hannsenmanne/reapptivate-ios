import SwiftUI

// MARK: - Design Tokens

enum DesignTokens {
    static let cardRadius: CGFloat = 14
    static let buttonRadius: CGFloat = 12
    static let inputRadius: CGFloat = 10
    static let badgeRadius: CGFloat = 8
    static let smallRadius: CGFloat = 8
    static let iconRadius: CGFloat = 10
    static let progressBarRadius: CGFloat = 4

    static let cardShadowColor = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.04)
            : UIColor.black.withAlphaComponent(0.06)
    })
    static let cardShadowRadius: CGFloat = 8
    static let cardShadowY: CGFloat = 2
}

// MARK: - Glass Card Helpers

private let glassStroke = LinearGradient(
    colors: [
        Color(UIColor { tc in
            tc.userInterfaceStyle == .dark
                ? .white.withAlphaComponent(0.12)
                : .white.withAlphaComponent(0.25)
        }),
        Color(UIColor { tc in
            tc.userInterfaceStyle == .dark
                ? .white.withAlphaComponent(0.02)
                : .white.withAlphaComponent(0.05)
        })
    ],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)

// MARK: - Card Style (Glass, frosted, subtle stroke)

struct CardStyle: ViewModifier {
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: DesignTokens.cardRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: DesignTokens.cardRadius, style: .continuous)
                            .fill(Color.cardBg.opacity(0.72))
                    }
            }
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cardRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: DesignTokens.cardRadius, style: .continuous)
                    .strokeBorder(glassStroke, lineWidth: 0.5)
            }
            .shadow(
                color: DesignTokens.cardShadowColor,
                radius: DesignTokens.cardShadowRadius,
                y: DesignTokens.cardShadowY
            )
    }
}

struct AccentCardStyle: ViewModifier {
    var accentColor: Color = .accent
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .padding(.leading, 4)
            .background {
                RoundedRectangle(cornerRadius: DesignTokens.cardRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: DesignTokens.cardRadius, style: .continuous)
                            .fill(Color.cardBg.opacity(0.72))
                    }
            }
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cardRadius, style: .continuous))
            .overlay(alignment: .leading) {
                UnevenRoundedRectangle(
                    topLeadingRadius: DesignTokens.cardRadius,
                    bottomLeadingRadius: DesignTokens.cardRadius,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 0,
                    style: .continuous
                )
                .fill(accentColor)
                .frame(width: 4)
            }
            .overlay {
                RoundedRectangle(cornerRadius: DesignTokens.cardRadius, style: .continuous)
                    .strokeBorder(glassStroke, lineWidth: 0.5)
            }
            .shadow(
                color: DesignTokens.cardShadowColor,
                radius: DesignTokens.cardShadowRadius,
                y: DesignTokens.cardShadowY
            )
    }
}

extension View {
    func cardStyle(padding: CGFloat = 16) -> some View {
        modifier(CardStyle(padding: padding))
    }

    func accentCardStyle(color: Color = .accent, padding: CGFloat = 16) -> some View {
        modifier(AccentCardStyle(accentColor: color, padding: padding))
    }
}

// MARK: - Primary Button Style (Gradient, inner highlight, spring press)

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.appBodySemibold)
            .foregroundStyle(isEnabled ? Color.appBg : .white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background {
                RoundedRectangle(cornerRadius: DesignTokens.buttonRadius, style: .continuous)
                    .fill(
                        isEnabled
                            ? LinearGradient(
                                colors: [Color.textPrimary, Color.textPrimary.opacity(0.85)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            : LinearGradient(
                                colors: [Color.gray400, Color.gray400],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: DesignTokens.buttonRadius, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
                    }
            }
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.buttonRadius, style: .continuous))
            .shadow(color: Color.black.opacity(0.12), radius: 4, y: 2)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Secondary Button Style (Glass material, spring press)

struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.appSubheadlineMedium)
            .foregroundStyle(isEnabled ? .textPrimary : .gray400)
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.buttonRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.buttonRadius, style: .continuous)
                    .strokeBorder(glassStroke, lineWidth: 0.5)
            )
            .opacity(isEnabled ? 1.0 : 0.6)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Accent Button Style (Emerald gradient, inner highlight, spring press)

struct AccentButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.appBodySemibold)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background {
                RoundedRectangle(cornerRadius: DesignTokens.buttonRadius, style: .continuous)
                    .fill(
                        isEnabled
                            ? LinearGradient(
                                colors: [Color.accent, Color.accent.opacity(0.82)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            : LinearGradient(
                                colors: [Color.gray400, Color.gray400],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: DesignTokens.buttonRadius, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5)
                    }
            }
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.buttonRadius, style: .continuous))
            .shadow(color: Color.accent.opacity(0.25), radius: 6, y: 3)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}

extension ButtonStyle where Self == AccentButtonStyle {
    static var accentFilled: AccentButtonStyle { AccentButtonStyle() }
}

// MARK: - Input Field Style (Rounded text fields)

struct InputFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.appBody)
            .padding(12)
            .background(Color.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.inputRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.inputRadius, style: .continuous)
                    .stroke(Color.gray300, lineWidth: 1)
            )
    }
}

extension View {
    func inputFieldStyle() -> some View {
        modifier(InputFieldStyle())
    }
}

// MARK: - Badge Style (Rounded pills)

struct BadgeStyle: ViewModifier {
    var color: Color

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.badgeRadius, style: .continuous))
    }
}

extension View {
    func badgeStyle(color: Color) -> some View {
        modifier(BadgeStyle(color: color))
    }
}

// MARK: - Info Box Style (Highlight boxes)

struct InfoBoxStyle: ViewModifier {
    var color: Color

    func body(content: Content) -> some View {
        content
            .padding(12)
            .background(color.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.smallRadius, style: .continuous))
    }
}

extension View {
    func infoBoxStyle(color: Color) -> some View {
        modifier(InfoBoxStyle(color: color))
    }
}

// MARK: - Card Entry Animation (Staggered spring fade-in)

struct CardEntryAnimation: ViewModifier {
    let index: Int

    @State private var isVisible = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 16)
            .scaleEffect(isVisible ? 1 : 0.96, anchor: .top)
            .onAppear {
                if reduceMotion {
                    isVisible = true
                } else {
                    withAnimation(
                        .spring(response: 0.5, dampingFraction: 0.78)
                        .delay(Double(index) * 0.07)
                    ) {
                        isVisible = true
                    }
                }
            }
    }
}

extension View {
    func cardEntryAnimation(index: Int) -> some View {
        modifier(CardEntryAnimation(index: index))
    }
}

// MARK: - App Background (Ambient gradient)

struct AppBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    Color.appBg

                    RadialGradient(
                        colors: [
                            Color.accent.opacity(0.06),
                            Color.clear
                        ],
                        center: .top,
                        startRadius: 0,
                        endRadius: 500
                    )
                    .ignoresSafeArea()
                }
            }
    }
}

extension View {
    func appBackground() -> some View {
        modifier(AppBackgroundModifier())
    }
}

// MARK: - Glass Sheet Style

struct GlassSheetModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .presentationCornerRadius(28)
            .presentationBackground(.regularMaterial)
            .presentationDragIndicator(.visible)
    }
}

extension View {
    func glassSheet() -> some View {
        modifier(GlassSheetModifier())
    }
}

// MARK: - Glowing Icon Container

struct GlowingIconContainer: View {
    let icon: String
    let color: Color
    var size: CGFloat = 44
    var iconSize: CGFloat = 18
    var radius: CGFloat = DesignTokens.badgeRadius + 2
    var isFilled: Bool = true

    var body: some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(
                isFilled
                    ? LinearGradient(
                        colors: [color, color.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    : LinearGradient(
                        colors: [color.opacity(0.12), color.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
            )
            .frame(width: size, height: size)
            .overlay {
                if isFilled {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5)
                }
            }
            .overlay {
                Image(systemName: icon)
                    .font(.system(size: iconSize, weight: .semibold))
                    .foregroundStyle(isFilled ? .white : color)
            }
            .shadow(color: color.opacity(isFilled ? 0.3 : 0.15), radius: 8, y: 2)
    }
}
