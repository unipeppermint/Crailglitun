import UIKit

final class ThemesController: PageController {
    var environment = "全部"
    let list = stack(spacing: 22)
    override func viewDidLoad() {
        super.viewDidLoad(); title = "主题馆"
        body.addArrangedSubview(stack([serifLabel("主题馆"),label("从一个小小的好奇开始",14,.regular,Palette.secondary)],spacing: 5))
        let control = UISegmentedControl(items: ["全部","室内","户外"]); control.selectedSegmentIndex = 0; control.selectedSegmentTintColor = Palette.paper
        control.addAction(UIAction { [weak self] _ in self?.environment = ["全部","室内","户外"][control.selectedSegmentIndex]; self?.render() },for: .valueChanged)
        body.addArrangedSubview(control); body.addArrangedSubview(list)
        render()
    }
    override func viewWillAppear(_ animated: Bool) { super.viewWillAppear(animated); if isViewLoaded { render() } }
    func render() {
        list.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for (index, theme) in AppStore.shared.library.themes.enumerated() {
            let tasks = AppStore.shared.library.tasks.filter { $0.themeID == theme.id && (environment == "全部" || $0.environments.contains(environment)) }
            guard !tasks.isEmpty else { continue }
            let count = Set(AppStore.shared.artworks.filter { $0.task.themeID == theme.id }.map { $0.task.id }).count
            let photo = photoView(UIImage(named: theme.image),height: 194)
            let text = stack([label("VOL. \(String(format: "%02d",index+1))   /   \(theme.environment)",11,.semibold,Palette.teal),label(theme.title,24,.semibold),label(theme.subtitle,13,.regular,Palette.secondary),label("\(count) / 10 个任务已完成     探索主题  ↗",12,.medium,Palette.teal)],spacing: 7)
            let content = stack([photo,text],spacing: 16); let cover = card(content,inset: 14)
            cover.isUserInteractionEnabled = true; let action = UIAction { [weak self] _ in self?.push(ThemeDetailController(theme: theme,environment: self?.environment ?? "全部")) }
            let overlay = UIControl(); cover.addSubview(overlay); overlay.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([overlay.topAnchor.constraint(equalTo: cover.topAnchor),overlay.bottomAnchor.constraint(equalTo: cover.bottomAnchor),overlay.leadingAnchor.constraint(equalTo: cover.leadingAnchor),overlay.trailingAnchor.constraint(equalTo: cover.trailingAnchor)])
            overlay.addAction(action,for: .touchUpInside); overlay.isAccessibilityElement = true; overlay.accessibilityLabel = "\(theme.title)，\(count) 个任务已完成，探索主题"; overlay.accessibilityTraits = .button
            list.addArrangedSubview(cover)
        }
    }
}
final class ThemeDetailController: PageController {
    let theme: Theme; let environment: String
    init(theme: Theme,environment: String) { self.theme = theme; self.environment = environment; super.init(nibName: nil,bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }
    override func viewDidLoad() {
        super.viewDidLoad(); title = theme.title
        body.addArrangedSubview(photoView(UIImage(named: theme.image),height: 220)); heading(theme.title,subtitle: theme.subtitle)
        body.addArrangedSubview(label("选择任务，开始创作",12,.regular,Palette.secondary))
        for task in AppStore.shared.library.tasks.filter({ $0.themeID == theme.id && (environment == "全部" || $0.environments.contains(environment)) }) {
            let completed = AppStore.shared.artworks.contains { $0.task.id == task.id }
            body.addArrangedSubview(button("\(completed ? "✓  " : "")\(task.title)\n\(task.minutes) 分钟 · \(task.method)",icon: "arrow.up.right") { [weak self] in self?.push(TaskDetailController(task: task)) })
            (body.arrangedSubviews.last as? UIButton)?.titleLabel?.numberOfLines = 2
        }
    }
}

final class PortfolioController: PageController {
    var mode = 0
    let list = stack(spacing: 18)
    let count = label("",13,.medium,Palette.teal)
    override func viewDidLoad() {
        super.viewDidLoad(); title = "作品集"
        body.spacing = 18
        let drafts = UIButton(type: .system); drafts.setTitle("草稿",for: .normal); drafts.titleLabel?.font = .systemFont(ofSize: 12); drafts.tintColor = Palette.secondary; drafts.addAction(UIAction { [weak self] _ in self?.mode = 2; (self?.body.arrangedSubviews.first { $0 is UISegmentedControl } as? UISegmentedControl)?.selectedSegmentIndex = UISegmentedControl.noSegment; self?.render() },for: .touchUpInside)
        let stats = stack([count,drafts],spacing: 2)
        let header = stack([stack([serifLabel("作品集",size: 34),label("把每一次发现，留在这里",14,.regular,Palette.secondary)],spacing: 5),stats],axis: .horizontal,spacing: 10); header.alignment = .center; count.textAlignment = .right; count.setContentHuggingPriority(.required,for: .horizontal); body.addArrangedSubview(header)
        let segmented = UISegmentedControl(items: ["全部作品","同题再看"]); segmented.selectedSegmentIndex = 0; segmented.selectedSegmentTintColor = Palette.orange; segmented.backgroundColor = UIColor(hex: 0xEDE9E0); segmented.heightAnchor.constraint(equalToConstant: 40).isActive = true
        segmented.setTitleTextAttributes([.foregroundColor: UIColor.white,.font: UIFont.systemFont(ofSize: 14,weight: .semibold)],for: .selected)
        segmented.setTitleTextAttributes([.foregroundColor: Palette.secondary,.font: UIFont.systemFont(ofSize: 14)],for: .normal)
        segmented.addAction(UIAction { [weak self] _ in self?.mode = segmented.selectedSegmentIndex; self?.render() },for: .valueChanged); body.addArrangedSubview(segmented); body.addArrangedSubview(list)
        NotificationCenter.default.addObserver(self,selector: #selector(render),name: .creationsChanged,object: nil); render()
    }
    @objc func batch() { push(BatchExportController()) }
    @objc func render() {
        guard isViewLoaded else { return }; list.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let store = AppStore.shared
        count.text = "\(store.artworks.count) 作品\n\(Set(store.artworks.map { $0.task.id }).count) 个系列"
        let items = mode == 2 ? store.drafts : store.artworks
        if items.isEmpty {
            let symbol = UIImageView(image: UIImage(systemName: mode == 2 ? "square.and.pencil" : "photo.on.rectangle.angled")); symbol.tintColor = Palette.teal; symbol.contentMode = .scaleAspectFit; symbol.heightAnchor.constraint(equalToConstant: 66).isActive = true
            let title = label(mode == 2 ? "灵感，随时可以继续" : "第一件作品，\n从一次观察开始",25,.semibold); title.textAlignment = .center
            let subtitle = label(mode == 2 ? "未完成的创作会自动保留在这里。" : "转一下，给眼前的生活一个新角度。\n这里将只展示你亲手创作的作品。",14,.regular,Palette.secondary); subtitle.textAlignment = .center
            list.addArrangedSubview(card(stack([symbol,title,subtitle,button("去找一个灵感",icon: "arrow.up.right",filled: true) { [weak self] in self?.tabBarController?.selectedIndex = 0 }],spacing: 24),inset: 28)); return
        }
        if mode == 1 {
            var seen = Set<String>()
            for item in items where seen.insert(item.task.id).inserted {
                let series = items.filter { $0.task.id == item.task.id }
                let photos = stack(axis: .horizontal,spacing: 8); photos.distribution = .fillEqually
                let date = DateFormatter(); date.dateFormat = "MM.dd"
                for work in series.prefix(2) {
                    let photo = photoView(height: 190); photo.layer.cornerRadius = 9; loadPhoto(work.photos.first ?? nil,into: photo)
                    photos.addArrangedSubview(stack([photo,label(date.string(from: work.updatedAt) + "  " + (work.caption.isEmpty ? "一次新的观察" : work.caption),12,.regular,Palette.secondary)],spacing: 6))
                }
                let open = disclosureTitle(item.task.title) { [weak self] in self?.push(CompareController(task: item.task)) }; open.contentHorizontalAlignment = .left; open.layer.borderWidth = 0; open.setTitleColor(Palette.ink,for: .normal)
                let content = stack([open,photos],spacing: 8)
                if series.count == 1 { content.addArrangedSubview(label("再创作一次，发现不同的光",12,.regular,Palette.secondary)) }
                list.addArrangedSubview(card(content,inset: 12))
                let again = button("用这组条件再创作") { [weak self] in self?.push(TaskDetailController(task: item.task)) }; again.setTitleColor(Palette.orange,for: .normal); again.layer.borderColor = Palette.orange.cgColor; again.layer.borderWidth = 1; list.addArrangedSubview(again)

            }
        } else {
            for item in items { list.addArrangedSubview(creationCard(item) { [weak self] in self?.push(item.completed ? ArtworkController(creation: item) : EditorController(creation: item)) }) }
        }
    }
}
func creationCard(_ item: Creation, action: @escaping () -> Void) -> UIView {
    let images = stack(axis: .horizontal,spacing: 6); images.distribution = .fillEqually
    for (i,name) in item.photos.enumerated() { let photo = photoView(height: item.photos.count == 1 ? 190 : 100); photo.layer.cornerRadius = 9; loadPhoto(name,into: photo,cropped: item.crops[i],region: item.cropRegions?[i]); images.addArrangedSubview(photo) }
    let open = disclosureTitle(item.task.title,action: action); open.contentHorizontalAlignment = .left; open.layer.borderWidth = 0; open.setTitleColor(Palette.ink,for: .normal); open.titleLabel?.font = .systemFont(ofSize: 19,weight: .semibold)
    let view = card(stack([open,images,conditionStrip(item.task)],spacing: 10),inset: 12)
    return view
}

final class ArtworkController: PageController {
    var creation: Creation
    init(creation: Creation) { self.creation = creation; super.init(nibName: nil,bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }
    override func viewDidLoad() { super.viewDidLoad(); title = "作品" }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated); if let updated = AppStore.shared.creations.first(where: { $0.id == creation.id }) { creation = updated }; render()
    }
    func render() {
        clear(); heading(creation.task.title,subtitle: creation.task.values.joined(separator: " · "))
        let gallery = stack(axis: .horizontal,spacing: 6); gallery.distribution = .fillEqually
        for (i,name) in creation.photos.enumerated() { let photo = photoView(height: creation.photos.count == 1 ? 320 : 250); photo.layer.cornerRadius = 8; loadPhoto(name,into: photo,cropped: creation.crops[i],region: creation.cropRegions?[i]); gallery.addArrangedSubview(photo) }
        let composition = stack([gallery],spacing: 18)
        if !creation.caption.isEmpty { composition.addArrangedSubview(label(creation.caption,17,.regular)) }
        body.addArrangedSubview(card(composition,inset: creation.layout == "留白" ? 18 : 6))
        body.addArrangedSubview(button("导出作品",icon: "square.and.arrow.up",filled: true) { [weak self] in guard let self = self else { return }; ExportCoordinator.share([self.creation],from: self) })
        body.addArrangedSubview(button("编辑作品",icon: "square.and.pencil") { [weak self] in guard let self = self else { return }; self.push(EditorController(creation: self.creation)) })
        body.addArrangedSubview(button("用这组条件再创作",icon: "arrow.clockwise") { [weak self] in self?.again() })
        body.addArrangedSubview(button("同题对照",icon: "rectangle.split.2x1") { [weak self] in guard let self = self else { return }; self.push(CompareController(task: self.creation.task)) })
        body.addArrangedSubview(button("删除作品",icon: "trash") { [weak self] in self?.delete() })
    }
    func again() { let draft = Creation(task: creation.task); do { try AppStore.shared.save(draft); push(EditorController(creation: draft)) } catch { fail(error) } }
    func delete() {
        let a = UIAlertController(title: "删除这件作品？",message: "作品记录会从本机移除，未被其他草稿或作品使用的照片也会删除。此操作无法撤销。",preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "保留",style: .cancel)); a.addAction(UIAlertAction(title: "删除",style: .destructive) { [weak self] _ in guard let self = self else { return }; do { try AppStore.shared.delete(self.creation); self.navigationController?.popViewController(animated: true) } catch { self.fail(error) } }); present(a,animated: true)
    }
}
final class CompareController: PageController {
    let task: PhotoTask
    var chosen: [UUID] = []
    var items: [Creation] { AppStore.shared.artworks.filter { $0.task.id == task.id && $0.task.values == task.values } }
    init(task: PhotoTask) { self.task = task; super.init(nibName: nil,bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }
    override func viewDidLoad() { super.viewDidLoad(); title = "同题再看"; chosen = Array(items.prefix(2).map(\.id)); render() }
    func render() {
        clear(); heading(task.title,subtitle: "相同的条件，每次都有新的发现。")
        if items.count < 2 { body.addArrangedSubview(card(label("还差一次观察\n\n完成第二件同题作品后，就能在这里比较两次的光线、细节与心情。",17))) }
        else {
            for i in 0..<2 {
                guard let item = items.first(where: { $0.id == chosen[i] }) else { continue }
                let formatter = DateFormatter(); formatter.dateFormat = "MM.dd HH:mm"
                body.addArrangedSubview(button("\(i == 0 ? "第一次选择" : "第二次选择") · \(formatter.string(from: item.updatedAt))",icon: "chevron.down") { [weak self] in self?.select(i) })
                let row = stack(axis: .horizontal,spacing: 5); row.distribution = .fillEqually
                for (n,name) in item.photos.enumerated() { let photo = photoView(height: 175); loadPhoto(name,into: photo,cropped: item.crops[n],region: item.cropRegions?[n]); row.addArrangedSubview(photo) }
                body.addArrangedSubview(row); if !item.caption.isEmpty { body.addArrangedSubview(label(item.caption,14,.regular,Palette.secondary)) }
            }
        }
        body.addArrangedSubview(button("用这组条件再创作",icon: "arrow.clockwise",filled: true) { [weak self] in guard let self = self else { return }; let draft = Creation(task: self.task); do { try AppStore.shared.save(draft); self.push(EditorController(creation: draft)) } catch { self.fail(error) } })
    }
    func select(_ index: Int) {
        let formatter = DateFormatter(); formatter.dateFormat = "yyyy.MM.dd HH:mm:ss"
        sheet("选择一次观察",options: items.filter { $0.id != chosen[1-index] }.map { item in (formatter.string(from: item.updatedAt) + " " + item.caption,{ [weak self] in self?.chosen[index] = item.id; self?.render() }) })
    }
}
final class BatchExportController: PageController {
    var selected = Set<UUID>()
    override func viewDidLoad() { super.viewDidLoad(); title = "导出作品"; render() }
    func render() {
        clear(); heading("把发现，带走。",subtitle: "选择作品，导出为高清 JPG 图片。\n图片不包含可恢复的草稿与系列数据。")
        if AppStore.shared.artworks.isEmpty { body.addArrangedSubview(card(label("还没有可以导出的作品。\n完成第一份任务后，再来这里吧。",16))); return }
        body.addArrangedSubview(button("导出选中的 \(selected.count) 件作品",icon: "square.and.arrow.up",filled: true) { [weak self] in
            guard let self = self else { return }; let items = AppStore.shared.artworks.filter { self.selected.contains($0.id) }; if items.isEmpty { self.notify("先选择作品","点击下方作品，选择要导出的内容。"); return }; ExportCoordinator.share(items,from: self)
        })
        for item in AppStore.shared.artworks { body.addArrangedSubview(button("\(selected.contains(item.id) ? "✓" : "○")  \(item.task.title)") { [weak self] in guard let self = self else { return }; if self.selected.contains(item.id) { self.selected.remove(item.id) } else { self.selected.insert(item.id) }; self.render() }) }
    }
}
nonisolated final class ExportJob: @unchecked Sendable {
    private let lock = NSLock(); private var cancelled = false
    func cancel() { lock.lock(); cancelled = true; lock.unlock() }
    var isCancelled: Bool { lock.lock(); defer { lock.unlock() }; return cancelled }
}
enum ExportCoordinator {
    static func share(_ items: [Creation],from controller: UIViewController) { run(items,from: controller,preview: false) }
    static func preview(_ item: Creation,from controller: UIViewController) { run([item],from: controller,preview: true) }
    static func run(_ items: [Creation],from controller: UIViewController,preview: Bool) {
        let job = ExportJob()
        let progress = UIAlertController(title: preview ? "正在生成预览" : "正在导出作品",message: "0 / \(items.count)",preferredStyle: .alert)
        progress.addAction(UIAlertAction(title: "取消",style: .cancel) { _ in job.cancel() })
        controller.present(progress,animated: true)
        MediaStore.queue.async {
            var urls: [URL] = []
            do {
                for item in items {
                    if job.isCancelled { break }
                    let url = try autoreleasepool { try MediaStore.export(item) }; urls.append(url)
                    let count = urls.count; DispatchQueue.main.async { progress.message = "\(count) / \(items.count)" }
                }
                let result = urls
                DispatchQueue.main.async {
                    guard !job.isCancelled else { result.forEach { try? FileManager.default.removeItem(at: $0) }; return }
                    progress.dismiss(animated: true) {
                        if preview, let url = result.first { controller.push(ExportPreviewController(url: url)); return }
                        let sheet = UIActivityViewController(activityItems: result,applicationActivities: nil)
                        sheet.popoverPresentationController?.sourceView = controller.view; sheet.popoverPresentationController?.sourceRect = controller.view.bounds
                        sheet.completionWithItemsHandler = { _,_,_,error in MediaStore.queue.async { result.forEach { try? FileManager.default.removeItem(at: $0) } }; if let error = error { controller.fail(error) } }
                        controller.present(sheet,animated: true)
                    }
                }
            } catch {
                urls.forEach { try? FileManager.default.removeItem(at: $0) }
                DispatchQueue.main.async { if !job.isCancelled { progress.dismiss(animated: true) { controller.fail(error) } } }
            }
        }
    }
}
final class ExportPreviewController: PageController {
    let url: URL
    init(url: URL) { self.url = url; super.init(nibName: nil,bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }
    override func viewDidLoad() { super.viewDidLoad(); title = "版式预览"; let image = UIImage(contentsOfFile: url.path); let v = UIImageView(image: image); v.contentMode = .scaleAspectFit; if let image = image { v.heightAnchor.constraint(equalTo: v.widthAnchor,multiplier: image.size.height/image.size.width).isActive = true }; body.addArrangedSubview(v); body.addArrangedSubview(label("这是最终导出图片的排版效果。",13,.regular,Palette.secondary)) }
    override func viewDidDisappear(_ animated: Bool) { super.viewDidDisappear(animated); if isMovingFromParent { let path = url; MediaStore.queue.async { try? FileManager.default.removeItem(at: path) } } }
}
