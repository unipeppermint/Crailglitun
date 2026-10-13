import UIKit

enum Palette {
    static let background = UIColor(hex: 0xF6F3EB)
    static let paper = UIColor(hex: 0xFFFDFA)
    static let ink = UIColor(hex: 0x252B29)
    static let secondary = UIColor(hex: 0x747B76)
    static let orange = UIColor(hex: 0xFF662D)
    static let teal = UIColor(hex: 0x568D83)
    static let line = UIColor(hex: 0xE6E2D8)
}
extension UIColor {
    convenience init(hex: Int) { self.init(red: CGFloat((hex >> 16) & 255)/255, green: CGFloat((hex >> 8) & 255)/255, blue: CGFloat(hex & 255)/255, alpha: 1) }
}
func label(_ text: String, _ size: CGFloat = 16, _ weight: UIFont.Weight = .regular, _ color: UIColor = Palette.ink) -> UILabel {
    let v = UILabel(); v.text = text; v.font = UIFontMetrics(forTextStyle: size >= 24 ? .title1 : size <= 13 ? .caption1 : .body).scaledFont(for: .systemFont(ofSize: size, weight: weight)); v.adjustsFontForContentSizeCategory = true; v.textColor = color; v.numberOfLines = 0; return v
}
func stack(_ views: [UIView] = [], axis: NSLayoutConstraint.Axis = .vertical, spacing: CGFloat = 12) -> UIStackView {
    let v = UIStackView(arrangedSubviews: views); v.axis = axis; v.spacing = spacing; return v
}
func button(_ title: String, icon: String? = nil, filled: Bool = false, action: @escaping () -> Void) -> UIButton {
    let b = UIButton(type: .system); b.setTitle(title, for: .normal)
    b.titleLabel?.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 16, weight: .semibold)); b.titleLabel?.adjustsFontForContentSizeCategory = true; b.titleLabel?.numberOfLines = 0; b.titleLabel?.textAlignment = .center
    b.setTitleColor(filled ? .white : Palette.ink, for: .normal)
    if let icon = icon { b.setImage(UIImage(systemName: icon,withConfiguration: UIImage.SymbolConfiguration(pointSize: 18,weight: .medium)), for: .normal); b.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 18,weight: .medium),forImageIn: .normal); b.imageView?.adjustsImageSizeForAccessibilityContentSizeCategory = false; b.imageView?.contentMode = .scaleAspectFit; b.tintColor = filled ? .white : Palette.teal; b.imageEdgeInsets = UIEdgeInsets(top: 0, left: -7, bottom: 0, right: 7) }
    b.backgroundColor = filled ? Palette.orange : Palette.paper; b.layer.cornerRadius = 16
    b.contentEdgeInsets = UIEdgeInsets(top: 15, left: 16, bottom: 15, right: 16)
    b.heightAnchor.constraint(greaterThanOrEqualToConstant: 50).isActive = true
    b.addAction(UIAction { _ in action() }, for: .touchUpInside); return b
}
func card(_ child: UIView, inset: CGFloat = 18) -> UIView {
    let v = UIView(); v.backgroundColor = Palette.paper; v.layer.cornerRadius = 16; v.layer.borderColor = Palette.line.cgColor; v.layer.borderWidth = 0.7
    v.addSubview(child); child.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([child.leadingAnchor.constraint(equalTo: v.leadingAnchor, constant: inset),child.trailingAnchor.constraint(equalTo: v.trailingAnchor, constant: -inset),child.topAnchor.constraint(equalTo: v.topAnchor, constant: inset),child.bottomAnchor.constraint(equalTo: v.bottomAnchor, constant: -inset)])
    return v
}
func photoView(_ image: UIImage? = nil, height: CGFloat = 180) -> UIImageView {
    let v = UIImageView(image: image); v.contentMode = .scaleAspectFill; v.clipsToBounds = true; v.layer.cornerRadius = 16; v.backgroundColor = Palette.line; v.heightAnchor.constraint(equalToConstant: height).isActive = true; return v
}
func loadPhoto(_ name: String?, into view: UIImageView, cropped: Bool = false, region: CropRegion? = nil) {
    view.accessibilityIdentifier = name
    guard let name = name else { return }
    MediaStore.queue.async {
        let image = MediaStore.image(name)
        let display = image.map { source in region.map { MediaStore.cropped(source,region: $0) } ?? (cropped ? MediaStore.square(source) : source) }
        DispatchQueue.main.async { if view.accessibilityIdentifier == name {
            view.image = display ?? UIImage(systemName: "exclamationmark.triangle")
            view.contentMode = display == nil ? .center : .scaleAspectFill
            view.tintColor = Palette.secondary
            if display == nil { view.isAccessibilityElement = true; view.accessibilityLabel = "照片无法读取，请重新导入" }
        } }
    }
}
class PageController: UIViewController {
    let scroll = UIScrollView()
    let body = stack(spacing: 20)
    override func viewDidLoad() {
        super.viewDidLoad(); view.backgroundColor = Palette.background
        view.addSubview(scroll); scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(body); body.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),scroll.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),body.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 12),body.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -28),body.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 20),body.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -20),body.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -40)])
        navigationItem.backButtonTitle = ""
        if navigationController?.viewControllers.first !== self {
            let back = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(goBack))
            if #available(iOS 26.0, *) { back.hidesSharedBackground = true }
            navigationItem.leftBarButtonItem = back
        }
    }
    @objc private func goBack() { navigationController?.popViewController(animated: true) }
    func clear() { body.arrangedSubviews.forEach { $0.removeFromSuperview() } }
    func heading(_ title: String, subtitle: String) { body.addArrangedSubview(stack([label(title, 32, .bold), label(subtitle, 14, .regular, Palette.secondary)], spacing: 8)) }
}
extension UIViewController {
    func notify(_ title: String, _ message: String) { let a = UIAlertController(title: title, message: message, preferredStyle: .alert); a.addAction(UIAlertAction(title: "知道了", style: .default)); present(a, animated: true) }
    func fail(_ error: Error) { notify("这一步未能完成", "你的现有内容仍保留。请检查可用存储空间后重试。\n\(error.localizedDescription)") }
    func push(_ vc: UIViewController) { vc.hidesBottomBarWhenPushed = true; navigationController?.pushViewController(vc, animated: true) }
    func sheet(_ title: String, options: [(String, () -> Void)], anchor: UIView? = nil) {
        let a = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        options.forEach { name, action in a.addAction(UIAlertAction(title: name, style: .default) { _ in action() }) }
        a.addAction(UIAlertAction(title: "取消", style: .cancel))
        a.popoverPresentationController?.sourceView = anchor ?? view; a.popoverPresentationController?.sourceRect = (anchor ?? view).bounds; present(a, animated: true)
    }
}

