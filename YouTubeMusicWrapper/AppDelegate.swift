import AppKit
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {
    let playbackState = PlaybackState()

    private var statusItemController: StatusItemController?
    private var nowPlayingManager: NowPlayingManager?
    private var remoteCommandManager: RemoteCommandManager?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        nowPlayingManager = NowPlayingManager()
        remoteCommandManager = RemoteCommandManager(playbackState: playbackState)

        statusItemController = StatusItemController(playbackState: playbackState)

        playbackState.$currentTrack
            .sink { [weak self] track in
                self?.nowPlayingManager?.update(with: track)
            }
            .store(in: &cancellables)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            for window in sender.windows {
                window.makeKeyAndOrderFront(nil)
            }
        }
        return true
    }
}

final class PlaybackState: ObservableObject {
    @Published var currentTrack: TrackInfo?
    weak var webViewController: WebViewController?
}
