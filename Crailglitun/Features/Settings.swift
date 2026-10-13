import UIKit
import SafariServices

final class SettingsController: PageController {
    override func viewDidLoad() { super.viewDidLoad(); title = "Settings"; render() }
    func render() {
        clear(); body.spacing = 12
        body.addArrangedSubview(label("Experience",14,.regular,Palette.secondary))
        let controls = grouped([
            toggle("Haptics",value: Preferences.shared.haptics) { Preferences.shared.haptics = $0 },
            toggle("Spin Sounds",value: Preferences.shared.sound) { Preferences.shared.sound = $0 },
            settingRow("Motion", value: Preferences.shared.reduce ? "Reduce Motion" : "Follow System") { [weak self] in self?.sheet("Motion",options: [("Follow System",{ Preferences.shared.reduce = false; self?.render() }),("Reduce Motion",{ Preferences.shared.reduce = true; self?.render() })]) }
        ])
        body.addArrangedSubview(controls)
        let hint = label("Reduce Motion skips the spin animation.",12,.regular,Palette.secondary); body.addArrangedSubview(hint); body.setCustomSpacing(30,after: hint)
        body.addArrangedSubview(label("Work & Storage",14,.regular,Palette.secondary))
        let data = grouped([settingRow("Export Work") { [weak self] in self?.push(BatchExportController()) },settingRow("Storage") { [weak self] in self?.push(StorageController()) }]); body.addArrangedSubview(data); body.setCustomSpacing(30,after: data)
        body.addArrangedSubview(label("Help & About",14,.regular,Palette.secondary))
        body.addArrangedSubview(grouped(Self.documents.map { title,_,copy in
            settingRow(title) { [weak self] in
                let policyURL = title == "Privacy" ? URL(string: "https://tkzcpoj.netlify.app/turnscene/privacy-policy/") : nil
                self?.push(TextController(title: title,text: copy,link: policyURL))
            }
        }))
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let footer = label("Version " + version,12,.regular,Palette.secondary); footer.textAlignment = .center; body.addArrangedSubview(footer)
    }
    func grouped(_ rows: [UIView]) -> UIView {
        let contents = stack(spacing: 0)
        for (i,row) in rows.enumerated() {
            contents.addArrangedSubview(row)
            if i < rows.count - 1 { let line = UIView(); line.backgroundColor = Palette.line.withAlphaComponent(0.6); line.heightAnchor.constraint(equalToConstant: 0.5).isActive = true; contents.addArrangedSubview(line) }
        }
        return card(contents,inset: 0)
    }
    func settingRow(_ title: String, value: String = "", action: @escaping () -> Void) -> UIView {
        let row = stack([label(title,17),label(value,14,.regular,Palette.secondary),label("›",23,.regular,Palette.secondary)],axis: .horizontal,spacing: 12); row.alignment = .center
        row.arrangedSubviews[0].setContentHuggingPriority(.defaultLow,for: .horizontal)
        row.arrangedSubviews[1].setContentHuggingPriority(.required,for: .horizontal); row.arrangedSubviews[2].setContentHuggingPriority(.required,for: .horizontal)
        row.arrangedSubviews[1].setContentCompressionResistancePriority(.required,for: .horizontal)
        let view = paddedRow(row); let overlay = UIControl(); view.addSubview(overlay); overlay.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),overlay.topAnchor.constraint(equalTo: view.topAnchor),overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor)])
        overlay.isAccessibilityElement = true; row.accessibilityElementsHidden = true; overlay.accessibilityLabel = title + (value.isEmpty ? "" : ", " + value); overlay.accessibilityTraits = .button; overlay.addAction(UIAction { _ in action() },for: .touchUpInside); return view
    }
    func paddedRow(_ row: UIView) -> UIView {
        let view = UIView(); view.addSubview(row); row.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([row.leadingAnchor.constraint(equalTo: view.leadingAnchor,constant: 18),row.trailingAnchor.constraint(equalTo: view.trailingAnchor,constant: -18),row.topAnchor.constraint(equalTo: view.topAnchor,constant: 12),row.bottomAnchor.constraint(equalTo: view.bottomAnchor,constant: -12),view.heightAnchor.constraint(greaterThanOrEqualToConstant: 56)])
        return view
    }
    func toggle(_ title: String,value: Bool,action: @escaping (Bool)->Void) -> UIView {
        let control = UISwitch(); control.isOn = value; control.onTintColor = Palette.teal; control.accessibilityLabel = title
        control.addAction(UIAction { _ in action(control.isOn) },for: .valueChanged)
        let row = stack([label(title,17),control],axis: .horizontal,spacing: 14); row.alignment = .center; return paddedRow(row)
    }
    static let documents: [(String,String,String)] = [
        ("Help", "questionmark.circle", "Choose a task\n\nSet a location and time limit, then tap Spin. Lock a choice to keep it or swipe a reel to choose manually. If nothing matches, allow more time or unlock a reel.\n\nCapture and edit\n\nFollow the steps to take or import photos. Drag and pinch to crop, then add a caption. Changes are saved as a draft in Portfolio.\n\nSave and share\n\nSave your finished work and export an image to share it. Choose Try This Task Again to create another version.\n\nKeep your work\n\nWork is stored on this device. Uninstalling the app may delete it. Exported images cannot restore drafts, so keep copies of important photos."),
        ("Feedback", "bubble.left", "When reporting a problem, include your device model, iOS version and the steps to reproduce it."),
        ("Privacy", "hand.raised", "Photos and work\n\nTurnScene does not require an account. Photos, drafts and work stay on this device and are not uploaded by the app.\n\nCamera and library\n\nCamera access is requested only when you take a photo. You can import photos without it. The app receives only the images you select and does not change the originals.\n\nExport and share\n\nYou choose what to export and where to share it. Exports do not include photo location data.\n\nDelete data\n\nDelete work from its detail page, or remove drafts and clear the cache in Storage. Clearing the cache keeps your work. Uninstalling the app may delete local data."),
        ("About TurnScene", "sparkles", "A fresh look at the everyday.\n\nExplore photo tasks across six themes. Capture what you discover and build your own collection.")
    ]
}
final class TextController: PageController {
    let copy: String
    let link: URL?
    init(title: String,text: String,link: URL? = nil) { copy = text; self.link = link; super.init(nibName: nil,bundle: nil); self.title = title }
    required init?(coder: NSCoder) { fatalError() }
    override func viewDidLoad() {
        super.viewDidLoad()
        if let link = link {
            body.addArrangedSubview(button("View Full Privacy Policy",icon: "safari") { [weak self] in
                self?.present(SFSafariViewController(url: link),animated: true)
            })
        }
        let text = label(copy,16); let paragraph = NSMutableParagraphStyle(); paragraph.lineSpacing = 7
        text.attributedText = NSAttributedString(string: copy,attributes: [.font: UIFont.preferredFont(forTextStyle: .body),.foregroundColor: Palette.ink,.paragraphStyle: paragraph]); body.addArrangedSubview(text)
    }
}
final class StorageController: PageController {
    let usage = label("Calculating…",16,.medium)
    override func viewDidLoad() { super.viewDidLoad(); title = "Storage"; render(); refresh() }
    func render() {
        clear(); heading("Storage",subtitle: "Your photos and work are stored on this device.")
        body.addArrangedSubview(card(usage)); body.addArrangedSubview(button("Clear Cache",icon: "arrow.triangle.2.circlepath") { [weak self] in
            MediaStore.queue.async {
                do { if FileManager.default.fileExists(atPath: MediaStore.cache.path) { try FileManager.default.removeItem(at: MediaStore.cache) }; DispatchQueue.main.async { self?.refresh(); self?.notify("Cache cleared","Your photos, drafts and work are preserved.") } }
                catch { DispatchQueue.main.async { self?.fail(error) } }
            }
        })
        body.addArrangedSubview(label("Clearing the cache keeps your photos, drafts and work.",13,.regular,Palette.secondary))
        body.addArrangedSubview(label("Drafts · \(AppStore.shared.drafts.count)",20,.semibold))
        for item in AppStore.shared.drafts {
            body.addArrangedSubview(button("Delete Draft · \(item.task.title)",icon: "trash") { [weak self] in
                guard let self = self else { return }; let alert = UIAlertController(title: "Delete this draft?",message: "This draft and any photos not used by other work will be deleted from this device. This cannot be undone.",preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Keep",style: .cancel)); alert.addAction(UIAlertAction(title: "Delete",style: .destructive) { _ in do { try AppStore.shared.delete(item); self.render(); self.refresh() } catch { self.fail(error) } }); self.present(alert,animated: true)
            })
        }
    }
    func refresh() {
        MediaStore.queue.async { let originals = MediaStore.usage(MediaStore.root); let caches = MediaStore.usage(MediaStore.cache); DispatchQueue.main.async { [weak self] in self?.usage.text = "Work & Photos  \(ByteCountFormatter.string(fromByteCount: originals,countStyle: .file))\n\nCache  \(ByteCountFormatter.string(fromByteCount: caches,countStyle: .file))" } }
    }
}
