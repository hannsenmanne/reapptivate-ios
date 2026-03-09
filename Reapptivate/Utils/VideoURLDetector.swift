import Foundation

enum VideoSource {
    case youtube(id: String)
    case vimeo(id: String)
    case directVideo(url: URL)
    case gif(url: URL)
    case unknown

    static func detect(_ urlString: String) -> VideoSource {
        guard let url = URL(string: urlString) else { return .unknown }
        let host = url.host(percentEncoded: false)?.lowercased() ?? ""
        let path = url.path.lowercased()

        // YouTube: youtube.com/watch?v=ID, youtu.be/ID, youtube.com/embed/ID
        if host.contains("youtube.com") || host.contains("youtube-nocookie.com") {
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let videoId = components.queryItems?.first(where: { $0.name == "v" })?.value {
                return .youtube(id: videoId)
            }
            if path.contains("/embed/") {
                let parts = path.components(separatedBy: "/embed/")
                if let id = parts.last, !id.isEmpty {
                    return .youtube(id: id)
                }
            }
        }
        if host.contains("youtu.be") {
            let id = url.lastPathComponent
            if !id.isEmpty {
                return .youtube(id: id)
            }
        }

        // Vimeo: vimeo.com/ID, vimeo.com/video/ID, player.vimeo.com/video/ID
        if host.contains("vimeo.com") {
            if path.contains("/video/") {
                let parts = path.components(separatedBy: "/video/")
                if let id = parts.last, !id.isEmpty {
                    return .vimeo(id: id)
                }
            }
            let id = url.lastPathComponent
            if !id.isEmpty, id.allSatisfy(\.isNumber) {
                return .vimeo(id: id)
            }
        }

        // GIF
        if path.hasSuffix(".gif") {
            return .gif(url: url)
        }

        // Direct video: .mp4, .webm, .ogg
        let videoExtensions = [".mp4", ".webm", ".ogg", ".m4v", ".mov"]
        if videoExtensions.contains(where: { path.hasSuffix($0) }) {
            return .directVideo(url: url)
        }

        return .unknown
    }

    var youtubeThumbURL: URL? {
        if case .youtube(let id) = self {
            return URL(string: "https://img.youtube.com/vi/\(id)/mqdefault.jpg")
        }
        return nil
    }
}
