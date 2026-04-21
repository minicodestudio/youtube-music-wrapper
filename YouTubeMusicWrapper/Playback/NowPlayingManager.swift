import AppKit
import MediaPlayer

@MainActor
final class NowPlayingManager {
    private let infoCenter = MPNowPlayingInfoCenter.default()
    private var lastArtworkURL: URL?
    private var cachedArtwork: MPMediaItemArtwork?
    private var artworkTask: Task<Void, Never>?

    func update(with track: TrackInfo?) {
        guard let track = track else {
            infoCenter.nowPlayingInfo = nil
            infoCenter.playbackState = .stopped
            lastArtworkURL = nil
            cachedArtwork = nil
            return
        }

        var info: [String: Any] = [:]
        info[MPMediaItemPropertyTitle] = track.title
        info[MPMediaItemPropertyArtist] = track.artist
        if let album = track.album {
            info[MPMediaItemPropertyAlbumTitle] = album
        }
        info[MPMediaItemPropertyPlaybackDuration] = track.duration
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = track.position
        info[MPNowPlayingInfoPropertyPlaybackRate] = track.isPlaying ? 1.0 : 0.0
        info[MPNowPlayingInfoPropertyMediaType] = MPNowPlayingInfoMediaType.audio.rawValue

        if let artwork = cachedArtwork, lastArtworkURL == track.artworkURL {
            info[MPMediaItemPropertyArtwork] = artwork
        }

        infoCenter.nowPlayingInfo = info
        infoCenter.playbackState = track.isPlaying ? .playing : .paused

        if track.artworkURL != lastArtworkURL {
            lastArtworkURL = track.artworkURL
            cachedArtwork = nil
            refreshArtwork(from: track.artworkURL)
        }
    }

    private func refreshArtwork(from url: URL?) {
        artworkTask?.cancel()
        guard let url = url else { return }

        artworkTask = Task { [weak self] in
            guard let (data, _) = try? await URLSession.shared.data(from: url),
                  let image = NSImage(data: data) else { return }
            if Task.isCancelled { return }
            let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
            await MainActor.run { [weak self] in
                guard let self = self, self.lastArtworkURL == url else { return }
                self.cachedArtwork = artwork
                var info = self.infoCenter.nowPlayingInfo ?? [:]
                info[MPMediaItemPropertyArtwork] = artwork
                self.infoCenter.nowPlayingInfo = info
            }
        }
    }
}
