import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    func scene(_ scene: UIScene,willConnectTo session: UISceneSession,options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: scene); window.overrideUserInterfaceStyle = .light; window.tintColor = Palette.orange
        let tabs = FlatTabController(); let store = AppStore.shared
        if let task = store.library.tasks.first {
            let screens: [(UIViewController,String,String)] = [(InspirationController(task: task),"转场","rectangle.3.offgrid"),(ThemesController(),"主题馆","square.grid.2x2"),(PortfolioController(),"作品集","photo.on.rectangle")]
            tabs.viewControllers = screens.map { screen,title,icon in
                let nav = UINavigationController(rootViewController: screen); nav.delegate = tabs; nav.setNavigationBarHidden(true, animated: false)
                nav.tabBarItem = UITabBarItem(title: title,image: UIImage(systemName: icon),selectedImage: UIImage(systemName: icon))
                let appearance = UINavigationBarAppearance(); appearance.configureWithOpaqueBackground(); appearance.backgroundColor = Palette.background; appearance.shadowColor = .clear; appearance.titleTextAttributes = [.foregroundColor: Palette.ink,.font: UIFont.systemFont(ofSize: 18,weight: .semibold)]
                nav.navigationBar.standardAppearance = appearance; nav.navigationBar.scrollEdgeAppearance = appearance; nav.navigationBar.tintColor = Palette.ink
                return nav
            }
        } else { tabs.viewControllers = [TextController(title: "内容暂时无法载入",text: "请关闭后重新打开应用。若问题持续，请联系应用支持。请勿卸载应用，以免丢失本地作品。\n\(store.startupError?.localizedDescription ?? "任务库为空")")] }
        let appearance = UITabBarAppearance(); appearance.configureWithOpaqueBackground(); appearance.backgroundColor = Palette.paper; appearance.shadowColor = Palette.line
        tabs.tabBar.standardAppearance = appearance; if #available(iOS 15.0, *) { tabs.tabBar.scrollEdgeAppearance = appearance }
        tabs.tabBar.tintColor = Palette.orange; tabs.tabBar.unselectedItemTintColor = Palette.secondary
        window.rootViewController = store.library.tasks.isEmpty ? tabs.viewControllers?.first : tabs; self.window = window; window.makeKeyAndVisible()
        if let error = store.startupError { DispatchQueue.main.asyncAfter(deadline: .now()+0.6) { tabs.notify("本地资料暂时无法读取",error.localizedDescription + "\n请勿卸载应用，以免丢失现有资料。") } }
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--self-test") { DispatchQueue.main.asyncAfter(deadline: .now()+1) { SelfTests.run() } }
        #endif
    }
}
