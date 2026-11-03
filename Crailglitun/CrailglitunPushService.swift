import FirebaseMessaging
import UIKit
import UserNotifications

@MainActor
final class CrailglitunPushService: NSObject {
    static let shared = CrailglitunPushService()
    static let tokenDidChange = Notification.Name("CrailglitunFCMTokenDidChange")

    private(set) var currentToken: String?
    var onOpenWebHome: (() -> Bool)?

    private let notificationCenter = UNUserNotificationCenter.current()
    private var isConfigured = false
    private var apnsRegistrationID: UUID?
    private var apnsToken: Data?
    private var isFetchingToken = false
    private var hasPendingNotificationOpen = false
    private var lastOpenedNotificationID: String?
    private var tokenRequests: [UUID: @MainActor (Result<String, Error>) -> Void] = [:]

    override init() {
        super.init()
    }

    func configure() {
        guard !isConfigured else { return }
        isConfigured = true

        notificationCenter.delegate = self
        Messaging.messaging().delegate = self
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )

        // APNs registration does not display the notification permission prompt.
        registerWithAPNsIfNeeded()
    }

    /// Shared by the native Settings switch and the web controller after ATT finishes.
    /// False means the application became inactive before it could ask.
    func requestNotificationAuthorizationIfNeeded() async -> Bool {
        let settings = await notificationCenter.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else {
            registerWithAPNsIfNeeded()
            return true
        }
        guard UIApplication.shared.applicationState == .active else { return false }

        do {
            _ = try await notificationCenter.requestAuthorization(
                options: [.alert, .sound, .badge]
            )
        } catch {
            logFailure("Notification authorization", error: error)
        }

        // A denied display permission does not prevent obtaining an APNs token.
        registerWithAPNsIfNeeded()
        return true
    }

    func didRegisterWithAPNs(deviceToken: Data) {
        apnsRegistrationID = nil
        if apnsToken != deviceToken {
            currentToken = nil
        }
        apnsToken = deviceToken
        Messaging.messaging().apnsToken = deviceToken
        requestFCMTokenIfNeeded()
    }

    func didFailToRegisterWithAPNs(error: Error) {
        apnsRegistrationID = nil
        logFailure("APNs registration", error: error)
        finishTokenRequests(.failure(error))
    }

    func fetchMessagingToken(
        completion: @escaping @MainActor (Result<String, Error>) -> Void
    ) {
        if let currentToken {
            completion(.success(currentToken))
            return
        }

        let requestID = UUID()
        tokenRequests[requestID] = completion
        registerWithAPNsIfNeeded()
        requestFCMTokenIfNeeded()

        // APNs may not call back while offline. Always resolve the H5 request.
        DispatchQueue.main.asyncAfter(deadline: .now() + 20) { [weak self] in
            guard let self,
                  let completion = self.tokenRequests.removeValue(forKey: requestID) else {
                return
            }
            completion(.failure(FirebasePlatformServiceError.messagingToken(
                "Push registration timed out. Please try again."
            )))
        }
    }

    func handleNotificationResponse(_ response: UNNotificationResponse) {
        guard response.actionIdentifier == UNNotificationDefaultActionIdentifier else { return }
        openNotification(identifier: Self.notificationIdentifier(response.notification))
    }

    func openPendingNotificationIfPossible() {
        guard hasPendingNotificationOpen, let onOpenWebHome else { return }

        // Clear before navigation, which can synchronously trigger viewDidAppear.
        hasPendingNotificationOpen = false
        if !onOpenWebHome() {
            hasPendingNotificationOpen = true
        }
    }

    func openNotification(identifier: String) {
        guard lastOpenedNotificationID != identifier else { return }
        lastOpenedNotificationID = identifier
        hasPendingNotificationOpen = true

        if #available(iOS 16.0, *) {
            notificationCenter.setBadgeCount(0) { _ in }
        } else {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
        openPendingNotificationIfPossible()
    }

    @objc
    private func applicationDidBecomeActive() {
        registerWithAPNsIfNeeded()
        requestFCMTokenIfNeeded()
        openPendingNotificationIfPossible()
    }

    private func registerWithAPNsIfNeeded() {
        guard apnsRegistrationID == nil, Messaging.messaging().apnsToken == nil else { return }
        let requestID = UUID()
        apnsRegistrationID = requestID
        UIApplication.shared.registerForRemoteNotifications()

        DispatchQueue.main.asyncAfter(deadline: .now() + 20) { [weak self] in
            guard let self, self.apnsRegistrationID == requestID else { return }
            self.apnsRegistrationID = nil
            self.finishTokenRequests(.failure(FirebasePlatformServiceError.messagingToken(
                "APNs registration timed out. Please try again."
            )))
        }
    }

    private func requestFCMTokenIfNeeded() {
        guard Messaging.messaging().apnsToken != nil,
              currentToken == nil,
              !isFetchingToken else { return }
        isFetchingToken = true

        // H5 expects an FCM token. The new register API returns a different FID.
        Messaging.messaging().token { [weak self] token, error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isFetchingToken = false

                if let token, !token.isEmpty {
                    self.updateToken(token)
                } else {
                    let failure = FirebasePlatformServiceError.messagingToken(
                        error?.localizedDescription ?? "No token was returned."
                    )
                    self.logFailure("FCM registration", error: failure)
                    self.finishTokenRequests(.failure(failure))
                }
            }
        }
    }

    private func updateToken(_ token: String?) {
        guard let token, !token.isEmpty else {
            currentToken = nil
            return
        }

        let didChange = currentToken != token
        currentToken = token
        finishTokenRequests(.success(token))
        if didChange {
            NotificationCenter.default.post(name: Self.tokenDidChange, object: self)
        }
    }

    private func finishTokenRequests(_ result: Result<String, Error>) {
        let completions = Array(tokenRequests.values)
        tokenRequests.removeAll()
        completions.forEach { $0(result) }
    }

    private func logFailure(_ operation: String, error: Error) {
        #if DEBUG
        print("[Push] \(operation) failed: \(error.localizedDescription)")
        #endif
    }

    private nonisolated static func notificationIdentifier(_ notification: UNNotification) -> String {
        if let messageID = notification.request.content.userInfo["gcm.message_id"] as? String {
            return messageID
        }
        return "\(notification.request.identifier):\(notification.date.timeIntervalSince1970)"
    }
}

extension CrailglitunPushService: MessagingDelegate {
    nonisolated func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        Task { @MainActor in
            self.updateToken(fcmToken)
        }
    }
}

extension CrailglitunPushService: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound, .badge]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard response.actionIdentifier == UNNotificationDefaultActionIdentifier else { return }
        let identifier = Self.notificationIdentifier(response.notification)
        await MainActor.run {
            self.openNotification(identifier: identifier)
        }
    }
}
