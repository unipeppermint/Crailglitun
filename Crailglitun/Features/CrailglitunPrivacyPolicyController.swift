import UIKit
import WebKit

final class CrailglitunPrivacyPolicyController: UIViewController, WKNavigationDelegate {
    private let policyURL: URL
    private let webView = WKWebView()
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let errorView = UIStackView()

    init(url: URL) {
        policyURL = url
        super.init(nibName: nil, bundle: nil)
        title = "Privacy Policy"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.largeTitleDisplayMode = .never

        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)

        activityIndicator.hidesWhenStopped = true
        activityIndicator.accessibilityLabel = "Loading privacy policy"
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)

        let message = UILabel()
        message.text = "Unable to load the privacy policy. Check your connection and try again."
        message.font = .preferredFont(forTextStyle: .body)
        message.adjustsFontForContentSizeCategory = true
        message.textColor = .label
        message.numberOfLines = 0
        message.textAlignment = .center

        let retryButton = button("Try Again", icon: "arrow.clockwise") { [weak self] in
            self?.loadPolicy()
        }
        errorView.axis = .vertical
        errorView.spacing = 20
        errorView.addArrangedSubview(message)
        errorView.addArrangedSubview(retryButton)
        errorView.translatesAutoresizingMaskIntoConstraints = false
        errorView.isHidden = true
        view.addSubview(errorView)

        let safeArea = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            webView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            activityIndicator.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: safeArea.centerYAnchor),
            errorView.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
            errorView.centerYAnchor.constraint(equalTo: safeArea.centerYAnchor),
            errorView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 24),
            errorView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -24)
        ])

        loadPolicy()
    }

    private func loadPolicy() {
        errorView.isHidden = true
        webView.isHidden = false
        activityIndicator.startAnimating()
        webView.load(URLRequest(url: policyURL, timeoutInterval: 30))
    }

    private func showLoadError() {
        activityIndicator.stopAnimating()
        webView.isHidden = true
        errorView.isHidden = false
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        errorView.isHidden = true
        activityIndicator.startAnimating()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicator.stopAnimating()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handleNavigationError(error)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        handleNavigationError(error)
    }

    private func handleNavigationError(_ error: Error) {
        let error = error as NSError
        guard error.domain != NSURLErrorDomain || error.code != NSURLErrorCancelled else {
            return
        }
        showLoadError()
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        showLoadError()
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse,
        decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void
    ) {
        if navigationResponse.isForMainFrame,
           let response = navigationResponse.response as? HTTPURLResponse,
           response.statusCode >= 400 {
            decisionHandler(.cancel)
            showLoadError()
            return
        }
        decisionHandler(.allow)
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }

        if url.scheme?.lowercased() == "mailto" {
            decisionHandler(.cancel)
            UIApplication.shared.open(url, options: [:]) { [weak self] opened in
                if !opened {
                    self?.notify("Email unavailable", "Please email cressidal@trademarkroofing.homes using your preferred mail app.")
                }
            }
            return
        }

        guard let scheme = url.scheme?.lowercased(), ["https", "http"].contains(scheme) else {
            decisionHandler(.cancel)
            return
        }

        if navigationAction.targetFrame == nil {
            decisionHandler(.cancel)
            webView.load(navigationAction.request)
            return
        }
        decisionHandler(.allow)
    }
}
