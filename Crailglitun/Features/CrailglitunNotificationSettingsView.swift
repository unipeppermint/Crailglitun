import UIKit
import UserNotifications

final class CrailglitunNotificationSettingsView: UIView {
    private static let preferenceKey = "Crailglitun.nativeNotificationsEnabled"
    private let notificationSwitch = UISwitch()

    init() {
        super.init(frame: .zero)
        notificationSwitch.isOn = UserDefaults.standard.bool(forKey: Self.preferenceKey)
        notificationSwitch.onTintColor = Palette.teal
        notificationSwitch.accessibilityLabel = "Daily Recommendations"
        notificationSwitch.accessibilityIdentifier = "Crailglitun.pushNotificationsSwitch"
        notificationSwitch.addTarget(self, action: #selector(toggleNotifications), for: .valueChanged)
        notificationSwitch.setContentHuggingPriority(.required, for: .horizontal)
        notificationSwitch.setContentCompressionResistancePriority(.required, for: .horizontal)

        let row = stack([label("Daily Recommendations", 17), notificationSwitch], axis: .horizontal, spacing: 14)
        row.alignment = .center
        let contents = stack([
            label("Notifications", 14, .regular, Palette.secondary),
            card(row, inset: 18),
            label("Turn on to request permission. Manage notification delivery in iOS Settings.", 12, .regular, Palette.secondary)
        ], spacing: 12)
        addSubview(contents)
        contents.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contents.topAnchor.constraint(equalTo: topAnchor),
            contents.leadingAnchor.constraint(equalTo: leadingAnchor),
            contents.trailingAnchor.constraint(equalTo: trailingAnchor),
            contents.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func toggleNotifications() {
        guard notificationSwitch.isOn else {
            // Keep this UI preference separate from app-wide notification delivery.
            UserDefaults.standard.set(false, forKey: Self.preferenceKey)
            return
        }
        notificationSwitch.isEnabled = false

        Task { [weak self] in
            guard let self else { return }
            defer { notificationSwitch.isEnabled = true }

            // The shared service only asks while system authorization is undetermined.
            _ = await CrailglitunPushService.shared.requestNotificationAuthorizationIfNeeded()
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            let allowed = settings.authorizationStatus == .authorized
                || settings.authorizationStatus == .provisional
                || settings.authorizationStatus == .ephemeral
            UserDefaults.standard.set(allowed, forKey: Self.preferenceKey)
            notificationSwitch.setOn(allowed, animated: true)
        }
    }
}
