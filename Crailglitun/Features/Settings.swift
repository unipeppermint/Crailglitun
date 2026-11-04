import UIKit

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
        let notificationSettings = CrailglitunNotificationSettingsView()
        body.addArrangedSubview(notificationSettings)
        body.setCustomSpacing(30, after: notificationSettings)
        body.addArrangedSubview(label("Work & Storage",14,.regular,Palette.secondary))
        let data = grouped([
            settingRow("Cloud Sync & Backup") { [weak self] in
                self?.push(CrailglitunCloudBackupController())
            },
            settingRow("Export Work") { [weak self] in
                self?.push(BatchExportController())
            },
            settingRow("Storage") { [weak self] in
                self?.push(StorageController())
            }
        ])
        body.addArrangedSubview(data)
        body.setCustomSpacing(30, after: data)
        body.addArrangedSubview(label("Help & About",14,.regular,Palette.secondary))
        body.addArrangedSubview(grouped(Self.documents.map { title,_,copy in
            settingRow(title) { [weak self] in
                if title == "Feedback" {
                    self?.push(CrailglitunFeedbackController())
                    return
                }
                let policyURL = title == "Privacy" ? URL(string: "https://tkzcpoj.netlify.app/turnscene/privacy-policy/") : nil
                self?.push(TextController(title: title,text: copy,link: policyURL))
            }
        }))
        if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
           !version.isEmpty {
            let footer = label("Version " + version, 12, .regular, Palette.secondary)
            footer.textAlignment = .center
            body.addArrangedSubview(footer)
        }
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
        ("Help", "questionmark.circle", """
        Choose a photo task

        Choose Indoors or Outdoors and a time limit, then tap Spin. These choices do not use your device location. Lock a choice to keep it or swipe a reel to choose manually. If nothing matches, allow more time or unlock a reel.

        Capture and edit

        Follow the steps to take or import photos. Use Crop to adjust a photo, then add a caption. Changes are saved as a draft in Portfolio.

        Save and share

        Save your finished work and export a JPG image to share it. Choose Try This Task Again to create another version. Exported images cannot restore editable drafts.

        Notifications

        Turn on Daily Recommendations in Settings to request notification permission if you have not decided yet. Manage delivery in iOS Settings.

        Online features

        An internet connection is needed for online pages and sign-in. The photography tools process and save your work on this device.

        Manage your sign-in

        Open Cloud Sync & Backup to sign in with Google or Apple. Tap Sign Out to return to the sign-in screen. To remove your sign-in or cloud account, choose Delete Account & Cloud Data and confirm. Work saved on your device remains available.

        Keep your work

        For cloud backups, sign in with Google and tap Back Up Now. Each backup saves your work, drafts, photos and editing details. Use the same Google account on another device to restore it. Restoring adds new copies and keeps your existing work. Changes do not sync automatically. Export Work saves JPG images rather than editable backups.

        Complete an important cloud backup before deleting the app. Deleting local work does not delete cloud backups. Manage backups and your cloud account in Cloud Sync & Backup.

        Feedback

        Settings > Feedback prepares an email for you to review and send. Your feedback is not sent until you send the email.
        """),
        ("Feedback", "bubble.left", "When reporting a problem, include your device model, iOS version and the steps to reproduce it."),
        ("Privacy", "hand.raised", """
        Photos and work

        The photography tools do not require an account. Photos, captions, drafts and work created with these tools are stored on your device without automatic upload. This does not cover information you provide on online pages.

        Account information

        Google cloud accounts use your account identifier and any name or email provided for sign-in and backup access. Apple sign-in information is stored on this device and cleared when you sign out or remove that sign-in.

        Cloud backups

        When you tap Back Up Now, your photos, work, drafts and editing details are uploaded to Firebase Cloud Storage under your cloud account. Uploads are manual; later changes do not sync automatically. Backups do not include notification tokens or device permissions. You can restore or delete individual backups in Cloud Sync & Backup. Delete Account & Cloud Data removes your cloud account and its backups after identity verification. Work already saved or restored on your device remains available.

        Camera and library

        Camera permission is requested when you choose to take a photo. You can import photos without it. The system photo picker provides only the images you select; editing local copies does not change your originals.

        Online services

        TurnScene uses AppsFlyer for installation and app-usage measurement, and Firebase for sign-in, cloud backups and notifications. Device and installation identifiers, usage information and technical details are processed by these services.

        Tracking choices

        TurnScene requests tracking permission when iOS allows it. You can review your choice in iOS Settings.

        Notifications

        Daily Recommendations requests notification permission. Turning it off does not stop existing notifications; manage delivery in iOS Settings.

        Export and share

        You choose what to export and where to share it. Exported JPGs do not include the original photos' GPS metadata, but visible photos and captions may contain personal information.

        Delete data and contact us

        Delete local work from its detail page, or manage drafts and photo cache in Storage. Clearing the photo cache keeps your work and does not clear website data. Deleting the app does not delete online accounts or information already held by online services.

        Feedback emails contain the contact address and message you choose to send. For privacy questions or requests about online information, contact cressidal@trademarkroofing.homes.
        """),
        ("About TurnScene", "sparkles", """
        A fresh look at the everyday.

        Explore 60 photography tasks across six themes. Capture what you discover, edit photos on your device and build your own collection.

        TurnScene also includes sign-in and notification services. Online features need an internet connection. See Privacy for information about these services and your choices.
        """)
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
            body.addArrangedSubview(button("View Full Privacy Policy", icon: "doc.text") { [weak self] in
                self?.push(CrailglitunPrivacyPolicyController(url: link))
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
        clear(); heading("Storage",subtitle: "Manage photos, drafts and work saved by the photography tools on this device.")
        body.addArrangedSubview(card(usage)); body.addArrangedSubview(button("Clear Photo Cache",icon: "arrow.triangle.2.circlepath") { [weak self] in
            MediaStore.queue.async {
                do { if FileManager.default.fileExists(atPath: MediaStore.cache.path) { try FileManager.default.removeItem(at: MediaStore.cache) }; DispatchQueue.main.async { self?.refresh(); self?.notify("Photo cache cleared","Your photos, drafts and work are preserved. Website data has not been cleared.") } }
                catch { DispatchQueue.main.async { self?.fail(error) } }
            }
        })
        body.addArrangedSubview(label("Clearing the photo cache keeps your photos, drafts and work. This page does not manage online accounts or website data.",13,.regular,Palette.secondary))
        body.addArrangedSubview(label("Drafts · \(AppStore.shared.drafts.count)",20,.semibold))
        for item in AppStore.shared.drafts {
            body.addArrangedSubview(button("Delete Draft · \(item.task.title)",icon: "trash") { [weak self] in
                guard let self = self else { return }; let alert = UIAlertController(title: "Delete this draft?",message: "This draft and any photos not used by other work will be deleted from this device. This cannot be undone.",preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Keep",style: .cancel)); alert.addAction(UIAlertAction(title: "Delete",style: .destructive) { _ in do { try AppStore.shared.delete(item); self.render(); self.refresh() } catch { self.fail(error) } }); self.present(alert,animated: true)
            })
        }
    }
    func refresh() {
        MediaStore.queue.async { let originals = MediaStore.usage(MediaStore.root); let caches = MediaStore.usage(MediaStore.cache); DispatchQueue.main.async { [weak self] in self?.usage.text = "Work & Photos  \(ByteCountFormatter.string(fromByteCount: originals,countStyle: .file))\n\nPhoto Cache  \(ByteCountFormatter.string(fromByteCount: caches,countStyle: .file))" } }
    }
}
