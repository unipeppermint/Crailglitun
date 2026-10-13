import UIKit
import PhotosUI
import AVFoundation
import UniformTypeIdentifiers

final class EditorController: PageController, PHPickerViewControllerDelegate, UITextViewDelegate {
    var creation: Creation
    var selectedSlot = 0
    let slots = stack(spacing: 14)
    let caption = UITextView()
    let status = label("草稿已保存到本机",12,.regular,Palette.teal)
    var saveWork: DispatchWorkItem?
    var busy = false
    var finished = false
    init(creation: Creation) {
        var draft = creation
        if creation.completed {
            if let existing = AppStore.shared.drafts.first(where: { $0.editingArtworkID == creation.id }) { draft = existing }
            else { draft.id = UUID(); draft.completed = false; draft.editingArtworkID = creation.id }
        }
        if draft.cropRegions == nil { draft.cropRegions = Array(repeating: nil,count: draft.photos.count) }
        self.creation = draft
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }
    override func viewDidLoad() {
        super.viewDidLoad(); title = "创作中"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "预览", style: .plain, target: self, action: #selector(preview))
        heading(creation.task.title, subtitle: "\(creation.task.values.joined(separator: " · "))\n按自己的节奏，完成这次观察。")
        body.addArrangedSubview(status); body.addArrangedSubview(slots); renderSlots()
        body.addArrangedSubview(label("为这一刻，留一句话",20,.semibold))
        caption.text = creation.caption; caption.font = .preferredFont(forTextStyle: .body); caption.adjustsFontForContentSizeCategory = true; caption.textColor = Palette.ink; caption.backgroundColor = Palette.paper; caption.layer.cornerRadius = 16; caption.textContainerInset = UIEdgeInsets(top: 16,left: 12,bottom: 16,right: 12); caption.delegate = self; caption.heightAnchor.constraint(equalToConstant: 120).isActive = true; caption.accessibilityLabel = "作品配文，最多 120 字"; caption.accessibilityIdentifier = "caption"
        let toolbar = UIToolbar(); toolbar.sizeToFit(); toolbar.items = [UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),UIBarButtonItem(title: "完成",style: .done,target: self,action: #selector(endTyping))]; caption.inputAccessoryView = toolbar
        body.addArrangedSubview(caption); body.addArrangedSubview(label("可选 · 最多 120 字",12,.regular,Palette.secondary))
        let layout = UISegmentedControl(items: ["留白","紧凑"]); layout.selectedSegmentIndex = creation.layout == "留白" ? 0 : 1; layout.selectedSegmentTintColor = Palette.paper
        layout.addAction(UIAction { [weak self] _ in self?.creation.layout = layout.selectedSegmentIndex == 0 ? "留白" : "紧凑"; self?.persist() },for: .valueChanged)
        body.addArrangedSubview(label("作品版式",17,.semibold)); body.addArrangedSubview(layout)
        body.addArrangedSubview(button("完成并保存作品",icon: "checkmark",filled: true) { [weak self] in self?.complete() })
        body.addArrangedSubview(label("照片与配文仅保存在这台设备。离开时自动保留草稿。",12,.regular,Palette.secondary))
        scroll.keyboardDismissMode = .interactive
        NotificationCenter.default.addObserver(self,selector: #selector(keyboardChanged(_:)),name: UIResponder.keyboardWillChangeFrameNotification,object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(backgroundSave), name: UIApplication.willResignActiveNotification, object: nil)
        persist()
    }
    override func viewWillDisappear(_ animated: Bool) { super.viewWillDisappear(animated); if !finished { persist() } }
    @objc func backgroundSave() { if !finished { persist() } }
    @objc func keyboardChanged(_ note: Notification) {
        guard let frame = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let local = view.convert(frame,from: nil)
        let overlap = max(0,view.bounds.maxY-local.minY-view.safeAreaInsets.bottom)
        scroll.contentInset.bottom = overlap; scroll.verticalScrollIndicatorInsets.bottom = overlap
        if caption.isFirstResponder { scroll.scrollRectToVisible(caption.convert(caption.bounds,to: scroll).insetBy(dx: 0,dy: -18),animated: true) }
    }
    @objc func endTyping() { view.endEditing(true) }
    func renderSlots() {
        slots.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for i in 0..<creation.task.photoCount {
            let has = creation.photos[i] != nil
            let head = label(String(format: "%02d", i+1) + "  " + creation.task.steps[i] + (has ? "  ✓" : ""),16,.semibold,has ? Palette.teal : Palette.ink)
            let content = stack([head,label(creation.task.hints[i],12,.regular,Palette.secondary)],spacing: 10)
            if has {
                let photo = photoView(height: 190); loadPhoto(creation.photos[i],into: photo,cropped: creation.crops[i],region: creation.cropRegions?[i]); content.addArrangedSubview(photo)
                let actions = stack(axis: .horizontal,spacing: 6); actions.distribution = .fillEqually
                let replace = button("替换",icon: "arrow.triangle.2.circlepath") { [weak self] in self?.source(i) }
                let crop = button("裁切",icon: "crop") { [weak self] in self?.crop(i) }
                [replace,crop].forEach { $0.titleLabel?.font = .systemFont(ofSize: 12,weight: .medium); actions.addArrangedSubview($0) }
                content.addArrangedSubview(actions)
                if creation.photos.count > 1 { content.addArrangedSubview(button("调整照片顺序",icon: "arrow.up.arrow.down") { [weak self] in self?.reorder(i) }) }
            } else {
                let add = button("添加第 \(i+1) 张照片",icon: "plus") { [weak self] in self?.source(i) }; add.accessibilityIdentifier = "add-photo-\(i)"; add.backgroundColor = UIColor(hex: 0xECEFE8); content.addArrangedSubview(add)
            }
            slots.addArrangedSubview(card(content))
        }
    }
    func crop(_ index: Int) {
        guard let name = creation.photos[index] else { return }
        sheet("照片裁切",options: [("调整方形裁切",{ [weak self] in
            MediaStore.queue.async {
                let image = MediaStore.image(name,maxSize: 2400)
                DispatchQueue.main.async {
                    guard let self = self,let image = image else { self?.notify("照片无法读取","请重新导入这张照片。"); return }
                    let crop = CropController(image: image,region: self.creation.cropRegions?[index])
                    crop.onSave = { [weak self] region in self?.creation.cropRegions?[index] = region; self?.creation.crops[index] = false; self?.persist(); self?.renderSlots() }
                    self.push(crop)
                }
            }
        }),("还原完整照片",{ [weak self] in self?.creation.cropRegions?[index] = nil; self?.creation.crops[index] = false; self?.persist(); self?.renderSlots() })])
    }
    func reorder(_ i: Int) {
        sheet("与哪张照片交换？", options: (0..<creation.photos.count).filter { $0 != i }.map { j in ("第 \(j+1) 张 · \(creation.task.steps[j])",{ [weak self] in
            guard let self = self else { return }; self.creation.photos.swapAt(i,j); self.creation.crops.swapAt(i,j); self.creation.cropRegions?.swapAt(i,j); self.persist(); self.renderSlots()
        }) })
    }
    func source(_ i: Int) {
        guard !busy else { return }; selectedSlot = i
        sheet("添加照片",options: [("拍摄照片",{ [weak self] in self?.camera() }),("从照片图库导入",{ [weak self] in self?.importPhoto() })])
    }
    func importPhoto() {
        var configuration = PHPickerConfiguration(); configuration.filter = .images; configuration.selectionLimit = 1
        let picker = PHPickerViewController(configuration: configuration); picker.delegate = self; present(picker,animated: true)
    }
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider else { return }
        guard provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) else { notify("无法导入这张照片","请选择另一张静态图片。原有照片仍保留。"); return }
        busy = true; status.text = "正在导入照片…"
        provider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { [weak self] url,error in
            // Read inside the provider callback: its temporary file expires on return.
            do {
                guard let url = url else { throw error ?? CocoaError(.fileReadUnknown) }
                let image = try MediaStore.importPreview(at: url)
                DispatchQueue.main.async { self?.receive(image) }
            } catch {
                DispatchQueue.main.async { self?.busy = false; self?.notify("导入失败", "请确认照片已下载到设备后重试。原有照片仍保留。"); self?.status.text = "导入失败，原有内容仍保留" }
            }
        }
    }

