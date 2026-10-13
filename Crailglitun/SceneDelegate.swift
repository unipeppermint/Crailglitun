import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    func scene(_ scene: UIScene,willConnectTo session: UISceneSession,options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: scene); window.overrideUserInterfaceStyle = .light; window.tintColor = Palette.orange
        let tabs = FlatTabController(); let store = AppStore.shared
        if let task = store.library.tasks.first {
            let screens: [(UIViewController,String,String)] = [(InspirationController(task: task),"TurnScene","rectangle.3.offgrid"),(ThemesController(),"Themes","square.grid.2x2"),(PortfolioController(),"Portfolio","photo.on.rectangle")]
            tabs.viewControllers = screens.map { screen,title,icon in
                let nav = UINavigationController(rootViewController: screen); nav.delegate = tabs; nav.setNavigationBarHidden(true, animated: false)
                nav.tabBarItem = UITabBarItem(title: title,image: UIImage(systemName: icon),selectedImage: UIImage(systemName: icon))
                let appearance = UINavigationBarAppearance(); appearance.configureWithOpaqueBackground(); appearance.backgroundColor = Palette.background; appearance.shadowColor = .clear; appearance.titleTextAttributes = [.foregroundColor: Palette.ink,.font: UIFont.systemFont(ofSize: 18,weight: .semibold)]
                nav.navigationBar.standardAppearance = appearance; nav.navigationBar.scrollEdgeAppearance = appearance; nav.navigationBar.tintColor = Palette.ink
                return nav
            }
        } else { tabs.viewControllers = [TextController(title: "Content unavailable",text: "Please close and reopen TurnScene. If the problem continues, contact support. Do not uninstall the app, as this may delete your saved work.")] }
        let appearance = UITabBarAppearance(); appearance.configureWithOpaqueBackground(); appearance.backgroundColor = Palette.paper; appearance.shadowColor = Palette.line
        tabs.tabBar.standardAppearance = appearance; if #available(iOS 15.0, *) { tabs.tabBar.scrollEdgeAppearance = appearance }
        tabs.tabBar.tintColor = Palette.orange; tabs.tabBar.unselectedItemTintColor = Palette.secondary
        window.rootViewController = store.library.tasks.isEmpty ? tabs.viewControllers?.first : tabs; self.window = window; window.makeKeyAndVisible()
        if store.startupError != nil { DispatchQueue.main.asyncAfter(deadline: .now()+0.6) { tabs.notify("Unable to load saved work","Please close and reopen TurnScene. Do not uninstall the app, as this may delete your saved work.") } }
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--self-test") { DispatchQueue.main.asyncAfter(deadline: .now()+1) { SelfTests.run() } }
        #endif
    }
}
