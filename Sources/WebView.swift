import UIKit
import WebKit
import SwiftUI

struct WebContainer: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let container = UIView(frame: .zero)

        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        config.allowsInlineMediaPlayback = true
        if #available(iOS 14.0, *) {
            // 🔸 Fuerza "sitio de escritorio"
            config.defaultWebpagePreferences.preferredContentMode = .desktop
        } else if #available(iOS 13.0, *) {
            config.defaultWebpagePreferences.preferredContentMode = .desktop
        }
        config.websiteDataStore = .default()

        let webView = TeamsWebView(frame: .zero, configuration: config)

        // 🔸 User-Agent de Safari en macOS (evita el bloqueo móvil de Teams)
        webView.customUserAgent =
          "Mozilla/5.0 (Macintosh; Intel Mac OS X 13_5) AppleWebKit/605.1_
