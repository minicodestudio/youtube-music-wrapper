import Foundation
import MediaPlayer

@MainActor
final class RemoteCommandManager {
    private weak var playbackState: PlaybackState?
    private let center = MPRemoteCommandCenter.shared()

    init(playbackState: PlaybackState) {
        self.playbackState = playbackState
        configure()
    }

    private func configure() {
        center.playCommand.isEnabled = true
        center.pauseCommand.isEnabled = true
        center.togglePlayPauseCommand.isEnabled = true
        center.nextTrackCommand.isEnabled = true
        center.previousTrackCommand.isEnabled = true
        center.changePlaybackPositionCommand.isEnabled = true

        center.playCommand.addTarget { [weak self] _ in
            self?.webViewController?.play()
            return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            self?.webViewController?.pause()
            return .success
        }
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.webViewController?.togglePlayPause()
            return .success
        }
        center.nextTrackCommand.addTarget { [weak self] _ in
            self?.webViewController?.next()
            return .success
        }
        center.previousTrackCommand.addTarget { [weak self] _ in
            self?.webViewController?.previous()
            return .success
        }
        center.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let seekEvent = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            self?.webViewController?.seek(to: seekEvent.positionTime)
            return .success
        }
    }

    private var webViewController: WebViewController? {
        playbackState?.webViewController
    }
}
