import UIKit

/// Keeps the prototype's full-width navigation consistent across iOS versions.
final class FlatTabController: UITabBarController, UINavigationControllerDelegate {
    private let bar = UIView()
    private var buttons: [UIButton] = []
    override var selectedIndex: Int { didSet { refresh() } }
    override func viewDidLoad() {
        super.viewDidLoad(); tabBar.isHidden = true
        bar.backgroundColor = Palette.paper; view.addSubview(bar); bar.translatesAutoresizingMaskIntoConstraints = false
        let row = stack(axis: .horizontal, spacing: 0); row.distribution = .fillEqually
        bar.addSubview(row); row.translatesAutoresizingMaskIntoConstraints = false
        let line = UIView(); line.backgroundColor = Palette.line; bar.addSubview(line); line.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([bar.leadingAnchor.constraint(equalTo: view.leadingAnchor),bar.trailingAnchor.constraint(equalTo: view.trailingAnchor),bar.bottomAnchor.constraint(equalTo: view.bottomAnchor),bar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -55),row.topAnchor.constraint(equalTo: bar.topAnchor),row.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),row.leadingAnchor.constraint(equalTo: bar.leadingAnchor,constant: 18),row.trailingAnchor.constraint(equalTo: bar.trailingAnchor,constant: -18),line.topAnchor.constraint(equalTo: bar.topAnchor),line.leadingAnchor.constraint(equalTo: bar.leadingAnchor),line.trailingAnchor.constraint(equalTo: bar.trailingAnchor),line.heightAnchor.constraint(equalToConstant: 0.5)])
        for (index, item) in [("TurnScene","house"),("Themes","square.grid.2x2"),("Portfolio","photo")].enumerated() {
            let b = UIButton(type: .system)
            let image = UIImageView(image: UIImage(systemName: item.1,withConfiguration: UIImage.SymbolConfiguration(pointSize: 22))); image.contentMode = .scaleAspectFit; image.heightAnchor.constraint(equalToConstant: 25).isActive = true
            let text = label(item.0,11,.medium); text.textAlignment = .center; text.tag = 100
            let content = stack([image,text],spacing: 2); content.isUserInteractionEnabled = false; b.addSubview(content); content.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([content.centerXAnchor.constraint(equalTo: b.centerXAnchor),content.centerYAnchor.constraint(equalTo: b.centerYAnchor)])
            b.accessibilityLabel = item.0

            b.addAction(UIAction { [weak self] _ in self?.selectedIndex = index },for: .touchUpInside); buttons.append(b); row.addArrangedSubview(b)
        }
        for case let nav as UINavigationController in viewControllers ?? [] { nav.delegate = self }
        refresh()
    }
    override func viewDidLayoutSubviews() { super.viewDidLayoutSubviews(); tabBar.isHidden = true; view.bringSubviewToFront(bar) }
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        let root = navigationController.viewControllers.first === viewController
        navigationController.setNavigationBarHidden(root, animated: animated)
        navigationController.additionalSafeAreaInsets.bottom = root ? 55 : 0
        if navigationController === selectedViewController { bar.isHidden = !root }
    }
    private func refresh() {
        guard isViewLoaded else { return }
        for (index, b) in buttons.enumerated() { b.tintColor = index == selectedIndex ? Palette.orange : Palette.secondary; (b.viewWithTag(100) as? UILabel)?.textColor = b.tintColor; b.accessibilityTraits = index == selectedIndex ? [.button,.selected] : .button }
        if let nav = selectedViewController as? UINavigationController, let screen = nav.topViewController { navigationController(nav,willShow: screen,animated: false) }
    }
}
