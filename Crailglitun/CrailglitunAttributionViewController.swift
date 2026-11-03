import AppTrackingTransparency
import UIKit

final class AttributionViewController: UIViewController {
    var onShowNativeHome: (() -> Void)?

    private let coordinator: AttributionCoordinator
    private var hasOpenedProductExperience = false
    private var isProductNavigationScheduled = false
    private var isRequestingTrackingAuthorization = false
    private var hasResolvedTrackingAuthorization = false

    init(coordinator: AttributionCoordinator) {
        self.coordinator = coordinator
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        coordinator.delegate = self
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(continueStartupIfNeeded),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )

        view.backgroundColor = UIColor(
            red: 0.9647,
            green: 0.9529,
            blue: 0.9216,
            alpha: 1
        )

        let backgroundView = UIImageView(image: UIImage(named: "CrailglitunLaunch"))
        backgroundView.contentMode = .scaleAspectFill
        backgroundView.clipsToBounds = true
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backgroundView)

        NSLayoutConstraint.activate([
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        continueStartupIfNeeded()
    }

    @objc
    private func continueStartupIfNeeded() {
        guard viewIfLoaded?.window != nil,
              navigationController?.topViewController === self,
              UIApplication.shared.applicationState == .active,
              !isRequestingTrackingAuthorization else { return }

        if !hasResolvedTrackingAuthorization {
            if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
                isRequestingTrackingAuthorization = true
                ATTrackingManager.requestTrackingAuthorization { [weak self] status in
                    DispatchQueue.main.async {
                        guard let self else { return }
                        self.isRequestingTrackingAuthorization = false
                        // If iOS could not present the prompt, retry on the next activation.
                        guard status != .notDetermined else { return }
                        self.continueStartupIfNeeded()
                    }
                }
                return
            }

            hasResolvedTrackingAuthorization = true
            coordinator.resumeAfterTrackingAuthorization()
        }

        openProductURLIfNeeded()
        openNativeHomeIfNeeded()
    }

    private func openProductURLIfNeeded() {
        guard
            let productURL = coordinator.productURL,
            let scheme = productURL.scheme?.lowercased(),
            ["http", "https"].contains(scheme),
            !hasOpenedProductExperience,
            !isProductNavigationScheduled,
            let navigationController,
            navigationController.topViewController === self,
            viewIfLoaded?.window != nil
        else {
            return
        }

        isProductNavigationScheduled = true
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.isProductNavigationScheduled = false

            guard
                !self.hasOpenedProductExperience,
                let navigationController = self.navigationController,
                navigationController.topViewController === self,
                self.viewIfLoaded?.window != nil,
                !navigationController.viewControllers.contains(where: {
                    $0 is WebExperienceViewController
                })
            else {
                return
            }

            let webViewController = WebExperienceViewController(productURL: productURL)
            navigationController.pushViewController(webViewController, animated: true)
            self.hasOpenedProductExperience = navigationController.viewControllers.contains {
                $0 === webViewController
            }
        }
    }

    private func openNativeHomeIfNeeded() {
        guard
            !hasOpenedProductExperience,
            !isProductNavigationScheduled,
            navigationController?.topViewController === self,
            viewIfLoaded?.window != nil
        else {
            return
        }

        // Keep this app's original home when first-open resolves without a web destination.
        let didResolve = coordinator.firstOpenError != nil
            || coordinator.firstOpenAttribution != nil
            || AttributionStateStore().didReportFirstOpen
            || AttributionConfiguration.appsFlyerAppID.isEmpty
        guard didResolve else { return }

        onShowNativeHome?()
    }
}

extension AttributionViewController: AttributionCoordinatorDelegate {
    func attributionCoordinatorDidUpdate(_ coordinator: AttributionCoordinator) {
        continueStartupIfNeeded()
    }
}
