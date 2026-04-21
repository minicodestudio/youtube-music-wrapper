import AppKit
import Combine

@MainActor
final class StatusItemController: NSObject {
    private let playbackState: PlaybackState
    private let statusItem: NSStatusItem
    private let menu = NSMenu()
    private var cancellables = Set<AnyCancellable>()

    private let currentTrackItem = NSMenuItem(title: "Not playing", action: nil, keyEquivalent: "")
    private let playPauseItem = NSMenuItem(title: "Play / Pause", action: #selector(togglePlayPause), keyEquivalent: "")
    private let nextItem = NSMenuItem(title: "Next", action: #selector(nextTrack), keyEquivalent: "")
    private let previousItem = NSMenuItem(title: "Previous", action: #selector(previousTrack), keyEquivalent: "")
    private let showWindowItem = NSMenuItem(title: "Show Window", action: #selector(showWindow), keyEquivalent: "")
    private let quitItem = NSMenuItem(title: "Quit YouTube Music", action: #selector(quit), keyEquivalent: "q")

    init(playbackState: PlaybackState) {
        self.playbackState = playbackState
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        configureButton()
        configureMenu()
        bindState()
    }

    private func configureButton() {
        if let button = statusItem.button {
            let image = NSImage(systemSymbolName: "music.note", accessibilityDescription: "YouTube Music")
            image?.isTemplate = true
            button.image = image
        }
    }

    private func configureMenu() {
        currentTrackItem.isEnabled = false

        [playPauseItem, nextItem, previousItem, showWindowItem, quitItem].forEach { $0.target = self }

        menu.addItem(currentTrackItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(playPauseItem)
        menu.addItem(nextItem)
        menu.addItem(previousItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(showWindowItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    private func bindState() {
        playbackState.$currentTrack
            .receive(on: DispatchQueue.main)
            .sink { [weak self] track in
                self?.renderTrack(track)
            }
            .store(in: &cancellables)
    }

    private func renderTrack(_ track: TrackInfo?) {
        if let track = track {
            let artistSuffix = track.artist.isEmpty ? "" : " — \(track.artist)"
            currentTrackItem.title = "\(track.title)\(artistSuffix)"
        } else {
            currentTrackItem.title = "Not playing"
        }
    }

    @objc private func togglePlayPause() {
        playbackState.webViewController?.togglePlayPause()
    }

    @objc private func nextTrack() {
        playbackState.webViewController?.next()
    }

    @objc private func previousTrack() {
        playbackState.webViewController?.previous()
    }

    @objc private func showWindow() {
        NSApp.activate(ignoringOtherApps: true)
        for window in NSApp.windows {
            window.makeKeyAndOrderFront(nil)
        }
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
