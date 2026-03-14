import SwiftUI

/// Renders markdown content with proper paragraph spacing and inline formatting (bold, italic).
/// Matches the formatting approach used in the companion web app's MicroModuleCard.
struct MarkdownContentView: View {
    let attributedParagraphs: [AttributedString]
    let font: Font
    let color: Color

    init(_ content: String, font: Font = .appSubheadline, color: Color = .textSecondary) {
        self.font = font
        self.color = color
        self.attributedParagraphs = content
            .components(separatedBy: "\n\n")
            .filter { !$0.isEmpty }
            .map { text in
                (try? AttributedString(
                    markdown: text,
                    options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
                )) ?? AttributedString(text)
            }
    }

    var body: some View {
        if !attributedParagraphs.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(attributedParagraphs.enumerated()), id: \.offset) { _, paragraph in
                    Text(paragraph)
                        .font(font)
                        .foregroundStyle(color)
                        .lineSpacing(3)
                }
            }
        }
    }
}
