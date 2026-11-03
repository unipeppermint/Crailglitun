import UIKit

@MainActor
final class CrailglitunStartupRouter {
    private let window: UIWindow
    private let attributionCoordinator: AttributionCoordinator

    init(window: UIWindow, attributionCoordinator: AttributionCoordinator) {
        self.window = window
        self.attributionCoordinator = attributionCoordinator
    }

    func start() {
        guard window.rootViewController == nil else { return }

        window.overrideUserInterfaceStyle = .light
        window.tintColor = Palette.orange

        let controller = AttributionViewController(coordinator: attributionCoordinator)
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
        window.makeKeyAndVisible()
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
