import AppTrackingTransparency
import UIKit
import WebKit

final class CrailglitunExperienceViewController: UIViewController {
    private enum JavaScriptChannel {
        static let openSafari = "openSafari"
        static let open = "open"
        static let openWebview = "openWebview"
        static let openWindow = "openWindow"
        static let storageGetItem = "storageGetItem"
        static let firebaseLogin = "firebaseLogin"
        static let getFcmToken = "getFcmToken"
        static let all = [
            openSafari,
            open,
            openWebview,
            openWindow,
            storageGetItem,
            firebaseLogin,
            getFcmToken
        ]
    }

    private let productURL: URL
    private let locationPermissionRequester = LocationPermissionRequester()

    private var didRequestFallback = false
    private var didReportInitialLoad = false
    private var didFinishInitialNavigation = false
    private var didStartLoadingProductPage = false
    private var isRequestingNotificationAuthorization = false
    private var didCompleteNotificationAuthorization = false
    private var lastNotifiedMessagingToken: String?
    private var progressObservation: NSKeyValueObservation?

    private lazy var nativeBridge: WebNativeBridge = {
        let bridge = WebNativeBridge()
        bridge.delegate = self
        return bridge
    }()

    private lazy var contentController: WKUserContentController = {
        let controller = WKUserContentController()
        let proxy = WeakWebMessageProxy(target: self)
        JavaScriptChannel.all.forEach { controller.add(proxy, name: $0) }
        nativeBridge.install(in: controller)
        return controller
    }()

    private lazy var webView: WKWebView = {
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
        view.navigationDelegate = self
        view.uiDelegate = self
        view.backgroundColor = .black
        view.isOpaque = false
        view.scrollView.backgroundColor = .black
        view.scrollView.contentInsetAdjustmentBehavior = .never
        view.scrollView.showsVerticalScrollIndicator = false
        view.scrollView.showsHorizontalScrollIndicator = false
        view.allowsLinkPreview = false
        view.allowsBackForwardNavigationGestures = true
        return view
    }()

    private let progressView: UIProgressView = {
        let view = UIProgressView(progressViewStyle: .bar)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.trackTintColor = UIColor.white.withAlphaComponent(0.08)
        view.progressTintColor = UIColor(red: 0.25, green: 1, blue: 0.75, alpha: 1)
        return view
    }()