    func camera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else { notify("当前设备无法拍摄","你仍可以从照片图库导入，完成这次创作。"); return }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: openCamera()
        case .notDetermined: AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in DispatchQueue.main.async { if granted { self?.openCamera() } else { self?.denied() } } }
        default: denied()
        }
    }
    func denied() {
        let a = UIAlertController(title: "相机权限未开启",message: "可继续导入照片，或前往系统设置开启相机权限。",preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "导入照片",style: .default) { [weak self] _ in self?.importPhoto() }); a.addAction(UIAlertAction(title: "系统设置",style: .default) { _ in if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) } }); a.addAction(UIAlertAction(title: "取消",style: .cancel)); present(a,animated: true)
    }
    func openCamera() { let camera = CameraController(); camera.onPhoto = { [weak self] image in self?.receive(image) }; camera.modalPresentationStyle = .fullScreen; present(camera,animated: true) }
    func receive(_ image: UIImage) {
        busy = true; status.text = "正在保存照片…"; let slot = selectedSlot
        MediaStore.importImage(image) { [weak self] result in DispatchQueue.main.async {
            guard let self = self else { return }; self.busy = false
            switch result {
            case .success(let name):
                let previous = self.creation; self.creation.photos[slot] = name; self.creation.crops[slot] = false; self.creation.cropRegions?[slot] = nil
                if self.persist() { self.renderSlots() } else { self.creation = previous; MediaStore.queue.async { try? FileManager.default.removeItem(at: MediaStore.root.appendingPathComponent(name)) } }
            case .failure(let error): self.fail(error); self.status.text = "照片未保存，请重试"
            }
        } }
    }
    func textViewDidEndEditing(_ textView: UITextView) { creation.caption = String(textView.text.prefix(120)); persist() }
    func textViewDidChange(_ textView: UITextView) { creation.caption = String(textView.text.prefix(120)); saveWork?.cancel(); let work = DispatchWorkItem { [weak self] in self?.persist() }; saveWork = work; DispatchQueue.main.asyncAfter(deadline: .now()+0.5,execute: work) }
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool { (textView.text as NSString).replacingCharacters(in: range,with: text).count <= 120 }
    @discardableResult func persist() -> Bool {
        guard !finished else { return true }; saveWork?.cancel(); creation.caption = String(caption.text?.prefix(120) ?? ""); creation.updatedAt = Date()
        do { try AppStore.shared.save(creation); status.text = "草稿已保存 · \(creation.photos.compactMap { $0 }.count)/\(creation.task.photoCount) 张照片"; return true }
        catch { status.text = "草稿未保存，请重试"; if presentedViewController == nil { fail(error) }; return false }
    }
    @objc func preview() { guard !busy else { notify("照片仍在处理中", "稍等片刻后再预览。"); return }; view.endEditing(true); guard persist() else { return }; guard creation.photos.allSatisfy({ $0 != nil }) else { notify("还差一点","请先为每个步骤添加照片，再预览完整作品。"); return }; ExportCoordinator.preview(creation,from: self) }
    func complete() {
        guard !busy else { notify("照片仍在处理中","稍等片刻后再保存。"); return }
        view.endEditing(true)
        guard creation.photos.allSatisfy({ $0 != nil }) else { notify("还差几张照片","为每个步骤添加照片后，就可以保存作品。当前进度已保留为草稿。"); return }
        busy = true
        let files = creation.photos.compactMap { $0 }
        MediaStore.queue.async {
            let available = files.allSatisfy { FileManager.default.fileExists(atPath: MediaStore.root.appendingPathComponent($0).path) }
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }; self.busy = false
                guard self.viewIfLoaded?.window != nil else { return }
                if available { self.confirmCompletion() } else { self.notify("部分照片无法读取","请重新导入缺失照片后保存。草稿与文字仍已保留。") }
            }
        }
    }
    func confirmCompletion() {
        let alert = UIAlertController(title: "完成这次观察？",message: "由你确认照片与任务相符。保存后仍可编辑。",preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "再看看",style: .cancel)); alert.addAction(UIAlertAction(title: "保存作品",style: .default) { [weak self] _ in self?.finishSave() }); present(alert,animated: true)
    }
    func finishSave() {
        var artwork = creation; artwork.completed = true; artwork.updatedAt = Date()
        let draftID = artwork.editingArtworkID == nil ? nil : artwork.id
        if let original = artwork.editingArtworkID { artwork.id = original; artwork.editingArtworkID = nil }
        do {
            try AppStore.shared.save(artwork,removing: draftID); finished = true; saveWork?.cancel()
            let detail = ArtworkController(creation: artwork); detail.hidesBottomBarWhenPushed = true
            if let nav = navigationController { if let root = nav.viewControllers.first { nav.setViewControllers([root,detail],animated: true) } }
        } catch { fail(error) }
    }
}

