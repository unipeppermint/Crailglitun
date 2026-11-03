import Foundation

@MainActor
final class AttributionStateStore {
    private enum Key {
        static let appInstanceID = "attribution.appInstanceID"
        static let didReportFirstOpen = "attribution.didReportFirstOpen"
        static let cachedProductURL = "attribution.cachedProductURL"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var appInstanceID: String {
        if let identifier = defaults.string(forKey: Key.appInstanceID) {
            return identifier
        }

        let identifier = "ai_\(UUID().uuidString.lowercased())"
        defaults.set(identifier, forKey: Key.appInstanceID)
        return identifier
    }

    var didReportFirstOpen: Bool {
        get { defaults.bool(forKey: Key.didReportFirstOpen) }
        set { defaults.set(newValue, forKey: Key.didReportFirstOpen) }
    }

    var cachedProductURL: URL? {
        get {
            guard let value = defaults.string(forKey: Key.cachedProductURL) else {
                return nil
            }
            return Self.validProductURL(from: value)
        }
        set {
            guard let newValue,
                  Self.validProductURL(from: newValue.absoluteString) != nil else {
                defaults.removeObject(forKey: Key.cachedProductURL)
                return
            }
            defaults.set(newValue.absoluteString, forKey: Key.cachedProductURL)
        }
    }

    private static func validProductURL(from value: String) -> URL? {
        guard let url = URL(string: value),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              url.host != nil else {
            return nil
        }
        return url
    }
}
