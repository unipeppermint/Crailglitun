import Foundation

nonisolated enum CrailglitunExperienceURLResolver {
    static func externalURL(from body: Any) -> URL? {
        if let value = body as? String {
            return normalizedExternalURL(from: value)
        }
        if let payload = body as? [String: Any] {
            return ["url", "href", "link", "target"]
                .compactMap { payload[$0] as? String }
                .compactMap(normalizedExternalURL)
                .first
        }
        return nil
    }

    private static func normalizedExternalURL(from rawValue: String) -> URL? {
        let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return nil }

        if let url = URL(string: value), isWebURL(url) {
            return url
        }
        if value.hasPrefix("//") {
            return URL(string: "https:\(value)").flatMap { isWebURL($0) ? $0 : nil }
        }
        if value.contains(".") {
            return URL(string: "https://\(value)").flatMap { isWebURL($0) ? $0 : nil }
        }
        return nil
    }

    private static func isWebURL(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased(), url.host?.isEmpty == false else {
            return false
        }
        return scheme == "http" || scheme == "https"
    }

    static func nativeIntentURL(from rawValue: String) -> URL? {
        let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty,
              let url = URL(string: value),
              let scheme = url.scheme?.lowercased(),
              !["about", "blob", "data", "file", "javascript"].contains(scheme)
        else {
            return nil
        }

        if scheme == "http" || scheme == "https" {
            guard url.host?.isEmpty == false else { return nil }
        }
        return url
    }
}
