import AuthenticationServices
import FirebaseAuth
import FirebaseStorage
import GoogleSignIn
import UIKit

final class CrailglitunCloudBackupController: PageController {
    private let account = CrailglitunCloudAccountService()
    private let appleSignIn = CrailglitunAppleSignInService()
    private let cloud = CrailglitunCloudBackupService()
    private let status = label("", 14, .regular, Palette.secondary)
    private var backups: [CrailglitunCloudBackup] = []
    private var loadedUID: String?
    private var busy = false
    private var canCancel = false
    private var operation: Task<Void, Never>?
    private var authObserver: AuthStateDidChangeListenerHandle?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Cloud Sync & Backup"
        authObserver = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            self.account.updateSession(for: user)
            if self.loadedUID != self.account.user?.uid {
                self.backups = []
                self.loadedUID = nil
            }
            if !self.busy { self.render() }
        }
        NotificationCenter.default.addObserver(
            self, selector: #selector(refreshAfterActivation),
            name: UIApplication.didBecomeActiveNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(refreshAfterActivation),
            name: ASAuthorizationAppleIDProvider.credentialRevokedNotification, object: nil
        )
        render()
        refreshAppleSession()
    }

    isolated deinit {
        if let authObserver { Auth.auth().removeStateDidChangeListener(authObserver) }
        NotificationCenter.default.removeObserver(self)
    }

    private func render() {
        clear()
        heading("Your work, backed up", subtitle: "Keep photos, work and editable drafts in your cloud account.")
        if appleSignIn.isSignedIn {
            body.addArrangedSubview(card(stack([
                label("Apple Account", 20, .semibold),
                label("Signed in with Apple", 14, .regular, Palette.secondary)
            ])))
        } else if let user = account.user {
            body.addArrangedSubview(card(stack([
                label(user.displayName ?? "Cloud account", 20, .semibold),
                label(user.email ?? "Signed in", 14, .regular, Palette.secondary)
            ])))
        }
        addAccountActions()

        if busy {
            let spinner = UIActivityIndicatorView(style: .medium)
            spinner.startAnimating()
            body.addArrangedSubview(card(stack([spinner, status])))
            if canCancel {
                body.addArrangedSubview(button("Cancel", icon: "xmark") { [weak self] in
                    self?.operation?.cancel()
                    self?.cloud.cancel()
                })
            }
            return
        }

        if appleSignIn.isSignedIn { return }

        guard let user = account.user else {
            body.addArrangedSubview(label("Sign in with Google to save a backup or restore your work on another device.", 16))
            let google = makeGoogleSignInButton()
            google.addAction(UIAction { [weak self] _ in self?.signInWithGoogle() }, for: .touchUpInside)
            let apple = ASAuthorizationAppleIDButton(type: .signIn, style: .black)
            apple.cornerRadius = 12
            apple.heightAnchor.constraint(equalToConstant: 50).isActive = true
            apple.addAction(UIAction { [weak self] _ in self?.signInWithApple() }, for: .touchUpInside)
            body.addArrangedSubview(google)
            body.addArrangedSubview(apple)
            body.addArrangedSubview(label("Cloud backups use your Google account. Apple sign-in confirms your identity on this device.", 13, .regular, Palette.secondary))
            return
        }

        body.addArrangedSubview(button("Back Up Now", icon: "icloud.and.arrow.up", filled: true) { [weak self] in
            self?.backUp()
        })
        body.addArrangedSubview(label("Creates a new cloud snapshot of your photos, captions, crops, layouts and drafts. Upload starts only when you tap Back Up Now. Keep TurnScene open until it finishes.", 13, .regular, Palette.secondary))
        body.addArrangedSubview(button("Refresh Backups", icon: "arrow.clockwise") { [weak self] in self?.refresh() })
        body.addArrangedSubview(label("Your Cloud Backups", 21, .semibold))
        if backups.isEmpty {
            body.addArrangedSubview(label(loadedUID == user.uid ? "No cloud backups yet." : "Refresh to load your cloud backups.", 14, .regular, Palette.secondary))
        }
        for backup in backups {
            let date = backup.createdAt.map {
                DateFormatter.localizedString(from: $0, dateStyle: .medium, timeStyle: .short)
            } ?? "Incomplete upload"
            let contents = stack([label(date, 17, .semibold)])
            if backup.isComplete {
                contents.addArrangedSubview(label("\(backup.workCount) works · \(backup.draftCount) drafts", 14, .regular, Palette.secondary))
                contents.addArrangedSubview(button("Restore", icon: "icloud.and.arrow.down") { [weak self] in
                    self?.confirmRestore(backup)
                })
            } else {
                contents.addArrangedSubview(label("This upload did not finish and cannot be restored. You can delete it and create a new backup.", 13, .regular, Palette.secondary))
            }
            contents.addArrangedSubview(button("Delete Backup", icon: "trash") { [weak self] in
                self?.confirmDelete(backup)
            })
            body.addArrangedSubview(card(contents))
        }
        body.addArrangedSubview(label("Restoring adds new copies and keeps existing work. Changes do not sync automatically. Sign-out keeps cloud backups; deleting local work does not delete cloud copies.", 13, .regular, Palette.secondary))
    }

    private func addAccountActions() {
        let signOut = button("Sign Out", icon: "rectangle.portrait.and.arrow.right") { [weak self] in
            self?.signOut()
        }
        let delete = button("Delete Account & Cloud Data", icon: "person.crop.circle.badge.minus") { [weak self] in
            self?.confirmDeleteAccount()
        }
        delete.setTitleColor(.systemRed, for: .normal)
        signOut.accessibilityIdentifier = "Crailglitun.signOutButton"
        delete.accessibilityIdentifier = "Crailglitun.deleteAccountButton"
        let enabled = !busy && (appleSignIn.isSignedIn || account.user != nil)
        for action in [signOut, delete] {
            action.isEnabled = enabled
            action.alpha = enabled ? 1 : 0.45
            body.addArrangedSubview(action)
        }
    }

    private func signOut() {
        guard !busy else { return }
        do {
            if appleSignIn.isSignedIn {
                appleSignIn.signOut()
            } else {
                try account.signOut()
            }
            backups = []
            loadedUID = nil
            render()
        } catch {
            showError(error)
        }
    }

    private func makeGoogleSignInButton() -> UIButton {
        var configuration = UIButton.Configuration.plain()
        configuration.title = "Sign in with Google"
        configuration.baseForegroundColor = UIColor(hex: 0x1F1F1F)
        // Original logo: https://developers.google.com/static/identity/images/g-logo.png
        if let logo = UIImage(named: "CrailglitunGoogleSignIn")?.cgImage {
            configuration.image = UIImage(cgImage: logo, scale: CGFloat(logo.height) / 18, orientation: .up)
                .withRenderingMode(.alwaysOriginal)
        }
        configuration.imagePadding = 12
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            attributes.font = UIFont.systemFont(ofSize: 19, weight: .medium)
            return attributes
        }
        configuration.cornerStyle = .fixed
        configuration.background.cornerRadius = 12
        configuration.background.backgroundColor = .white
        configuration.background.strokeColor = UIColor(hex: 0x747775)
        configuration.background.strokeWidth = 1

        let button = UIButton(configuration: configuration)
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        button.accessibilityIdentifier = "Crailglitun.googleSignInButton"
        button.accessibilityLabel = "Sign in with Google"
        button.configurationUpdateHandler = { button in
            button.configuration?.background.backgroundColor = button.isHighlighted
                ? UIColor(hex: 0xF2F2F2) : .white
            button.configuration?.background.strokeColor = button.isHighlighted
                ? UIColor(hex: 0x4285F4) : UIColor(hex: 0x747775)
        }
        return button
    }

    private func runCloudTask(
        _ message: String,
        canCancel: Bool = true,
        destructive: Bool = false,
        completionTitle: String = "Cloud Backup",
        action: @escaping () async throws -> String?
    ) {
        guard !busy else { return }
        busy = true
        self.canCancel = canCancel
        status.text = message
        navigationItem.leftBarButtonItem?.isEnabled = false
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        render()
        operation = Task {
            var completion: String?
            var failure: Error?
            do { completion = try await action() }
            catch { failure = error }
            busy = false
            operation = nil
            navigationItem.leftBarButtonItem?.isEnabled = true
            navigationController?.interactivePopGestureRecognizer?.isEnabled = true
            render()
            if let failure { showError(failure, destructive: destructive) }
            else if let completion { notify(completionTitle, completion) }
        }
    }

    private func signInWithGoogle() {
        runCloudTask("Signing in…", canCancel: false) { [self] in
            try await account.signInWithGoogle(presenting: self)
            appleSignIn.signOut()
            return nil
        }
    }

    private func signInWithApple() {
        runCloudTask("Signing in with Apple…", canCancel: false, completionTitle: "Backup Successful") { [self] in
            try await appleSignIn.signIn(presenting: self)
            return "Backup completed successfully."
        }
    }

    @objc private func refreshAfterActivation() {
        guard viewIfLoaded?.window != nil, !busy else { return }
        refreshAppleSession()
    }

    private func refreshAppleSession() {
        guard appleSignIn.isSignedIn else { return }
        Task { [weak self] in
            guard let self else { return }
            await self.appleSignIn.refreshSession()
            if !self.busy { self.render() }
        }
    }

    private func refresh() {
        guard let uid = account.user?.uid else { return }
        runCloudTask("Loading cloud backups…") { [self] in
            try await account.refreshSession()
            try await loadBackups(uid: uid)
            return nil
        }
    }

    private func loadBackups(uid: String) async throws {
        let result = try await cloud.list(uid: uid)
        try cloud.checkAccount(uid)
        backups = result
        loadedUID = uid
    }

    private func backUp() {
        guard let uid = account.user?.uid else { return }
        if let error = AppStore.shared.startupError { showError(error); return }
        let creations = AppStore.shared.creations
        guard !creations.isEmpty else { showError(CrailglitunBackupError.empty); return }
        runCloudTask("Preparing your backup…") { [self] in
            let prepared = try await withCheckedThrowingContinuation { continuation in
                MediaStore.queue.async {
                    continuation.resume(with: Result {
                        try CrailglitunBackupArchive.create(creations: creations, mediaRoot: MediaStore.root)
                    })
                }
            }
            defer { MediaStore.queue.async { CrailglitunBackupArchive.remove(prepared.url) } }
            try cloud.checkAccount(uid)
            try await cloud.upload(prepared, uid: uid) { [weak self] in self?.status.text = $0 }
            // Upload is committed. A subsequent list failure must not turn success into a false failure.
            do {
                try await loadBackups(uid: uid)
                return "Your backup is saved in the cloud. Sign in with this account on another device to restore it."
            } catch {
                return "Your backup is saved in the cloud. Refresh the list to see it."
            }
        }
    }

    private func confirmRestore(_ backup: CrailglitunCloudBackup) {
        guard let uid = account.user?.uid else { return }
        confirm(
            title: "Restore this cloud backup?",
            message: "This downloads the backup and adds new copies of its work and drafts. Existing work stays unchanged. Restoring it again creates additional copies.",
            actionTitle: "Restore", destructive: false
        ) { [weak self] in
            guard let self else { return }
            self.runCloudTask("Downloading your backup…") {
                let prepared = try await self.cloud.download(id: backup.id, uid: uid) { [weak self] in self?.status.text = $0 }
                defer { MediaStore.queue.async { CrailglitunBackupArchive.remove(prepared.url) } }
                try self.cloud.checkAccount(uid)
                let restored = try await withCheckedThrowingContinuation { continuation in
                    MediaStore.queue.async {
                        continuation.resume(with: Result {
                            try CrailglitunBackupArchive.copyForRestore(prepared, mediaRoot: MediaStore.root)
                        })
                    }
                }
                do {
                    try self.cloud.checkAccount(uid)
                    try AppStore.shared.addRestoredCreations(restored)
                } catch {
                    MediaStore.queue.async {
                        Set(restored.flatMap { $0.photos.compactMap { $0 } }).forEach {
                            CrailglitunBackupArchive.remove(MediaStore.root.appendingPathComponent($0))
                        }
                    }
                    throw error
                }
                return "Added \(restored.count) items to Portfolio. Your existing work is unchanged."
            }
        }
    }

    private func confirmDelete(_ backup: CrailglitunCloudBackup) {
        guard let uid = account.user?.uid else { return }
        confirm(title: "Delete this cloud backup?", message: "This cannot be undone. Work saved on your device will remain.", actionTitle: "Delete", destructive: true) { [weak self] in
            guard let self else { return }
            self.runCloudTask("Deleting cloud backup…", canCancel: false, destructive: true) {
                try await self.cloud.delete(id: backup.id, uid: uid)
                self.backups.removeAll { $0.id == backup.id }
                return "Cloud backup deleted."
            }
        }
    }

    private func confirmDeleteAccount() {
        guard !busy else { return }
        if appleSignIn.isSignedIn {
            confirm(
                title: "Delete your account?",
                message: "This removes your Apple sign-in from this app. Local work stays on this device.",
                actionTitle: "Delete Account", destructive: true
            ) { [weak self] in
                guard let self else { return }
                self.appleSignIn.signOut()
                self.backups = []
                self.loadedUID = nil
                self.render()
            }
            return
        }
        guard let uid = account.user?.uid else { return }
        confirm(
            title: "Delete your account?",
            message: "Your TurnScene cloud account and all its backups will be deleted permanently. Online services that use this account will also lose access. Local work stays on this device. You will sign in again to confirm your identity.",
            actionTitle: "Delete Account", destructive: true
        ) { [weak self] in
            guard let self else { return }
            self.runCloudTask("Verifying account ownership…", canCancel: false, destructive: true) {
                try await self.account.reauthenticateForDeletion(presenting: self)
                try self.cloud.checkAccount(uid)
                self.status.text = "Deleting cloud data and account…"
                try await self.cloud.deleteAll(uid: uid)
                try await self.account.deleteAccount(uid: uid)
                self.backups = []
                self.loadedUID = nil
                return "Your account and cloud backups have been deleted. Local work remains on this device."
            }
        }
    }

    private func confirm(title: String, message: String, actionTitle: String, destructive: Bool, action: @escaping () -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: actionTitle, style: destructive ? .destructive : .default) { _ in action() })
        present(alert, animated: true)
    }

    private func showError(_ error: Error, destructive: Bool = false) {
        let nsError = error as NSError
        if error is CancellationError
            || (nsError.domain == ASAuthorizationError.errorDomain && nsError.code == ASAuthorizationError.canceled.rawValue)
            || (nsError.domain == kGIDSignInErrorDomain && nsError.code == -5)
            || (nsError.domain == StorageErrorDomain && nsError.code == StorageErrorCode.cancelled.rawValue) {
            return
        }
        NSLog("Cloud backup action failed: domain=%@, code=%ld", nsError.domain, nsError.code)
        let message = (error as? CrailglitunCloudError)?.errorDescription
            ?? (error as? CrailglitunAppleSignInError)?.errorDescription
            ?? (error as? CrailglitunBackupError)?.errorDescription
            ?? cloudServiceErrorMessage(nsError)
            ?? "The cloud service could not complete this action. Check your connection and try again. If this continues, contact support."
        let detail = destructive ? "\n\nSome cloud data may already have been deleted. Refresh and retry to finish. Local work remains on this device." : ""
        notify("Unable to complete this action", message + detail)
    }

    private func cloudServiceErrorMessage(_ error: NSError) -> String? {
        if error.domain == NSURLErrorDomain {
            return "Could not connect to the cloud service. Check your internet connection and try again."
        }
        guard error.domain == StorageErrorDomain else { return nil }
        switch StorageErrorCode(rawValue: error.code) {
        case .unauthenticated:
            return "Your cloud session has expired. Sign out and sign in again."
        case .unauthorized:
            return "This account does not have permission to access cloud backups. Please contact support."
        case .bucketNotFound, .projectNotFound:
            return "Cloud backup storage is not available. Please contact support."
        case .quotaExceeded:
            return "Cloud backup storage has reached its limit. Please try again later."
        case .retryLimitExceeded:
            return "The cloud request timed out. Check your internet connection and try again."
        case .objectNotFound:
            return "This backup is no longer available. Refresh the list and try again."
        default:
            return nil
        }
    }
}