nonisolated final class CaptureService: NSObject, AVCapturePhotoCaptureDelegate, @unchecked Sendable {
    let session = AVCaptureSession()
    let queue = DispatchQueue(label: "app.turnscene.camera")
    let output = AVCapturePhotoOutput()
    var completion: (@Sendable (Result<UIImage,Error>) -> Void)?
    func start(completion: @escaping @Sendable (Error?) -> Void) {
        queue.async {
            do {
                if self.session.inputs.isEmpty {
                    self.session.beginConfiguration(); self.session.sessionPreset = .photo
                    guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera,for: .video,position: .back) else { self.session.commitConfiguration(); throw CocoaError(.featureUnsupported) }
                    let input = try AVCaptureDeviceInput(device: camera)
                    guard self.session.canAddInput(input),self.session.canAddOutput(self.output) else { self.session.commitConfiguration(); throw CocoaError(.featureUnsupported) }
                    self.session.addInput(input); self.session.addOutput(self.output); self.session.commitConfiguration()
                }
                self.session.startRunning(); completion(nil)
            } catch { completion(error) }
        }
    }
    func stop() { queue.async { self.session.stopRunning() } }
    func capture(completion: @escaping @Sendable (Result<UIImage,Error>) -> Void) {
        queue.async { guard self.session.isRunning, self.output.connection(with: .video)?.isEnabled == true, self.completion == nil else { completion(.failure(CocoaError(.featureUnsupported))); return }; self.completion = completion; if let connection = self.output.connection(with: .video), connection.isVideoOrientationSupported { connection.videoOrientation = .portrait }; self.output.capturePhoto(with: AVCapturePhotoSettings(),delegate: self) }
    }
    func photoOutput(_ output: AVCapturePhotoOutput,didFinishProcessingPhoto photo: AVCapturePhoto,error: Error?) {
        if let data = photo.fileDataRepresentation(),let image = UIImage(data: data),error == nil { completion?(.success(image)) } else { completion?(.failure(error ?? CocoaError(.fileReadUnknown))) }; completion = nil
    }
}
final class CameraController: UIViewController {
    let capture = CaptureService()
    var layer: AVCaptureVideoPreviewLayer!
    var onPhoto: ((UIImage) -> Void)?
    var shutter: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad(); view.backgroundColor = .black
        layer = AVCaptureVideoPreviewLayer(session: capture.session); layer.videoGravity = .resizeAspectFill; view.layer.addSublayer(layer)
        let cancel = button("取消") { [weak self] in self?.dismiss(animated: true) }
        shutter = button("拍摄",icon: "camera",filled: true) { [weak self] in
            guard let self = self else { return }; self.shutter.isEnabled = false
            self.capture.capture { [weak self] result in DispatchQueue.main.async { guard let self = self else { return }; self.shutter.isEnabled = true
                switch result { case .success(let image): self.dismiss(animated: true) { self.onPhoto?(image) }; case .failure(let error): self.fail(error) }
            } }
        }
        let controls = stack([cancel,shutter],axis: .horizontal,spacing: 24); controls.distribution = .fillEqually; view.addSubview(controls); controls.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([controls.leadingAnchor.constraint(equalTo: view.leadingAnchor,constant: 24),controls.trailingAnchor.constraint(equalTo: view.trailingAnchor,constant: -24),controls.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor,constant: -24)])
        shutter.isEnabled = false
        capture.start { [weak self] error in DispatchQueue.main.async { if let error = error { self?.fail(error) } else { self?.shutter.isEnabled = true } } }
    }
    override func viewDidLayoutSubviews() { super.viewDidLayoutSubviews(); layer.frame = view.bounds; if layer.connection?.isVideoOrientationSupported == true { layer.connection?.videoOrientation = .portrait } }
    override func viewDidDisappear(_ animated: Bool) { super.viewDidDisappear(animated); capture.stop() }
}