    init(productURL: URL) {

        self.productURL = productURL
        super.init(nibName: nil, bundle: nil)

    }
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        progressObservation?.invalidate()
        nativeBridge.uninstall()
        JavaScriptChannel.all.forEach {
            contentController.removeScriptMessageHandler(forName: $0)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        buildInterface()
        observeLoadingProgress()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(prepareWebExperienceIfNeeded),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(notifyWebOfMessagingToken),
            name: CrailglitunPushService.tokenDidChange,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(prepareWebExperienceIfNeeded),
            name: CrailglitunStartupRouter.trackingAuthorizationDidResolve,
            object: nil
        )
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        CrailglitunPushService.shared.openPendingNotificationIfPossible()
        prepareWebExperienceIfNeeded()
    }

    @objc
    private func prepareWebExperienceIfNeeded() {
        guard viewIfLoaded?.window != nil,
              UIApplication.shared.applicationState != .background else { return }

        if !didStartLoadingProductPage {
            loadProductPage()
        }

        // Load the page while ATT is pending, but serialize system permission prompts.
        guard !isRequestingNotificationAuthorization,
              UIApplication.shared.applicationState == .active,
              ATTrackingManager.trackingAuthorizationStatus != .notDetermined else { return }

        if !didCompleteNotificationAuthorization {
            isRequestingNotificationAuthorization = true
            Task { @MainActor [weak self] in
                let didComplete = await CrailglitunPushService.shared
                    .requestNotificationAuthorizationIfNeeded()
                guard let self else { return }
                self.isRequestingNotificationAuthorization = false
                self.didCompleteNotificationAuthorization = didComplete
                self.prepareWebExperienceIfNeeded()
            }
            return
        }

        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        NotificationCenter.default.removeObserver(
            self,
            name: CrailglitunStartupRouter.trackingAuthorizationDidResolve,
            object: nil
        )
        locationPermissionRequester.requestWhenInUseAuthorizationIfNeeded()
    }

    private func loadProductPage() {
        didStartLoadingProductPage = true
        webView.load(URLRequest(url: productURL))
    }

    func openHomeFromNotification() {
        // Cold launches already load productURL once through the normal flow.
        guard didFinishInitialNavigation || didRequestFallback else { return }
        webView.load(URLRequest(url: productURL))
    }

    @objc
    private func notifyWebOfMessagingToken() {
        guard didFinishInitialNavigation,
              !webView.isLoading,
              let token = CrailglitunPushService.shared.currentToken,
              token != lastNotifiedMessagingToken,
              let tokenJSON = jsonString(token) else { return }

        lastNotifiedMessagingToken = token
        webView.evaluateJavaScript("""
        window.dispatchEvent(new CustomEvent('fcmTokenUpdated', {
            detail: { token: \(tokenJSON) }
        }));
        """, completionHandler: nil)
    }

    private func buildInterface() {
        view.backgroundColor = .black
        view.addSubview(webView)
        view.addSubview(progressView)
        webView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            progressView.topAnchor.constraint(equalTo: webView.topAnchor),
            progressView.leadingAnchor.constraint(equalTo: webView.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: webView.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 2)
        ])
    }

    private func observeLoadingProgress() {
        progressObservation = webView.observe(\.estimatedProgress, options: [.initial, .new]) { [weak self] webView, _ in
            DispatchQueue.main.async {
                self?.updateProgress(Float(webView.estimatedProgress))
            }
        }
    }

    private func updateProgress(_ progress: Float) {
        progressView.isHidden = false
        progressView.setProgress(progress, animated: true)
        guard progress >= 1 else { return }

        UIView.animate(withDuration: 0.22, delay: 0.12, options: .curveEaseOut) {
            self.progressView.alpha = 0
        } completion: { _ in
            self.progressView.isHidden = true
            self.progressView.alpha = 1
            self.progressView.progress = 0
        }
    }

    private func requestNativeFallback(for error: Error) {
        guard !didRequestFallback else { return }
        didRequestFallback = true
        #if DEBUG
        print("[WebExperience] Navigation failed: \(error.localizedDescription)")
        #endif
    }

    private func shouldFallback(for error: Error) -> Bool {
        let nsError = error as NSError

        // WebKit reports cancelled navigations during redirects, link changes,
        // authentication callbacks, and back/forward gestures. These are not
        // launch failures and must not replace the app's root controller.
        if nsError.domain == NSURLErrorDomain, nsError.code == NSURLErrorCancelled {
            return false
        }

        return !didFinishInitialNavigation && !didReportInitialLoad
    }

    private func openExternalBrowser(with body: Any) {
        guard let url = externalURL(from: body) else {
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
              isValidCallbackName(callback) else {
            return
        }

        guard channel.lowercased() == "google" else {
            evaluateCallback(named: callback, value: "failure: unsupported channel")
            return
        }

        AppIntegrationService.shared.signInWithFirebaseGoogle(presenting: self) { [weak self] result in
            switch result {
            case let .success(idToken):
                self?.evaluateCallback(named: callback, value: idToken)
            case let .failure(error):
                self?.evaluateCallback(
                    named: callback,
                    value: "failure: \(error.localizedDescription)"
                )
            }
        }
    }

    private func handleFCMTokenRequest(with body: Any) {
        guard let callback = callbackName(from: body) else { return }

        AppIntegrationService.shared.fetchMessagingToken { [weak self] result in
            switch result {
            case let .success(token):
                self?.evaluateCallback(named: callback, value: token)
            case let .failure(error):
                self?.evaluateCallback(
                    named: callback,
                    value: "failure: \(error.localizedDescription)"
                )
            }
        }
    }

    private func callbackName(from body: Any) -> String? {
        let callback: String?
        if let payload = body as? [String: Any] {
            callback = payload["callback"] as? String
        } else {
            callback = body as? String
        }
        guard let callback, isValidCallbackName(callback) else { return nil }
        return callback
    }

    private func evaluateCallback(named callback: String, value: String) {
        guard isValidCallbackName(callback),
              let callbackJSON = jsonString(callback),
              let valueJSON = jsonString(value) else {
            return
        }

        let script = """
        (function () {
            var callback = window[\(callbackJSON)];
            if (typeof callback !== "function") {
                return false;
            }
            callback(\(valueJSON));
            return true;
        })();
        """

        webView.evaluateJavaScript(script) { result, error in
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

    private func isValidCallbackName(_ callback: String) -> Bool {
        guard !callback.isEmpty else { return false }
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_$"))
        return callback.unicodeScalars.allSatisfy(allowedCharacters.contains)
    }

    private func jsonString(_ value: String) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: value, options: [.fragmentsAllowed]) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    private func externalURL(from body: Any) -> URL? {
        if let value = body as? String {
            return normalizedExternalURL(from: value)
        }
        if let payload = body as? [String: Any] {
            return ["url", "href", "link", "target"]
                .compactMap { payload[$0] as? String }
                .compactMap(normalizedExternalURL)
                .first
        }
        return nil
    }

    private func normalizedExternalURL(from rawValue: String) -> URL? {
        let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return nil }

        if let url = URL(string: value), isWebURL(url) {
            return url
        }
        if value.hasPrefix("//") {
            return URL(string: "https:\(value)").flatMap { isWebURL($0) ? $0 : nil }
        }
        if value.contains(".") {
            return URL(string: "https://\(value)").flatMap { isWebURL($0) ? $0 : nil }
        }
        return nil
    }

    private func isWebURL(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased(), url.host?.isEmpty == false else {
            return false
        }
        return scheme == "http" || scheme == "https"
    }

    private func nativeIntentURL(from rawValue: String) -> URL? {
        let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty,
              let url = URL(string: value),
              let scheme = url.scheme?.lowercased(),
              !["about", "blob", "data", "file", "javascript"].contains(scheme)
        else {
            return nil
        }

        if scheme == "http" || scheme == "https" {
            guard url.host?.isEmpty == false else { return nil }
        }
        return url
    }
}

