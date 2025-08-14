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
          "Mozilla/5.0 (Macintosh; Intel Mac OS X 13_5) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"

        webView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            webView.topAnchor.constraint(equalTo: container.topAnchor),
            webView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        webView.load(URLRequest(url: URL(string: "https://teams.microsoft.com")!))
        return container
    }
    func updateUIView(_ uiView: UIView, context: Context) {}
}

final class TeamsWebView: WKWebView, WKNavigationDelegate, WKUIDelegate {
    override init(frame: CGRect, configuration: WKWebViewConfiguration) {
        super.init(frame: frame, configuration: configuration)
        navigationDelegate = self
        uiDelegate = self
        scrollView.bounces = true
        scrollView.alwaysBounceVertical = true
        allowsBackForwardNavigationGestures = true
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url, !(url.scheme?.hasPrefix("http") ?? false) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            decisionHandler(.cancel); return
        }
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
            decisionHandler(.cancel); return
        }
        decisionHandler(.allow)
    }

    // JS dialogs
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        presentAlert(title: nil, message: message,
                     actions: [UIAlertAction(title: "OK", style: .default, handler: { _ in completionHandler() })])
    }
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        presentAlert(title: nil, message: message, actions: [
            UIAlertAction(title: "Cancelar", style: .cancel, handler: { _ in completionHandler(false) }),
            UIAlertAction(title: "OK", style: .default, handler: { _ in completionHandler(true) })
        ])
    }
    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String,
                 defaultText: String?, initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (String?) -> Void) {
        let alert = UIAlertController(title: nil, message: prompt, preferredStyle: .alert)
        alert.addTextField { $0.text = defaultText }
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel, handler: { _ in completionHandler(nil) }))
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in completionHandler(alert.textFields?.first?.text) }))
        topMostController()?.present(alert, animated: true, completion: nil)
    }

    private func presentAlert(title: String?, message: String?, actions: [UIAlertAction]) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        actions.forEach { alert.addAction($0) }
        topMostController()?.present(alert, animated: true, completion: nil)
    }

    private func topMostController() -> UIViewController? {
        var keyWindow = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
        if keyWindow == nil { keyWindow = UIApplication.shared.windows.first { $0.isKeyWindow } }
        var top = keyWindow?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }
}
