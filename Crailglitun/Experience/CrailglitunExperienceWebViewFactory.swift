import UIKit
import WebKit

@MainActor
enum CrailglitunExperienceWebViewFactory {
    static func make(contentController: WKUserContentController) -> WKWebView {
        let pagePreferences = WKWebpagePreferences()
        pagePreferences.allowsContentJavaScript = true

        let preferences = WKPreferences()
        preferences.javaScriptCanOpenWindowsAutomatically = true

        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences = pagePreferences
        configuration.preferences = preferences
        configuration.userContentController = contentController
        if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
           !version.isEmpty {
            configuration.applicationNameForUserAgent = "AppVer/\(version)"
        }
        configuration.allowsInlineMediaPlayback = true
        configuration.allowsPictureInPictureMediaPlayback = false
        configuration.allowsAirPlayForMediaPlayback = false

        let view = WKWebView(frame: .zero, configuration: configuration)
        view.backgroundColor = .black
        view.isOpaque = false
        view.scrollView.backgroundColor = .black
        view.scrollView.contentInsetAdjustmentBehavior = .never
        view.scrollView.showsVerticalScrollIndicator = false
        view.scrollView.showsHorizontalScrollIndicator = false
        view.allowsLinkPreview = false
        view.allowsBackForwardNavigationGestures = true
        return view
    }
}
