import UIKit

final class InspirationViewModel {
    let store: AppStore
    var environment = "室内"
    var minutes = 10
    var locked = Set<Int>()
    var task: PhotoTask
    var recent: [String] = []
    var spinning = false
    init(store: AppStore = .shared, task: PhotoTask) { self.store = store; self.task = task }
    var engine: TaskEngine { TaskEngine(tasks: store.library.tasks) }
    func choose(manual: (Int, String)? = nil) -> PhotoTask? {
        var values = task.values; var rules = locked
        if let (index, value) = manual { values[index] = value; rules.insert(index) }
        let candidates = engine.candidates(environment: environment, minutes: minutes, values: values, locked: rules)
        let completed = store.artworks.prefix(8).map { $0.task.id }
        return engine.pick(from: candidates, recent: recent + completed)
    }
}
final class ReelCell: UICollectionViewCell {
    let symbol = UIImageView()
    let text = label("", 16, .semibold)
    override init(frame: CGRect) {
        super.init(frame: frame)
        symbol.contentMode = .scaleAspectFit; symbol.isAccessibilityElement = false
        text.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 16,weight: .semibold),maximumPointSize: 24)
        text.numberOfLines = 1; text.textAlignment = .center; text.adjustsFontSizeToFitWidth = true; text.minimumScaleFactor = 0.7
        for child in [symbol, text] { contentView.addSubview(child); child.translatesAutoresizingMaskIntoConstraints = false }
        let preferredWidth = symbol.widthAnchor.constraint(equalToConstant: 80); preferredWidth.priority = .defaultHigh
        NSLayoutConstraint.activate([
            preferredWidth, symbol.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, constant: -8),
            symbol.heightAnchor.constraint(equalTo: symbol.widthAnchor),
            symbol.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            symbol.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -10),
            text.topAnchor.constraint(equalTo: symbol.bottomAnchor, constant: 1),
            text.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 3),
            text.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -3)
        ])
    }
    required init?(coder: NSCoder) { fatalError() }
    func setDistance(_ distance: CGFloat) {
        let progress = min(1, distance / ReelView.itemHeight)
        alpha = 1 - 0.68 * progress
        // Center neighboring pictures without reserving room for their hidden labels.
        symbol.transform = CGAffineTransform(translationX: 0, y: 10 * progress).scaledBy(x: 1 - 0.3 * progress, y: 1 - 0.3 * progress)
        text.alpha = max(0, 1 - distance / 42)
    }
    override func prepareForReuse() { super.prepareForReuse(); symbol.image = nil; setDistance(0) }
}
final class ReelView: UIView, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    static let itemHeight: CGFloat = 92
    private static let reelHeight: CGFloat = 240
    private var alignmentInset: CGFloat { (Self.reelHeight - Self.itemHeight) / 2 }
    let collection: UICollectionView
    let values: [String]
    var onChoose: ((String) -> Void)?
    var onRequestSelection: (() -> Void)?
    var selected: String = ""
    var locked = false { didSet { collection.isScrollEnabled = !locked; accessibilityValue = selected + (locked ? "，已锁定" : "，未锁定") } }
    private let wash = CAGradientLayer()
    init(values: [String]) {
        self.values = values
        let flow = UICollectionViewFlowLayout(); flow.minimumLineSpacing = 0
        collection = UICollectionView(frame: .zero, collectionViewLayout: flow)
        super.init(frame: .zero)
        backgroundColor = UIColor(hex: 0xE7E3D9); layer.cornerRadius = 16; clipsToBounds = true
        let center = UIView(); center.backgroundColor = UIColor(hex: 0xFFF0DE); addSubview(center); center.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([center.leadingAnchor.constraint(equalTo: leadingAnchor),center.trailingAnchor.constraint(equalTo: trailingAnchor),center.centerYAnchor.constraint(equalTo: centerYAnchor),center.heightAnchor.constraint(equalToConstant: Self.itemHeight + 16)])
        collection.backgroundColor = .clear; collection.showsVerticalScrollIndicator = false; collection.decelerationRate = .fast
        collection.register(ReelCell.self, forCellWithReuseIdentifier: "cell"); collection.dataSource = self; collection.delegate = self
        addSubview(collection); collection.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([collection.leadingAnchor.constraint(equalTo: leadingAnchor),collection.trailingAnchor.constraint(equalTo: trailingAnchor),collection.topAnchor.constraint(equalTo: topAnchor),collection.bottomAnchor.constraint(equalTo: bottomAnchor),heightAnchor.constraint(equalToConstant: Self.reelHeight)])
        wash.colors = [UIColor(hex: 0xD8D4CB).cgColor, UIColor(hex: 0xF6F2E9).cgColor, UIColor(hex: 0xFFF2E4).cgColor, UIColor(hex: 0xF6F2E9).cgColor, UIColor(hex: 0xD8D4CB).cgColor]; wash.locations = [0,0.2,0.5,0.8,1]; layer.insertSublayer(wash, at: 0); layer.borderWidth = 0.8; layer.borderColor = Palette.line.cgColor
        isAccessibilityElement = true; accessibilityTraits = .adjustable
    }
    required init?(coder: NSCoder) { fatalError() }
    override func layoutSubviews() { super.layoutSubviews(); wash.frame = bounds; updateFade() }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { values.count * 80 }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize { CGSize(width: collection.bounds.width, height: Self.itemHeight) }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! ReelCell
        let value = values[indexPath.item % values.count]; cell.text.text = value == "三格故事" ? "三格" : value == "同一位置" ? "同位置" : value
        cell.symbol.image = reelImage(value)
        cell.symbol.tintColor = UIColor(hex: 0x8D9188)
        return cell
    }
    func set(_ value: String, animated: Bool = false, duration: Double = 0.9, completion: (() -> Void)? = nil) {
        selected = value; accessibilityValue = value + (locked ? "，已锁定" : "，未锁定")
        guard let index = values.firstIndex(of: value) else { completion?(); return }
        layoutIfNeeded(); collection.layoutIfNeeded()
        let target = CGFloat(values.count * 40 + index) * Self.itemHeight - alignmentInset
        if animated {
            collection.contentOffset.y = target - CGFloat(values.count * 2) * Self.itemHeight
            UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseOut, .beginFromCurrentState], animations: { self.collection.contentOffset.y = target }, completion: { _ in self.updateFade(); completion?() })
        } else { collection.layer.removeAllAnimations(); collection.setContentOffset(CGPoint(x: 0, y: target), animated: false); collection.layoutIfNeeded(); updateFade(); completion?() }
    }
    func collectionView(_ collectionView: UICollectionView,didSelectItemAt indexPath: IndexPath) { if !locked { onRequestSelection?() } }
    override func accessibilityActivate() -> Bool { guard !locked else { return false }; onRequestSelection?(); return true }
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) { (cell as? ReelCell)?.setDistance(abs(cell.center.y - collection.contentOffset.y - collection.bounds.height / 2)) }
    func scrollViewDidScroll(_ scrollView: UIScrollView) { updateFade() }
    private func updateFade() {
        let center = collection.contentOffset.y + collection.bounds.height / 2
        for cell in collection.visibleCells {
            let distance = abs(cell.center.y - center)
            (cell as? ReelCell)?.setDistance(distance)
        }
    }
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let row = round((targetContentOffset.pointee.y + alignmentInset) / Self.itemHeight)
        targetContentOffset.pointee.y = row * Self.itemHeight - alignmentInset
    }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) { commit() }
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) { if !decelerate { commit() } }
    func commit() { let row = max(0, Int(round((collection.contentOffset.y + alignmentInset)/Self.itemHeight))); onChoose?(values[row % values.count]) }
    override func accessibilityIncrement() { adjust(1) }
    override func accessibilityDecrement() { adjust(-1) }
    func adjust(_ delta: Int) { guard !locked, let i = values.firstIndex(of: selected) else { return }; onChoose?(values[(i+delta+values.count)%values.count]) }
}

