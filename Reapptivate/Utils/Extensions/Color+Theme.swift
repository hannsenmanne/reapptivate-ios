import SwiftUI

extension Color {
    // MARK: - Backgrounds
    static let appBackground = Color("AppBackground", bundle: nil)
    static let cardBackground = Color("CardBackground", bundle: nil)

    // Fallback colors when asset catalog colors aren't set up yet
    static let appBg = Color(light: .white, dark: Color(hex: "1C1C1E"))
    static let cardBg = Color(light: Color(hex: "F5F5F5"), dark: Color(hex: "2C2C2E"))

    // MARK: - Pain Level Colors
    static let painGreen = Color(hex: "10B981")
    static let painAmber = Color(hex: "F59E0B")
    static let painRed = Color(hex: "EF4444")

    // MARK: - AEM Subtype Colors
    static let farBlue = Color(hex: "3B82F6")
    static let derOrange = Color(hex: "F97316")
    static let eerGreen = Color(hex: "22C55E")
    static let arGray = Color(hex: "6B7280")

    // MARK: - NDI Severity Colors
    static let severityLeicht = Color(hex: "22C55E")
    static let severityMittel = Color(hex: "F59E0B")
    static let severitySchwer = Color(hex: "EF4444")

    // MARK: - Phase Decision Colors
    static let phaseProgress = Color(hex: "10B981")
    static let phaseHold = Color(hex: "6B7280")
    static let phaseRegress = Color(hex: "EF4444")
    static let phaseInitial = Color(hex: "3B82F6")

    // MARK: - UI Accents
    static let accent = Color(hex: "1F2937")
    static let textPrimary = Color(light: Color(hex: "1F2937"), dark: .white)
    static let textSecondary = Color(light: Color(hex: "6B7280"), dark: Color(hex: "9CA3AF"))

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

    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(dark)
                : UIColor(light)
        })
    }
}
