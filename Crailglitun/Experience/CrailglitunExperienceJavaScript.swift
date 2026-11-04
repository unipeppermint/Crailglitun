import Foundation

nonisolated enum CrailglitunExperienceJavaScript {
    static func callbackScript(named callback: String, value: String) -> String? {
        guard isValidCallbackName(callback),
              let callbackJSON = jsonString(callback),
              let valueJSON = jsonString(value) else {
            return nil
        }

        return """
        (function () {
            var callback = window[\(callbackJSON)];
            if (typeof callback !== "function") {
                return false;
            }
            callback(\(valueJSON));
            return true;
        })();
        """
    }

    static func callbackName(from body: Any) -> String? {
        let callback: String?
        if let payload = body as? [String: Any] {
            callback = payload["callback"] as? String
        } else {
            callback = body as? String
        }
        guard let callback, isValidCallbackName(callback) else { return nil }
        return callback
    }

    static func isValidCallbackName(_ callback: String) -> Bool {
        guard !callback.isEmpty else { return false }
        let allowedCharacters = CharacterSet.alphanumerics.union(
            CharacterSet(charactersIn: "_$")
        )
        return callback.unicodeScalars.allSatisfy(allowedCharacters.contains)
    }

    static func jsonString(_ value: String) -> String? {
        guard let data = try? JSONSerialization.data(
            withJSONObject: value,
            options: [.fragmentsAllowed]
        ) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
}
