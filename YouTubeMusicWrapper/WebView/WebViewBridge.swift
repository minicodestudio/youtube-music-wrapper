import Foundation
import WebKit

final class WebViewBridge: NSObject, WKScriptMessageHandler {
    static let messageName = "trackInfo"

    private let onUpdate: (TrackInfo?) -> Void

    init(onUpdate: @escaping (TrackInfo?) -> Void) {
        self.onUpdate = onUpdate
    }

    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        guard message.name == Self.messageName,
              let body = message.body as? [String: Any] else { return }

        guard let data = try? JSONSerialization.data(withJSONObject: body),
              let payload = try? JSONDecoder().decode(TrackInfoPayload.self, from: data) else {
            return
        }

        let track = payload.toTrackInfo()
        Task { @MainActor in
            self.onUpdate(track)
        }
    }
}
