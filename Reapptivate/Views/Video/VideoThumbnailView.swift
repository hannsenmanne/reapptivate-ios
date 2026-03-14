import SwiftUI

struct VideoThumbnailView: View {
    let urlString: String
    @State private var isExpanded = false
    @AppStorage("appLanguage") private var appLanguage = "de"

    private var isEn: Bool { appLanguage == "en" }

    private var source: VideoSource {
        VideoSource.detect(urlString)
    }

    var body: some View {
        Button {
            isExpanded = true
        } label: {
            ZStack {
                thumbnailContent
                    .frame(maxWidth: .infinity)
                    .frame(height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.smallRadius, style: .continuous))

                // Play overlay
                playOverlay
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isEn ? "Play video" : "Video abspielen")
        .sheet(isPresented: $isExpanded) {
            ExerciseVideoPlayer(urlString: urlString, title: nil)
                .glassSheet()
        }
    }

    // MARK: - Thumbnail Content

    @ViewBuilder
    private var thumbnailContent: some View {
        switch source {
        case .youtube:
            if let thumbURL = source.youtubeThumbURL {
                AsyncImage(url: thumbURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        placeholderView
                    case .empty:
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.textSecondary.opacity(0.1))
                    @unknown default:
                        placeholderView
                    }
                }
            } else {
                placeholderView
            }

        case .gif(let url):
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    placeholderView
                case .empty:
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.textSecondary.opacity(0.1))
                @unknown default:
                    placeholderView
                }
            }

        default:
            placeholderView
        }
    }

    private var placeholderView: some View {
        Rectangle()
            .fill(Color.textSecondary.opacity(0.1))
            .overlay {
                VStack(spacing: 8) {
                    Image(systemName: "play.rectangle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.textSecondary)
                    Text("Video")
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                }
            }
    }

    private var playOverlay: some View {
        Circle()
            .fill(.ultraThinMaterial)
            .frame(width: 48, height: 48)
            .overlay {
                Image(systemName: "play.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.textPrimary)
                    .offset(x: 2)
            }
    }
}
