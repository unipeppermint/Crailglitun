import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    private let integrations = AppIntegrationService.shared
    private var startupRouter: CrailglitunStartupRouter?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        let router = CrailglitunStartupRouter(
            window: window,
            attributionCoordinator: integrations.attributionCoordinator
        )
        self.window = window
        startupRouter = router
        router.start()
        integrations.handleSceneConnection(connectionOptions)
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        integrations.handleOpenURLContexts(URLContexts)
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        integrations.continueUserActivity(userActivity)
    }
}
