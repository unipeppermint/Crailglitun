import UIKit

final class SettingsController: PageController {
    override func viewDidLoad() { super.viewDidLoad(); title = "设置"; render() }
    func render() {
        clear(); body.spacing = 12
        body.addArrangedSubview(label("交互体验",14,.regular,Palette.secondary))
        let controls = grouped([
            toggle("触感反馈",value: Preferences.shared.haptics) { Preferences.shared.haptics = $0 },
            toggle("转动音效",value: Preferences.shared.sound) { Preferences.shared.sound = $0 },
            settingRow("动态效果", value: Preferences.shared.reduce ? "减少动态" : "跟随系统") { [weak self] in self?.sheet("动态效果",options: [("跟随系统",{ Preferences.shared.reduce = false; self?.render() }),("减少动态",{ Preferences.shared.reduce = true; self?.render() })]) }
        ])
        body.addArrangedSubview(controls)
        let hint = label("减少动态效果时，直接显示组合结果",12,.regular,Palette.secondary); body.addArrangedSubview(hint); body.setCustomSpacing(30,after: hint)
        body.addArrangedSubview(label("作品与数据",14,.regular,Palette.secondary))
        let data = grouped([settingRow("导出作品") { [weak self] in self?.push(BatchExportController()) },settingRow("存储管理") { [weak self] in self?.push(StorageController()) }]); body.addArrangedSubview(data); body.setCustomSpacing(30,after: data)
        body.addArrangedSubview(label("帮助与关于",14,.regular,Palette.secondary))
        body.addArrangedSubview(grouped(Self.documents.map { title,_,copy in settingRow(title) { [weak self] in self?.push(TextController(title: title,text: copy)) } }))
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let footer = label("版本 " + version,12,.regular,Palette.secondary); footer.textAlignment = .center; body.addArrangedSubview(footer)
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
        let view = paddedRow(row); let overlay = UIControl(); view.addSubview(overlay); overlay.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),overlay.topAnchor.constraint(equalTo: view.topAnchor),overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor)])
        overlay.isAccessibilityElement = true; row.accessibilityElementsHidden = true; overlay.accessibilityLabel = title + (value.isEmpty ? "" : "，" + value); overlay.accessibilityTraits = .button; overlay.addAction(UIAction { _ in action() },for: .touchUpInside); return view
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
        ("使用帮助", "questionmark.circle", "选择任务\n\n设置环境和时长，点击「转一下」。锁定喜欢的条件后可以继续转动，也可以滑动滚轮手动选择。没有匹配任务时，延长时间或解锁一列。\n\n拍摄与编辑\n\n按步骤拍摄或导入照片，拖动、缩放调整裁切，再添加配文。修改会自动保存为草稿，可在作品集中继续。\n\n保存与分享\n\n完成后保存作品，导出图片即可分享。想尝试同一个任务，可在作品详情选择「用这组条件再创作」。\n\n保留作品\n\n作品保存在本机。卸载应用可能丢失本地数据；导出图片不能恢复草稿，请妥善保存重要照片。"),
        ("意见反馈", "bubble.left", "反馈问题时，请附上设备型号、系统版本和操作步骤，便于定位问题。"),
        ("隐私说明", "hand.raised", "照片与作品\n\n转场无需注册，照片、草稿和作品保存在本机，不会由应用上传。\n\n相机与图库\n\n拍摄时才会请求相机权限；拒绝后仍可导入照片。图库仅接收你选中的图片，不会修改原件。\n\n导出与分享\n\n由你选择是否导出以及分享给谁，导出图片不包含拍摄位置。\n\n删除数据\n\n可在作品详情删除作品，在存储管理删除草稿或清理缓存。清理缓存不会删除作品，卸载应用可能清除本地数据。"),
        ("关于转场", "sparkles", "转一下，换个角度看日常。\n\n从六个主题的摄影任务出发，拍下身边的发现，留在自己的作品集中。")
    ]
}
final class TextController: PageController {
    let copy: String
    init(title: String,text: String) { copy = text; super.init(nibName: nil,bundle: nil); self.title = title }
    required init?(coder: NSCoder) { fatalError() }
    override func viewDidLoad() { super.viewDidLoad(); let text = label(copy,16); let paragraph = NSMutableParagraphStyle(); paragraph.lineSpacing = 7; text.attributedText = NSAttributedString(string: copy,attributes: [.font: UIFont.preferredFont(forTextStyle: .body),.foregroundColor: Palette.ink,.paragraphStyle: paragraph]); body.addArrangedSubview(text) }
}
final class StorageController: PageController {
    let usage = label("正在计算…",16,.medium)
    override func viewDidLoad() { super.viewDidLoad(); title = "存储管理"; render(); refresh() }
    func render() {
        clear(); heading("存储管理",subtitle: "照片与作品保存在本机。")
        body.addArrangedSubview(card(usage)); body.addArrangedSubview(button("清理缓存",icon: "arrow.triangle.2.circlepath") { [weak self] in
            MediaStore.queue.async {
                do { if FileManager.default.fileExists(atPath: MediaStore.cache.path) { try FileManager.default.removeItem(at: MediaStore.cache) }; DispatchQueue.main.async { self?.refresh(); self?.notify("缓存已清理","原素材、草稿与作品均已保留。") } }
                catch { DispatchQueue.main.async { self?.fail(error) } }
            }
        })
        body.addArrangedSubview(label("清理缓存不会删除照片、草稿和作品。",13,.regular,Palette.secondary))
        body.addArrangedSubview(label("草稿 · \(AppStore.shared.drafts.count)",20,.semibold))
        for item in AppStore.shared.drafts {
            body.addArrangedSubview(button("删除草稿 · \(item.task.title)",icon: "trash") { [weak self] in
                guard let self = self else { return }; let alert = UIAlertController(title: "删除这份草稿？",message: "草稿与未被其他作品使用的照片将从本机移除，无法撤销。",preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "保留",style: .cancel)); alert.addAction(UIAlertAction(title: "删除",style: .destructive) { _ in do { try AppStore.shared.delete(item); self.render(); self.refresh() } catch { self.fail(error) } }); self.present(alert,animated: true)
            })
        }
    }
    func refresh() {
        MediaStore.queue.async { let originals = MediaStore.usage(MediaStore.root); let caches = MediaStore.usage(MediaStore.cache); DispatchQueue.main.async { [weak self] in self?.usage.text = "作品与素材  \(ByteCountFormatter.string(fromByteCount: originals,countStyle: .file))\n\n可清理缓存  \(ByteCountFormatter.string(fromByteCount: caches,countStyle: .file))" } }
    }
}
