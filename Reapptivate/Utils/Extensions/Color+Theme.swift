import SwiftUI

// MARK: - Adaptive Color Helper

extension Color {
    /// Creates a color that adapts to light/dark mode using UIColor's trait collection
    private static func adaptive(light: String, dark: String) -> Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(Color(hex: dark))
                : UIColor(Color(hex: light))
        })
    }

    // MARK: - Backgrounds (Cool neutral palette)
    static let appBg = adaptive(light: "F8F8FA", dark: "121214")
    static let cardBg = adaptive(light: "FFFFFF", dark: "1C1C1E")
    static let beigeDark = adaptive(light: "EEEEF0", dark: "2C2C2E")
    static let beigeLight = adaptive(light: "FBFBFD", dark: "1A1A1C")

    // MARK: - Neutrals (Cool gray scale)
    static let gray100 = adaptive(light: "F5F5F7", dark: "2C2C2E")
    static let gray200 = adaptive(light: "E5E7EB", dark: "3A3A3C")
    static let gray300 = adaptive(light: "D1D5DB", dark: "48484A")
    static let gray400 = adaptive(light: "9CA3AF", dark: "636366")
    static let gray500 = adaptive(light: "6B7280", dark: "8E8E93")
    static let gray600 = adaptive(light: "4B5563", dark: "AEAEB2")

    // MARK: - Pain Level Colors (vivid — work in both modes)
    static let painGreen = Color(hex: "10B981")
    static let painAmber = Color(hex: "D97706")
    static let painRed = Color(hex: "EF4444")

    // MARK: - AEM Subtype Colors
    static let farBlue = Color(hex: "3B82F6")
    static let derOrange = Color(hex: "FB923C")
    static let eerGreen = Color(hex: "10B981")
    static let arGray = adaptive(light: "6B7280", dark: "8E8E93")

    // MARK: - NDI Severity Colors
    static let severityLeicht = Color(hex: "10B981")
    static let severityMittel = Color(hex: "F59E0B")
    static let severitySchwer = Color(hex: "EF4444")

    // MARK: - Phase Decision Colors
    static let phaseProgress = Color(hex: "10B981")
    static let phaseHold = adaptive(light: "6B7280", dark: "8E8E93")
    static let phaseRegress = Color(hex: "EF4444")
    static let phaseInitial = Color(hex: "3B82F6")

    // MARK: - UI Accents & Text
    static let accent = adaptive(light: "10B981", dark: "34D399")
    static let textPrimary = adaptive(light: "1A1A1A", dark: "F2F2F7")
    static let textSecondary = adaptive(light: "6B7280", dark: "8E8E93")
    static let textTertiary = adaptive(light: "9CA3AF", dark: "636366")

    // MARK: - Pain Level Helpers

    static func painColor(for level: Int, maxPainLevel: Int = 3) -> Color {
        if level <= maxPainLevel {
            return .painGreen
        } else if level <= maxPainLevel + 1 {
            return .painAmber
        } else {
            return .painRed
        }
    }

    static func subtypeColor(for subtype: AemSubtype) -> Color {
        switch subtype {
        case .FAR: return .farBlue
        case .DER: return .derOrange
        case .EER: return .eerGreen
        case .AR, .unknown: return .arGray
        }
    }

    static func severityColor(for severity: NdiSeverityGrade) -> Color {
        switch severity {
        case .LEICHT: return .severityLeicht
        case .MITTEL: return .severityMittel
        case .SCHWER, .unknown: return .severitySchwer
        }
    }

    static func severityColor(for severity: TsiSeverityGrade) -> Color {
        switch severity {
        case .LEICHT: return .severityLeicht
        case .MITTEL: return .severityMittel
        case .SCHWER, .unknown: return .severitySchwer
        }
    }

    static func severityColor(for severity: SiSeverityGrade) -> Color {
        switch severity {
        case .LEICHT: return .severityLeicht
        case .MITTEL: return .severityMittel
        case .SCHWER, .unknown: return .severitySchwer
        }
    }

    static func severityColor(for severity: FsSeverityGrade) -> Color {
        switch severity {
        case .LEICHT: return .severityLeicht
        case .MITTEL: return .severityMittel
        case .SCHWER, .unknown: return .severitySchwer
        }
    }
}

// MARK: - ShapeStyle convenience (enables .foregroundStyle(.textPrimary) syntax)

extension ShapeStyle where Self == Color {
    static var appBg: Color { Color.appBg }
    static var cardBg: Color { Color.cardBg }
    static var beigeDark: Color { Color.beigeDark }

    static var painGreen: Color { Color.painGreen }
    static var painAmber: Color { Color.painAmber }
    static var painRed: Color { Color.painRed }

    static var farBlue: Color { Color.farBlue }
    static var derOrange: Color { Color.derOrange }
    static var eerGreen: Color { Color.eerGreen }
    static var arGray: Color { Color.arGray }

    static var severityLeicht: Color { Color.severityLeicht }
    static var severityMittel: Color { Color.severityMittel }
    static var severitySchwer: Color { Color.severitySchwer }

    static var phaseProgress: Color { Color.phaseProgress }
    static var phaseHold: Color { Color.phaseHold }
    static var phaseRegress: Color { Color.phaseRegress }
    static var phaseInitial: Color { Color.phaseInitial }

    static var accent: Color { Color.accent }
    static var textPrimary: Color { Color.textPrimary }
    static var textSecondary: Color { Color.textSecondary }
    static var textTertiary: Color { Color.textTertiary }

    static var gray200: Color { Color.gray200 }
    static var gray300: Color { Color.gray300 }
    static var gray400: Color { Color.gray400 }
}

// MARK: - Hex Color Init

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
