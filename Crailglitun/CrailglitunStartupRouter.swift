import AppTrackingTransparency
import UIKit

@MainActor
final class CrailglitunStartupRouter: NSObject {
    static let trackingAuthorizationDidResolve = Notification.Name(
        "Crailglitun.trackingAuthorizationDidResolve"
    )

    private let window: UIWindow
    private let attributionCoordinator: AttributionCoordinator
    private var hasStartedTrackingAuthorization = false
    private var isRequestingTrackingAuthorization = false

    init(window: UIWindow, attributionCoordinator: AttributionCoordinator) {
        self.window = window
        self.attributionCoordinator = attributionCoordinator
        super.init()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func start() {
        guard window.rootViewController == nil else { return }

        CrailglitunPushService.shared.onOpenWebHome = { [weak self] in
            self?.openWebHome() ?? false
        }

        window.overrideUserInterfaceStyle = .light
        window.tintColor = Palette.orange

        let controller = CrailglitunAttributionViewController(coordinator: attributionCoordinator)
        controller.onStart = { [weak self] in
            self?.hasStartedTrackingAuthorization = true
            self?.requestTrackingAuthorizationIfNeeded()
        }
        let navigationController = UINavigationController(rootViewController: controller)
        navigationController.navigationBar.prefersLargeTitles = false
        navigationController.setNavigationBarHidden(true, animated: false)
        controller.onShowNativeHome = { [weak self, weak navigationController] in
            guard let self,
                  let navigationController,
                  self.window.rootViewController === navigationController else { return }

            self.showNativeHome()
        }
        window.rootViewController = navigationController
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(requestTrackingAuthorizationIfNeeded),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        window.makeKeyAndVisible()
    }

    @objc
    private func requestTrackingAuthorizationIfNeeded() {
        guard hasStartedTrackingAuthorization,
              !isRequestingTrackingAuthorization,
              UIApplication.shared.applicationState == .active,
              window.rootViewController?.viewIfLoaded?.window != nil,
              ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }

        isRequestingTrackingAuthorization = true
        // The scene retains this router even after the launch controller is replaced.
        ATTrackingManager.requestTrackingAuthorization { [weak self] status in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isRequestingTrackingAuthorization = false
                // If iOS could not show the prompt, retry on a later activation.
                guard status != .notDetermined else { return }
                NotificationCenter.default.post(
                    name: Self.trackingAuthorizationDidResolve,
                    object: nil
                )
            }
        }
    }

    private func openWebHome() -> Bool {
        guard let navigationController = window.rootViewController as? UINavigationController,
              let webController = navigationController.viewControllers.first(where: {
                  $0 is CrailglitunExperienceViewController
              }) as? CrailglitunExperienceViewController else {
            return false
        }

        navigationController.dismiss(animated: false)
        navigationController.popToViewController(webController, animated: false)
        webController.openHomeFromNotification()
        return true
    }

    private func showNativeHome() {
        let store = AppStore.shared
        let controller = CrailglitunMainViewFactory.make(store: store)
        window.rootViewController = controller

        if store.startupError != nil {
            DispatchQueue.main.async { [weak self, weak controller] in
                guard let self,
                      let controller,
                      self.window.rootViewController === controller else { return }
                controller.notify(
                    "Unable to load saved work",
                    "Please close and reopen TurnScene. Do not uninstall the app, as this may delete your saved work."
                )
            }
        }

        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--self-test") {
            DispatchQueue.main.async {
                SelfTests.run()
            }
        }
        #endif
    }
}
