import SwiftUI

@main
struct YouTubeMusicWrapperApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appDelegate.playbackState)
                .frame(
                    minWidth: 900, idealWidth: 1200, maxWidth: .infinity,
                    minHeight: 600, idealHeight: 800, maxHeight: .infinity
                )
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}
