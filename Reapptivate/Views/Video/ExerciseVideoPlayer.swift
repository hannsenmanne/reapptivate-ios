import SwiftUI
import AVKit
import WebKit

struct ExerciseVideoPlayer: View {
    let urlString: String
    let title: String?
    @Environment(\.dismiss) private var dismiss

    private var source: VideoSource {
        VideoSource.detect(urlString)
    }

    var body: some View {
        NavigationStack {
            Group {
                switch source {
                case .youtube(let id):
                    if let embedURL = URL(string: "https://www.youtube-nocookie.com/embed/\(id)?autoplay=1&rel=0&playsinline=1") {
                        WebVideoPlayer(url: embedURL)
                    }

                case .vimeo(let id):
                    if let embedURL = URL(string: "https://player.vimeo.com/video/\(id)?autoplay=1") {
                        WebVideoPlayer(url: embedURL)
                    }

                case .directVideo(let url):
                    NativeVideoPlayer(url: url)

                case .gif(let url):
                    ScrollView {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                            case .failure:
                                ContentUnavailableView(
                                    "GIF konnte nicht geladen werden",
                                    systemImage: "photo.badge.exclamationmark"
                                )
                            case .empty:
                                ProgressView("Lade GIF...")
                                    .frame(maxWidth: .infinity, minHeight: 300)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }

                case .unknown:
                    ContentUnavailableView {
                        Label("Nicht unterstützt", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text("Dieses Videoformat wird nicht unterstützt.")
                    } actions: {
                        if let url = URL(string: urlString) {
                            Link("In Safari öffnen", destination: url)
                        }
                    }
                }
            }
            .background(Color.black)
            .navigationTitle(title ?? "Video")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.appTitle3)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
}

// MARK: - Native Video Player (AVKit)

private struct NativeVideoPlayer: View {
    let url: URL
    @State private var player: AVPlayer?

    var body: some View {
        VideoPlayer(player: player)
            .ignoresSafeArea()
            .onAppear {
                player = AVPlayer(url: url)
                player?.play()
            }
            .onDisappear {
                player?.pause()
                player = nil
            }
    }
}

// MARK: - Web Video Player (YouTube / Vimeo via WKWebView)

private struct WebVideoPlayer: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.isScrollEnabled = false
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}
}
