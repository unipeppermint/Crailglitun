import AppTrackingTransparency
import UIKit
import WebKit

final class CrailglitunExperienceViewController: UIViewController {
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

    private lazy var messageHandler = CrailglitunExperienceMessageHandler(presenting: self)

    private lazy var webView: WKWebView = {
        let contentController = WKUserContentController()
        messageHandler.install(in: contentController)

        let view = CrailglitunExperienceWebViewFactory.make(contentController: contentController)
        view.navigationDelegate = self
        view.uiDelegate = self
        messageHandler.webView = view
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
        messageHandler.uninstall()
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
              let tokenJSON = CrailglitunExperienceJavaScript.jsonString(token) else { return }

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
        progressObservation = webView.observe(
            \.estimatedProgress,
            options: [.initial, .new]
        ) { [weak self] webView, _ in
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
}

extension CrailglitunExperienceViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation?) {
        didFinishInitialNavigation = true
        lastNotifiedMessagingToken = nil
        notifyWebOfMessagingToken()
        guard !didReportInitialLoad else { return }
        didReportInitialLoad = true
    }

    func webView(
        _ webView: WKWebView,
        didFail navigation: WKNavigation?,
        withError error: Error
    ) {
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

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation?,
        withError error: Error
    ) {
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
