import SwiftUI

// MARK: - Design Tokens

enum DesignTokens {
    static let cardRadius: CGFloat = 14
    static let buttonRadius: CGFloat = 12
    static let inputRadius: CGFloat = 10
    static let badgeRadius: CGFloat = 8
    static let smallRadius: CGFloat = 8
    static let iconRadius: CGFloat = 10

    static let cardShadowColor = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.04)
            : UIColor.black.withAlphaComponent(0.06)
    })
    static let cardShadowRadius: CGFloat = 8
    static let cardShadowY: CGFloat = 2
}

// MARK: - Card Style (Rounded, shadow, white bg)

struct CardStyle: ViewModifier {
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cardRadius, style: .continuous))
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
            .background(Color.cardBg)
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

// MARK: - Primary Button Style (Dark bg, rounded, spring press)

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.appBodySemibold)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(isEnabled ? Color.textPrimary : Color.gray400)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.buttonRadius, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Secondary Button Style (Border, rounded, spring press)

struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.appSubheadlineMedium)
            .foregroundStyle(isEnabled ? .textPrimary : .gray400)
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .background(Color.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.buttonRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.buttonRadius, style: .continuous)
                    .stroke(isEnabled ? Color.gray300 : Color.gray200, lineWidth: 1)
            )
            .opacity(isEnabled ? 1.0 : 0.6)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Accent Button Style (Emerald bg, rounded, spring press)

struct AccentButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.appBodySemibold)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(isEnabled ? Color.accent : Color.gray400)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.buttonRadius, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
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
