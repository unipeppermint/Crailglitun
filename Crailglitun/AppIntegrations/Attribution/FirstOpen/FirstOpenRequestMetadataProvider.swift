import AppsFlyerLib
import UIKit
import WebKit

nonisolated struct FirstOpenRequestMetadata: Sendable {
    let userAgent: String
    let appsFlyerId: String
    let deviceId: String?
}

@MainActor
protocol FirstOpenRequestMetadataProviding: AnyObject {
    func makeMetadata(completion: @escaping @MainActor (FirstOpenRequestMetadata) -> Void)
}

@MainActor
final class SystemFirstOpenRequestMetadataProvider: FirstOpenRequestMetadataProviding {
    func makeMetadata(completion: @escaping @MainActor (FirstOpenRequestMetadata) -> Void) {
        let appsFlyerId = AppsFlyerLib.shared().getAppsFlyerUID()
        let deviceId = UIDevice.current.identifierForVendor?.uuidString

        DispatchQueue.main.async {
            let webView = WKWebView(frame: .zero)
            webView.evaluateJavaScript("navigator.userAgent") { [webView] result, _ in
                let userAgent = (result as? String)?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                completion(
                    FirstOpenRequestMetadata(
                        userAgent: userAgent.flatMap { $0.isEmpty ? nil : $0 }
                            ?? Self.fallbackUserAgent(),
                        appsFlyerId: appsFlyerId,
                        deviceId: deviceId
                    )
                )
                _ = webView
            }
        }
    }

    private static func fallbackUserAgent() -> String {
        let osVersion = UIDevice.current.systemVersion.replacingOccurrences(of: ".", with: "_")
        let device = UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone"
        return "Mozilla/5.0 (\(device); CPU iPhone OS \(osVersion) like Mac OS X) "
            + "AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile"
    }
}
