import UIKit

@MainActor
enum CrailglitunMainViewFactory {
    static func make(store: AppStore) -> UIViewController {
        guard let task = store.library.tasks.first else {
            return TextController(
                title: "Content unavailable",
                text: "Please close and reopen TurnScene. If the problem continues, contact support. Do not uninstall the app, as this may delete your saved work."
            )
        }

        let tabs = FlatTabController()
        let screens: [(UIViewController, String, String)] = [
            (InspirationController(task: task), "TurnScene", "rectangle.3.offgrid"),
            (ThemesController(), "Themes", "square.grid.2x2"),
            (PortfolioController(), "Portfolio", "photo.on.rectangle")
        ]
        tabs.viewControllers = screens.map { screen, title, icon in
            let navigation = UINavigationController(rootViewController: screen)
            navigation.delegate = tabs
            navigation.setNavigationBarHidden(true, animated: false)
            navigation.tabBarItem = UITabBarItem(
                title: title,
                image: UIImage(systemName: icon),
                selectedImage: UIImage(systemName: icon)
            )

            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = Palette.background
            appearance.shadowColor = .clear
            appearance.titleTextAttributes = [
                .foregroundColor: Palette.ink,
                .font: UIFont.systemFont(ofSize: 18, weight: .semibold)
            ]
            navigation.navigationBar.standardAppearance = appearance
            navigation.navigationBar.scrollEdgeAppearance = appearance
            navigation.navigationBar.tintColor = Palette.ink
            return navigation
        }

        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = Palette.paper
        appearance.shadowColor = Palette.line
        tabs.tabBar.standardAppearance = appearance
        tabs.tabBar.scrollEdgeAppearance = appearance
        tabs.tabBar.tintColor = Palette.orange
        tabs.tabBar.unselectedItemTintColor = Palette.secondary
        return tabs
    }
}
