import Foundation

struct TrackInfo: Equatable {
    var title: String
    var artist: String
    var album: String?
    var artworkURL: URL?
    var duration: TimeInterval
    var position: TimeInterval
    var isPlaying: Bool
}

struct TrackInfoPayload: Decodable {
    let title: String?
    let artist: String?
    let album: String?
    let artworkURL: String?
    let duration: Double?
    let position: Double?
    let isPlaying: Bool?

    func toTrackInfo() -> TrackInfo? {
        guard let title = title, !title.isEmpty else { return nil }
        return TrackInfo(
            title: title,
            artist: artist ?? "",
            album: (album?.isEmpty == false) ? album : nil,
            artworkURL: artworkURL.flatMap(URL.init(string:)),
            duration: duration ?? 0,
            position: position ?? 0,
            isPlaying: isPlaying ?? false
        )
    }
}