final class InspirationController: PageController {
    let model: InspirationViewModel
    var reels: [ReelView] = []
    var locks: [UIButton] = []
    let preview = stack(spacing: 0)
    let draftArea = stack(spacing: 8)
    let hint = label("保留喜欢的条件，再转一次", 12, .regular, Palette.secondary)
    var spinButton: UIButton!
    var filters: UIStackView!
    init(task: PhotoTask) { model = InspirationViewModel(task: task); super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }
    override func viewDidLoad() {
        super.viewDidLoad(); body.spacing = 12
        navigationItem.title = "转场"
        let gear = UIButton(type: .system); gear.setImage(UIImage(systemName: "gearshape", withConfiguration: UIImage.SymbolConfiguration(pointSize: 22)), for: .normal); gear.tintColor = Palette.ink; gear.accessibilityLabel = "设置"
        gear.widthAnchor.constraint(equalToConstant: 40).isActive = true; gear.heightAnchor.constraint(equalToConstant: 44).isActive = true
        gear.addAction(UIAction { [weak self] _ in self?.settings() }, for: .touchUpInside)
        let heading = stack([stack([serifLabel("转场", size: 36), label("转一下，遇见新的观察角度", 15, .regular, Palette.secondary)], spacing: 3), gear], axis: .horizontal, spacing: 10); heading.alignment = .top
        body.addArrangedSubview(heading); body.setCustomSpacing(10, after: heading)
        filters = stack(axis: .horizontal, spacing: 10); body.addArrangedSubview(filters); updateFilters()
        let columns = stack(axis: .horizontal, spacing: 10); columns.distribution = .fillEqually
        for i in 0..<3 {
            let values = Array(Set(model.store.library.tasks.map { $0.values[i] })).sorted()
            let reel = ReelView(values: values); reel.accessibilityLabel = ["对象","方式","限制"][i]
            reel.onChoose = { [weak self] value in self?.manual(i, value) }; reel.onRequestSelection = { [weak self] in self?.selectColumn(i) }; reels.append(reel)
            let title = label(["对象","方式","限制"][i], 14, .semibold, Palette.ink); title.textAlignment = .center; title.font = UIFontMetrics(forTextStyle: .caption1).scaledFont(for: .systemFont(ofSize: 12,weight: .medium),maximumPointSize: 18)
            let lock = compactButton("锁定", icon: "lock") { [weak self] in self?.toggle(i) }; lock.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium); lock.contentEdgeInsets = UIEdgeInsets(top: 9,left: 4,bottom: 9,right: 4); locks.append(lock)
            columns.addArrangedSubview(stack([title,reel,lock], spacing: 10))
        }
        let panel = card(columns, inset: 10); panel.backgroundColor = UIColor(hex: 0xFBF8F0); panel.layer.cornerRadius = 24; body.addArrangedSubview(panel); body.setCustomSpacing(10, after: panel)
        hint.textAlignment = .center; body.addArrangedSubview(hint)
        spinButton = button("转一下", icon: "arrow.clockwise", filled: true) { [weak self] in self?.spin() }; spinButton.accessibilityIdentifier = "spin"
        body.addArrangedSubview(spinButton); body.addArrangedSubview(preview); body.addArrangedSubview(draftArea)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshDraft), name: .creationsChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(settle), name: UIApplication.willResignActiveNotification, object: nil)
        updatePreview(); refreshDraft()
    }
    override func viewDidAppear(_ animated: Bool) { super.viewDidAppear(animated); if !model.spinning { sync() } }
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) { super.traitCollectionDidChange(previousTraitCollection); if isViewLoaded, filters != nil, previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory { updateFilters() } }
    func updateFilters() {
        filters.arrangedSubviews.forEach { $0.removeFromSuperview() }
        filters.axis = traitCollection.preferredContentSizeCategory.isAccessibilityCategory ? .vertical : .horizontal
        let env = compactButton(model.environment, icon: model.environment == "室内" ? "house" : "sun.max") { [weak self] in
            guard let self = self else { return }; self.sheet("在哪里观察？", options: ["室内","户外"].map { value in (value, { self.model.environment = value; self.filterChanged() }) })
        }
        let time = compactButton("\(model.minutes) 分钟", icon: "clock") { [weak self] in
            guard let self = self else { return }; self.sheet("给自己多少时间？", options: [5,10,20].map { value in ("\(value) 分钟", { self.model.minutes = value; self.filterChanged() }) })
        }
        if filters.axis == .horizontal { filters.addArrangedSubview(UIView()) }; filters.addArrangedSubview(env); filters.addArrangedSubview(time)
    }
    func filterChanged() { updateFilters(); if let task = model.choose() { model.task = task; sync(); updatePreview(); hint.text = "保留喜欢的条件，再转一次" } else { unavailable() } }
    func selectColumn(_ index: Int) {
        guard !model.spinning, !model.locked.contains(index) else { return }
        let candidates = model.engine.candidates(environment: model.environment,minutes: model.minutes,values: model.task.values,locked: model.locked)
        let values = Array(Set(candidates.map { $0.values[index] })).sorted()
        guard !values.isEmpty else { unavailable(); return }
        sheet("手动选择" + ["对象","方式","限制"][index],options: values.map { value in (value,{ [weak self] in self?.manual(index,value) }) })
    }
    func manual(_ index: Int, _ value: String) { guard !model.spinning, !model.locked.contains(index) else { sync(); return }; if let task = model.choose(manual: (index,value)) { model.task = task; sync(); updatePreview(); Preferences.shared.tick() } else { unavailable(); sync() } }
    func unavailable() { hint.text = "暂无匹配任务 · 请调整时间、环境或锁定条件"; preview.arrangedSubviews.forEach { $0.removeFromSuperview() }; preview.addArrangedSubview(card(label("这组条件暂时没有合适任务。\n试试更长的时间，或解锁一列。", 14, .regular, Palette.secondary))) }
    func toggle(_ i: Int) {
        guard !model.spinning else { return }
        if model.locked.contains(i) { model.locked.remove(i) } else { model.locked.insert(i) }
        Preferences.shared.tick(); sync(); spinButton.isEnabled = model.locked.count < 3; spinButton.alpha = spinButton.isEnabled ? 1 : 0.5
        hint.text = model.locked.count == 3 ? "已保留全部条件 · 解锁一列后再转" : "保留喜欢的条件，再转一次"
    }
    func sync() {
        for i in 0..<3 {
            reels[i].locked = model.locked.contains(i); reels[i].set(model.task.values[i])
            locks[i].setTitle(model.locked.contains(i) ? "已锁定" : "锁定", for: .normal)
            locks[i].setImage(UIImage(systemName: model.locked.contains(i) ? "lock.fill" : "lock"), for: .normal)
            locks[i].backgroundColor = model.locked.contains(i) ? Palette.teal : Palette.paper; locks[i].tintColor = model.locked.contains(i) ? .white : Palette.teal
            locks[i].setTitleColor(model.locked.contains(i) ? .white : Palette.secondary, for: .normal)
        }
    }
    func spin() {
        guard !model.spinning, model.locked.count < 3 else { return }
        guard let result = model.choose() else { unavailable(); return }
        model.spinning = true; model.task = result; model.recent.append(result.id); model.recent = Array(model.recent.suffix(5))
        spinButton.isEnabled = false; filters.isUserInteractionEnabled = false; reels.forEach { $0.isUserInteractionEnabled = false }; hint.text = "让灵感，慢慢停下来…"
        let active = (0..<3).filter { !model.locked.contains($0) }
        for i in active { reels[i].set(result.values[i], animated: !Preferences.shared.reduceMotion, duration: 0.75 + Double(i)*0.22) { [weak self] in
            guard self?.model.spinning == true else { return }; Preferences.shared.tick(); if i == active.last { self?.settle() }
        } }
    }
    @objc func settle() {
        guard isViewLoaded else { return }; model.spinning = false; sync(); spinButton.isEnabled = model.locked.count < 3; filters.isUserInteractionEnabled = true; reels.forEach { $0.isUserInteractionEnabled = true }; hint.text = "灵感已就位，去发现一点不同"; updatePreview()
    }
    func updatePreview() {
        preview.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let task = model.task
        guard task.environments.contains(model.environment), task.minutes <= model.minutes else { unavailable(); return }
        let image = photoView(UIImage(named: model.store.theme(task)?.image ?? ""), height: 56); image.widthAnchor.constraint(equalToConstant: 86).isActive = true; image.layer.cornerRadius = 9
        let copy = stack([label(task.title,15,.semibold),label(task.values.map(shortCondition).joined(separator: " · "),12,.regular,Palette.secondary)],spacing: 6)
        let arrow = UIImageView(image: UIImage(systemName: "chevron.right")); arrow.tintColor = Palette.ink; arrow.widthAnchor.constraint(equalToConstant: 10).isActive = true; arrow.contentMode = .scaleAspectFit
        let row = stack([image,copy,arrow],axis: .horizontal,spacing: 12); row.alignment = .center
        let view = card(stack([label("这次的灵感",12,.medium,Palette.secondary),row],spacing: 5),inset: 12); view.isUserInteractionEnabled = true; view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(detail))); view.accessibilityIdentifier = "task-preview"; view.isAccessibilityElement = true; view.accessibilityTraits = .button; view.accessibilityLabel = "这次的灵感，" + task.title + "，查看任务"
        preview.addArrangedSubview(view)
    }
    @objc func detail() { guard !model.spinning else { return }; push(TaskDetailController(task: model.task)) }
    @objc func settings() { push(SettingsController()) }
    @objc func refreshDraft() {
        guard isViewLoaded else { return }; draftArea.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if let draft = model.store.drafts.first {
            let image = photoView(UIImage(named: model.store.theme(draft.task)?.image ?? ""), height: 52); image.widthAnchor.constraint(equalToConstant: 86).isActive = true; image.layer.cornerRadius = 8
            if let name = draft.photos.compactMap({ $0 }).first { loadPhoto(name, into: image) }
            let copy = stack([label("继续上次创作",14,.semibold),label(draft.task.title,12,.regular,Palette.secondary)],spacing: 5)
            let arrow = label("›",24,.regular); arrow.setContentHuggingPriority(.required,for: .horizontal)
            let row = stack([image,copy,arrow],axis: .horizontal,spacing: 12); row.alignment = .center
            let view = card(row,inset: 12); let tap = UIControl(); view.addSubview(tap); tap.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([tap.leadingAnchor.constraint(equalTo: view.leadingAnchor),tap.trailingAnchor.constraint(equalTo: view.trailingAnchor),tap.topAnchor.constraint(equalTo: view.topAnchor),tap.bottomAnchor.constraint(equalTo: view.bottomAnchor)])
            tap.isAccessibilityElement = true; row.accessibilityElementsHidden = true; tap.accessibilityTraits = .button; tap.accessibilityLabel = "继续草稿，" + draft.task.title; tap.addAction(UIAction { [weak self] _ in self?.push(EditorController(creation: draft)) },for: .touchUpInside); draftArea.addArrangedSubview(view)
        }

    }
}

