import UIKit
import WebKit

/// Owns the web/native message contract without retaining the page or its presenter.
final class CrailglitunExperienceMessageHandler: NSObject {
    private enum JavaScriptChannel: String, CaseIterable {
        case openSafari
        case open
        case openWebview
        case openWindow
        case storageGetItem
        case firebaseLogin
        case getFcmToken
    }

    private weak var presentingViewController: UIViewController?
    private weak var contentController: WKUserContentController?
    weak var webView: WKWebView?

    private let nativeBridge = WebNativeBridge()

    init(presenting viewController: UIViewController) {
        presentingViewController = viewController
        super.init()
        nativeBridge.delegate = self
    }

    func install(in controller: WKUserContentController) {
        uninstall()
        contentController = controller
        // WebKit retains this handler. All references back to its owners are weak.
        JavaScriptChannel.allCases.forEach { controller.add(self, name: $0.rawValue) }
        nativeBridge.install(in: controller)
    }

    func uninstall() {
        nativeBridge.uninstall()
        JavaScriptChannel.allCases.forEach {
            contentController?.removeScriptMessageHandler(forName: $0.rawValue)
        }
        contentController = nil
    }

    private func openExternalBrowser(with body: Any) {
        guard let url = CrailglitunExperienceURLResolver.externalURL(from: body) else {
            #if DEBUG
            print("[WebExperience] Ignored an invalid external URL payload.")
            #endif
            return
        }
        UIApplication.shared.open(url)
    }

    private func handleFirebaseLogin(with body: Any) {
        guard let payload = body as? [String: Any],
              let channel = payload["channel"] as? String,
              let callback = payload["callback"] as? String,
              CrailglitunExperienceJavaScript.isValidCallbackName(callback) else {
            return
        }

        guard channel.lowercased() == "google" else {
            evaluateCallback(named: callback, value: "failure: unsupported channel")
            return
        }

        guard let presentingViewController else { return }
        AppIntegrationService.shared.signInWithFirebaseGoogle(
            presenting: presentingViewController
        ) { [weak self] result in
            self?.evaluateCallback(named: callback, result: result)
        }
    }

    private func handleFCMTokenRequest(with body: Any) {
        guard let callback = CrailglitunExperienceJavaScript.callbackName(from: body) else { return }

        AppIntegrationService.shared.fetchMessagingToken { [weak self] result in
            self?.evaluateCallback(named: callback, result: result)
        }
    }

    private func evaluateCallback(named callback: String, result: Result<String, Error>) {
        switch result {
        case let .success(value):
            evaluateCallback(named: callback, value: value)
        case let .failure(error):
            evaluateCallback(named: callback, value: "failure: \(error.localizedDescription)")
        }
    }

    private func evaluateCallback(named callback: String, value: String) {
        guard let script = CrailglitunExperienceJavaScript.callbackScript(
            named: callback,
            value: value
        ) else {
            return
        }

        webView?.evaluateJavaScript(script) { result, error in
            #if DEBUG
            if let error {
                print("[WebExperience] JavaScript callback failed: \(error.localizedDescription)")
            } else if (result as? Bool) != true {
                print("[WebExperience] JavaScript callback was not found: \(callback)")
            } else {
                print("[WebExperience] JavaScript callback invoked: \(callback)")
            }
            #endif
        }
    }
}

extension CrailglitunExperienceMessageHandler: WebNativeBridgeDelegate {
    func webNativeBridge(
        _ bridge: WebNativeBridge,
        openIntent urlString: String
    ) {
        guard let url = CrailglitunExperienceURLResolver.nativeIntentURL(from: urlString) else {
#if DEBUG
            print("[WebExperience] Ignored an invalid native intent URL.")
#endif
            return
        }
        UIApplication.shared.open(url)
    }

    func webNativeBridge(
        _ bridge: WebNativeBridge,
        deleteCookieNamed name: String
    ) {
        let cookieName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cookieName.isEmpty else { return }

        guard let cookieStore = webView?.configuration.websiteDataStore.httpCookieStore else {
            return
        }
        cookieStore.getAllCookies { cookies in
            let matchingCookies = cookies.filter { $0.name == cookieName }
            matchingCookies.forEach { cookieStore.delete($0) }
#if DEBUG
            print(
                "[WebExperience] Deleted \(matchingCookies.count) cookie(s) named \(cookieName)."
            )
#endif
        }
    }

    func webNativeBridgeDidRequestGoogleLogin(_ bridge: WebNativeBridge) {
        guard let presentingViewController else { return }
        AppIntegrationService.shared.signInWithGoogleAccessToken(
            presenting: presentingViewController
        ) { [weak self] result in
            switch result {
            case let .success(accessToken):
                self?.evaluateCallback(named: "googleLogin", value: accessToken)

            case let .failure(error):
#if DEBUG
                print(
                    "[WebExperience] Native Google sign-in failed: \(error.localizedDescription)"
                )
#endif
            }
        }
    }
}

extension CrailglitunExperienceMessageHandler: WKScriptMessageHandler {
    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard let channel = JavaScriptChannel(rawValue: message.name) else { return }

        switch channel {
        case .openSafari, .open, .openWebview, .openWindow:
            openExternalBrowser(with: message.body)
        case .firebaseLogin:
            handleFirebaseLogin(with: message.body)
        case .getFcmToken:
            handleFCMTokenRequest(with: message.body)
        case .storageGetItem:
            break
        }
    }
}

