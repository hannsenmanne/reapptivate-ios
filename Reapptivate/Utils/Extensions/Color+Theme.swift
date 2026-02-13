import SwiftUI

extension Color {
    // MARK: - Backgrounds (Cool neutral palette)
    static let appBg = Color(hex: "F8F8FA")        // Cool near-white page background
    static let cardBg = Color.white                 // White cards
    static let beigeDark = Color(hex: "EEEEF0")    // Subtle dividers, secondary bg
    static let beigeLight = Color(hex: "FBFBFD")   // Lightest background

    // MARK: - Neutrals (Cool gray scale)
    static let gray100 = Color(hex: "F5F5F7")
    static let gray200 = Color(hex: "E5E7EB")      // Borders, dividers
    static let gray300 = Color(hex: "D1D5DB")       // Input borders
    static let gray400 = Color(hex: "9CA3AF")       // Disabled text
    static let gray500 = Color(hex: "6B7280")       // Secondary text
    static let gray600 = Color(hex: "4B5563")       // Body text alt

    // MARK: - Pain Level Colors
    static let painGreen = Color(hex: "10B981")     // Emerald — safe/good
    static let painAmber = Color(hex: "D97706")     // Amber — moderate
    static let painRed = Color(hex: "EF4444")       // Red — warning/danger

    // MARK: - AEM Subtype Colors
    static let farBlue = Color(hex: "3B82F6")
    static let derOrange = Color(hex: "FB923C")     // Web: #FB923C (was F97316)
    static let eerGreen = Color(hex: "10B981")      // Web: emerald (was 22C55E)
    static let arGray = Color(hex: "6B7280")

    // MARK: - NDI Severity Colors
    static let severityLeicht = Color(hex: "10B981") // Emerald (was 22C55E)
    static let severityMittel = Color(hex: "F59E0B")
    static let severitySchwer = Color(hex: "EF4444")

    // MARK: - Phase Decision Colors
    static let phaseProgress = Color(hex: "10B981")  // Emerald
    static let phaseHold = Color(hex: "6B7280")       // Gray
    static let phaseRegress = Color(hex: "EF4444")    // Red
    static let phaseInitial = Color(hex: "3B82F6")    // Blue

    // MARK: - UI Accents & Text
    static let accent = Color(hex: "10B981")          // Emerald accent (was 1F2937)
    static let textPrimary = Color(hex: "1A1A1A")      // Near-black (softer)
    static let textSecondary = Color(hex: "6B7280")    // Cool gray

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
        case .AR: return .arGray
        }
    }

    static func severityColor(for severity: NdiSeverityGrade) -> Color {
        switch severity {
        case .LEICHT: return .severityLeicht
        case .MITTEL: return .severityMittel
        case .SCHWER: return .severitySchwer
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

    static var gray200: Color { Color.gray200 }
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
