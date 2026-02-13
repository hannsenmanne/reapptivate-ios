import SwiftUI

// MARK: - Outfit Font Integration

extension Font {
    // Semantic sizes matching iOS defaults but using Outfit
    static let appLargeTitle = Font.custom("Outfit-ExtraBold", size: 34)
    static let appTitle = Font.custom("Outfit-Bold", size: 28)
    static let appTitle2 = Font.custom("Outfit-Bold", size: 22)
    static let appTitle3 = Font.custom("Outfit-SemiBold", size: 20)
    static let appHeadline = Font.custom("Outfit-SemiBold", size: 17)
    static let appBody = Font.custom("Outfit-Regular", size: 17)
    static let appSubheadline = Font.custom("Outfit-Regular", size: 15)
    static let appCaption = Font.custom("Outfit-Regular", size: 12)
    static let appCaption2 = Font.custom("Outfit-Regular", size: 11)

    // Weighted variants for common patterns
    static let appSubheadlineMedium = Font.custom("Outfit-Medium", size: 15)
    static let appSubheadlineSemibold = Font.custom("Outfit-SemiBold", size: 15)
    static let appCaptionMedium = Font.custom("Outfit-Medium", size: 12)
    static let appCaptionBold = Font.custom("Outfit-Bold", size: 12)
    static let appBodySemibold = Font.custom("Outfit-SemiBold", size: 17)

    // Custom sizes
    static func outfit(_ weight: OutfitWeight, size: CGFloat) -> Font {
        Font.custom(weight.fontName, size: size)
    }
}

enum OutfitWeight {
    case light, regular, medium, semibold, bold, extraBold

    var fontName: String {
        switch self {
        case .light: "Outfit-Light"
        case .regular: "Outfit-Regular"
        case .medium: "Outfit-Medium"
        case .semibold: "Outfit-SemiBold"
        case .bold: "Outfit-Bold"
        case .extraBold: "Outfit-ExtraBold"
        }
    }
}
