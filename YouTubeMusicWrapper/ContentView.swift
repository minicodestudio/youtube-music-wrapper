import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var playbackState: PlaybackState

    var body: some View {
        YouTubeMusicWebView(playbackState: playbackState)
    }
}
