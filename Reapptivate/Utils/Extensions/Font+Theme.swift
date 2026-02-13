import SwiftUI

// MARK: - Outfit Font Integration

extension Font {
    // Semantic sizes matching iOS defaults but using Outfit (Dynamic Type enabled)
    static let appLargeTitle = Font.custom("Outfit-ExtraBold", size: 34, relativeTo: .largeTitle)
    static let appTitle = Font.custom("Outfit-Bold", size: 28, relativeTo: .title)
    static let appTitle2 = Font.custom("Outfit-Bold", size: 22, relativeTo: .title2)
    static let appTitle3 = Font.custom("Outfit-SemiBold", size: 20, relativeTo: .title3)
    static let appHeadline = Font.custom("Outfit-SemiBold", size: 17, relativeTo: .headline)
    static let appBody = Font.custom("Outfit-Regular", size: 17, relativeTo: .body)
    static let appSubheadline = Font.custom("Outfit-Regular", size: 15, relativeTo: .subheadline)
    static let appCaption = Font.custom("Outfit-Regular", size: 12, relativeTo: .caption)
    static let appCaption2 = Font.custom("Outfit-Regular", size: 11, relativeTo: .caption2)

    // Weighted variants for common patterns
    static let appSubheadlineMedium = Font.custom("Outfit-Medium", size: 15, relativeTo: .subheadline)
    static let appSubheadlineSemibold = Font.custom("Outfit-SemiBold", size: 15, relativeTo: .subheadline)
    static let appCaptionMedium = Font.custom("Outfit-Medium", size: 12, relativeTo: .caption)
    static let appCaptionBold = Font.custom("Outfit-Bold", size: 12, relativeTo: .caption)
    static let appBodySemibold = Font.custom("Outfit-SemiBold", size: 17, relativeTo: .body)

    // Custom sizes
    static func outfit(_ weight: OutfitWeight, size: CGFloat, relativeTo textStyle: Font.TextStyle = .body) -> Font {
        Font.custom(weight.fontName, size: size, relativeTo: textStyle)
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