final class TaskDetailController: PageController {
    let task: PhotoTask
    init(task: PhotoTask) { self.task = task; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }
    override func viewDidLoad() {
        super.viewDidLoad(); title = "创作任务"
        body.spacing = 12
        body.addArrangedSubview(conditionStrip(task))
        let paper = stack(spacing: 14)
        let number = AppStore.shared.library.tasks.firstIndex(where: { $0.id == task.id }).map { $0 + 1 } ?? 1
        paper.addArrangedSubview(label(String(format: "灵感 NO.%03d", number),13,.regular,Palette.secondary))
        paper.addArrangedSubview(stack([serifLabel(task.title,size: 28),label(task.summary,15,.regular,Palette.secondary)],spacing: 6))
        let image = photoView(UIImage(named: AppStore.shared.theme(task)?.image ?? ""),height: 165); image.layer.cornerRadius = 11; image.accessibilityLabel = "主题封面"
        paper.addArrangedSubview(image)
        for (i, step) in task.steps.enumerated() {
            let number = label(String(format: "%02d", i+1),16,.medium,.white); number.textAlignment = .center; number.backgroundColor = Palette.orange; number.layer.cornerRadius = 18; number.clipsToBounds = true
            number.widthAnchor.constraint(equalToConstant: 36).isActive = true; number.heightAnchor.constraint(equalToConstant: 36).isActive = true
            let row = stack([number,stack([label(step,16,.semibold),label(task.hints[i],12,.regular,Palette.secondary)],spacing: 4)],axis: .horizontal,spacing: 12); row.alignment = .top; paper.addArrangedSubview(row)
        }
        let metrics = stack([label("◷  约 \(task.minutes) 分钟",13,.medium,Palette.secondary),label("▧  \(task.photoCount) 张照片",13,.medium,Palette.secondary)],axis: .horizontal,spacing: 10); metrics.distribution = .fillEqually
        for item in metrics.arrangedSubviews { item.backgroundColor = UIColor(hex: 0xF0EDE5); item.layer.cornerRadius = 16; item.clipsToBounds = true; (item as? UILabel)?.textAlignment = .center; item.heightAnchor.constraint(equalToConstant: 32).isActive = true }
        paper.addArrangedSubview(metrics); body.addArrangedSubview(card(paper,inset: 16))
        body.addArrangedSubview(button("开始创作",icon: "camera",filled: true) { [weak self] in
            guard let self = self else { return }; let creation = Creation(task: self.task)
            do { try AppStore.shared.save(creation); self.push(EditorController(creation: creation)) } catch { self.fail(error) }
        })
        let another = button("换个组合",icon: "arrow.clockwise") { [weak self] in self?.anotherTask() }; another.backgroundColor = .clear; another.layer.borderColor = UIColor(hex: 0xCBCBC3).cgColor; another.layer.borderWidth = 1; body.addArrangedSubview(another)
    }
    func anotherTask() {
        if let home = navigationController?.viewControllers.first as? InspirationController {
            navigationController?.popToRootViewController(animated: true)
            DispatchQueue.main.asyncAfter(deadline: .now()+0.35) { home.spin() }
        } else {
            let candidates = AppStore.shared.library.tasks.filter { $0.themeID == task.themeID && $0.id != task.id && $0.minutes <= task.minutes && !$0.environments.filter(task.environments.contains).isEmpty }
            guard let next = candidates.randomElement() else { notify("这个主题暂无其他匹配任务","返回主题馆看看其他主题吧。"); return }
            let detail = TaskDetailController(task: next); detail.hidesBottomBarWhenPushed = true
            if let nav = navigationController { nav.setViewControllers(Array(nav.viewControllers.dropLast()) + [detail],animated: true) }
        }
    }
}
