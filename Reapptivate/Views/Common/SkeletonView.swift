import SwiftUI

// MARK: - Skeleton Shape Variant

enum SkeletonVariant {
    case card(height: CGFloat = 120)
    case line(width: CGFloat? = nil, height: CGFloat = 14)
    case circle(diameter: CGFloat = 40)
}

// MARK: - Skeleton View

struct SkeletonView: View {
    let variant: SkeletonVariant

    @State private var shimmerOffset: CGFloat = -1

    private var baseColor: Color { .gray200 }
    private var shimmerColor: Color { .gray100 }

    var body: some View {
        content
            .overlay {
                GeometryReader { geo in
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: shimmerColor.opacity(0.6), location: 0.5),
                            .init(color: .clear, location: 1)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 0.6)
                    .offset(x: geo.size.width * shimmerOffset)
                    .clipped()
                }
                .clipShape(shapeForClipping)
            }
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 1.2)
                    .repeatForever(autoreverses: false)
                ) {
                    shimmerOffset = 1.6
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        switch variant {
        case .card(let height):
            RoundedRectangle(cornerRadius: DesignTokens.cardRadius, style: .continuous)
                .fill(baseColor)
                .frame(height: height)

        case .line(let width, let height):
            RoundedRectangle(cornerRadius: height / 2, style: .continuous)
                .fill(baseColor)
                .frame(width: width, height: height)
                .frame(maxWidth: width == nil ? .infinity : nil, alignment: .leading)

        case .circle(let diameter):
            Circle()
                .fill(baseColor)
                .frame(width: diameter, height: diameter)
        }
    }

    private var shapeForClipping: some Shape {
        switch variant {
        case .card:
            AnyShape(RoundedRectangle(cornerRadius: DesignTokens.cardRadius, style: .continuous))
        case .line(_, let height):
            AnyShape(RoundedRectangle(cornerRadius: height / 2, style: .continuous))
        case .circle:
            AnyShape(Circle())
        }
    }
}

// MARK: - Dashboard Skeleton Placeholders

struct OverviewSkeletonView: View {
    var body: some View {
        VStack(spacing: 20) {
            // Stats row
            HStack(spacing: 12) {
                SkeletonView(variant: .card(height: 60))
                SkeletonView(variant: .card(height: 60))
                SkeletonView(variant: .card(height: 60))
            }

            // Phase card
            SkeletonView(variant: .card(height: 100))

            // Exercise link card
            SkeletonView(variant: .card(height: 72))
        }
    }
}

struct ProgressSkeletonView: View {
    var body: some View {
        VStack(spacing: 20) {
            // Stats grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                SkeletonView(variant: .card(height: 90))
                SkeletonView(variant: .card(height: 90))
                SkeletonView(variant: .card(height: 90))
                SkeletonView(variant: .card(height: 90))
            }

            // Timeline
            SkeletonView(variant: .card(height: 140))
        }
    }
}