extension CrailglitunExperienceViewController: WebNativeBridgeDelegate {
    func webNativeBridge(
        _ bridge: WebNativeBridge,
        openIntent urlString: String
    ) {
        guard let url = nativeIntentURL(from: urlString) else {
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

        let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
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
        AppIntegrationService.shared.signInWithGoogleAccessToken(
            presenting: self
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

extension CrailglitunExperienceViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation?) {
        didFinishInitialNavigation = true
        lastNotifiedMessagingToken = nil
        notifyWebOfMessagingToken()
        guard !didReportInitialLoad else { return }
        didReportInitialLoad = true
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation?, withError error: Error) {
        // A committed page can still report failures for subsequent
        // navigations. Keep the existing H5 session alive in that case.
        guard shouldFallback(for: error) else {
            #if DEBUG
            print("[WebExperience] Ignored post-launch navigation failure: \(error.localizedDescription)")
            #endif
            return
        }

        requestNativeFallback(for: error)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation?, withError error: Error) {
        guard shouldFallback(for: error) else { return }
        requestNativeFallback(for: error)
    }
}

extension CrailglitunExperienceViewController: WKUIDelegate {
    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        if navigationAction.targetFrame == nil, let url = navigationAction.request.url {
            webView.load(URLRequest(url: url))
        }
        return nil
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping () -> Void
    ) {
        let alert = UIAlertController(
            title: webView.url?.host ?? "Message",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completionHandler()
        })
        present(alert, animated: true)
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptConfirmPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (Bool) -> Void
    ) {
        let alert = UIAlertController(
            title: webView.url?.host ?? "Confirm",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completionHandler(false)
        })
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completionHandler(true)
        })
        present(alert, animated: true)
    }
}

extension CrailglitunExperienceViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case JavaScriptChannel.openSafari,
             JavaScriptChannel.open,
             JavaScriptChannel.openWebview,
             JavaScriptChannel.openWindow:
            openExternalBrowser(with: message.body)
        case JavaScriptChannel.firebaseLogin:
            handleFirebaseLogin(with: message.body)
        case JavaScriptChannel.getFcmToken:
            handleFCMTokenRequest(with: message.body)
        case JavaScriptChannel.storageGetItem:
            break
        default:
            break
        }
    }
}

private final class WeakWebMessageProxy: NSObject, WKScriptMessageHandler {
    weak var target: WKScriptMessageHandler?

    init(target: WKScriptMessageHandler) {
        self.target = target
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        target?.userContentController(userContentController, didReceive: message)
    }
}