func serifLabel(_ text: String, size: CGFloat = 32) -> UILabel {
    let v = label(text, size, .semibold)
    v.font = UIFontMetrics(forTextStyle: .title1).scaledFont(for: UIFont(name: "TurnSceneSerif", size: size) ?? .systemFont(ofSize: size, weight: .semibold))
    return v
}
func compactButton(_ title: String, icon: String? = nil, action: @escaping () -> Void) -> UIButton {
    let b = UIButton(type: .system); b.setTitle(title, for: .normal)
    b.titleLabel?.font = UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: .systemFont(ofSize: 14, weight: .medium))
    b.setTitleColor(Palette.secondary, for: .normal); b.tintColor = Palette.ink
    if let icon = icon { b.setImage(UIImage(systemName: icon, withConfiguration: UIImage.SymbolConfiguration(pointSize: 14)), for: .normal); b.imageEdgeInsets = UIEdgeInsets(top: 0, left: -5, bottom: 0, right: 5) }
    b.backgroundColor = Palette.paper; b.layer.cornerRadius = 19; b.layer.borderColor = Palette.line.cgColor; b.layer.borderWidth = 0.8
    b.contentEdgeInsets = UIEdgeInsets(top: 9, left: 15, bottom: 9, right: 10)
    b.heightAnchor.constraint(greaterThanOrEqualToConstant: 36).isActive = true
    b.addAction(UIAction { _ in action() }, for: .touchUpInside); return b
}
func conditionStrip(_ task: PhotoTask) -> UIView {
    let row = stack(axis: .horizontal, spacing: 8); row.distribution = .fillEqually
    for value in task.values {
        let image = UIImageView(image: reelImage(value)); image.contentMode = .scaleAspectFit; image.widthAnchor.constraint(equalToConstant: 32).isActive = true; image.heightAnchor.constraint(equalToConstant: 38).isActive = true
        let text = label(shortCondition(value), 13, .medium); text.adjustsFontSizeToFitWidth = true; text.minimumScaleFactor = 0.7; text.numberOfLines = 1
        row.addArrangedSubview(stack([image,text], axis: .horizontal, spacing: 4))
    }
    let v = card(row, inset: 10); v.backgroundColor = UIColor(hex: 0xF0EDE5); return v
}
func shortCondition(_ value: String) -> String { value == "三格故事" ? "三格" : value == "同一位置" ? "同位置" : value }

func disclosureTitle(_ title: String, action: @escaping () -> Void) -> UIButton {
    let b = UIButton(type: .system); b.accessibilityLabel = title
    let text = label(title,19,.semibold); text.isUserInteractionEnabled = false
    let chevron = UIImageView(image: UIImage(systemName: "chevron.right",withConfiguration: UIImage.SymbolConfiguration(pointSize: 13))); chevron.tintColor = Palette.secondary; chevron.contentMode = .scaleAspectFit; chevron.widthAnchor.constraint(equalToConstant: 12).isActive = true
    let row = stack([text,chevron],axis: .horizontal,spacing: 8); row.alignment = .center; row.isUserInteractionEnabled = false
    b.addSubview(row); row.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([row.leadingAnchor.constraint(equalTo: b.leadingAnchor),row.trailingAnchor.constraint(equalTo: b.trailingAnchor),row.topAnchor.constraint(equalTo: b.topAnchor,constant: 3),row.bottomAnchor.constraint(equalTo: b.bottomAnchor,constant: -3),b.heightAnchor.constraint(greaterThanOrEqualToConstant: 32)])
    b.addAction(UIAction { _ in action() },for: .touchUpInside); return b
}
