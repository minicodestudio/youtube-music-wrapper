import SwiftUI
import WebKit

struct YouTubeMusicWebView: NSViewRepresentable {
    let playbackState: PlaybackState

    func makeCoordinator() -> WebViewController {
        WebViewController(playbackState: playbackState)
    }

    func makeNSView(context: Context) -> WKWebView {
        let controller = context.coordinator
        let webView = controller.makeWebView()
        playbackState.webViewController = controller
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) { }
}

@MainActor
final class WebViewController: NSObject {
    private weak var playbackState: PlaybackState?
    private(set) weak var webView: WKWebView?

    init(playbackState: PlaybackState) {
        self.playbackState = playbackState
    }

    func makeWebView() -> WKWebView {
        let config = WKWebViewConfiguration()

        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = prefs

        config.mediaTypesRequiringUserActionForPlayback = []
        config.websiteDataStore = .default()

        let userContentController = WKUserContentController()
        config.userContentController = userContentController

        if let script = Self.loadInjectedScript() {
            let userScript = WKUserScript(
                source: script,
                injectionTime: .atDocumentEnd,
                forMainFrameOnly: false
            )
            userContentController.addUserScript(userScript)
        }

        let bridge = WebViewBridge { [weak self] track in
            self?.playbackState?.currentTrack = track
        }
        userContentController.add(bridge, name: WebViewBridge.messageName)

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.allowsBackForwardNavigationGestures = true
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
        webView.navigationDelegate = self
        webView.load(URLRequest(url: Self.homeURL))

        self.webView = webView
        return webView
    }

    static let homeURL = URL(string: "https://music.youtube.com")!

    private static let mainYouTubeHosts: Set<String> = [
        "www.youtube.com",
        "youtube.com",
        "m.youtube.com",
    ]

    fileprivate func shouldBounceToMusic(_ url: URL?) -> Bool {
        guard let host = url?.host?.lowercased() else { return false }
        return Self.mainYouTubeHosts.contains(host)
    }

    func play() { evaluate("window.__ymw && window.__ymw.play();") }
    func pause() { evaluate("window.__ymw && window.__ymw.pause();") }
    func togglePlayPause() { evaluate("window.__ymw && window.__ymw.toggle();") }
    func next() { evaluate("window.__ymw && window.__ymw.next();") }
    func previous() { evaluate("window.__ymw && window.__ymw.previous();") }
    func seek(to seconds: TimeInterval) {
        evaluate("window.__ymw && window.__ymw.seekTo(\(seconds));")
    }

    private func evaluate(_ js: String) {
        webView?.evaluateJavaScript(js, completionHandler: nil)
    }

    private static func loadInjectedScript() -> String? {
        guard let url = Bundle.main.url(forResource: "injected", withExtension: "js") else {
            return nil
        }
        return try? String(contentsOf: url, encoding: .utf8)
    }
}

extension WebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let type = navigationAction.navigationType
        if (type == .linkActivated || type == .other) && shouldBounceToMusic(navigationAction.request.url) {
            decisionHandler(.cancel)
            webView.load(URLRequest(url: Self.homeURL))
            return
        }
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Safety net: post-login redirects can land on youtube.com — bounce to Music.
        if shouldBounceToMusic(webView.url) {
            webView.load(URLRequest(url: Self.homeURL))
        }
    }
}
