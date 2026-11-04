import Foundation

nonisolated struct AppsFlyerAttributionPayload: Sendable {
    enum Source: Sendable {
        case conversionData
        case deepLink

        var logTitle: String {
            switch self {
            case .conversionData:
                return "AppsFlyer Conversion Data"
            case .deepLink:
                return "AppsFlyer Deep Link Data"
            }
        }
    }

    let source: Source
    let parameters: AttributionParameters
    let attributionData: [String: AttributionValue]
    let formattedData: String

    init(
        source: Source,
        attributionData: [AnyHashable: Any]
    ) {
        self.source = source
        parameters = AttributionParameters(conversionData: attributionData)
        self.attributionData = AttributionValue.filteredDictionary(
            from: attributionData
        )
#if DEBUG
        formattedData = AttributionPayloadFormatter.prettyJSONString(
            from: attributionData
        )
#else
        formattedData = ""
#endif
    }
}

nonisolated struct AttributionParameters: Equatable, Sendable {
    let mediaSource: String?
    let campaign: String?
    let deepLinkValue: String?

    init(conversionData: [AnyHashable: Any]) {
        mediaSource = Self.stringValue(for: "media_source", in: conversionData)
        campaign = Self.stringValue(for: "campaign", in: conversionData)
        deepLinkValue = Self.stringValue(for: "deep_link_value", in: conversionData)
    }

    private static func stringValue(
        for key: String,
        in conversionData: [AnyHashable: Any]
    ) -> String? {
        guard let rawValue = conversionData[key] else { return nil }
        let value = String(describing: rawValue).trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty || value == "<null>" ? nil : value
    }
}

nonisolated private enum AttributionPayloadFormatter {
    nonisolated static func prettyJSONString(
        from values: [AnyHashable: Any]
    ) -> String {
        let normalizedValues = normalize(values)
        guard
            JSONSerialization.isValidJSONObject(normalizedValues),
            let data = try? JSONSerialization.data(
                withJSONObject: normalizedValues,
                options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
            ),
            let json = String(data: data, encoding: .utf8)
        else {
            return String(describing: values)
        }
        return json
    }

    nonisolated private static func normalize(_ value: Any) -> Any {
        switch value {
        case let dictionary as [AnyHashable: Any]:
            return Dictionary(
                uniqueKeysWithValues: dictionary.map {
                    (String(describing: $0.key), normalize($0.value))
                }
            )
        case let dictionary as NSDictionary:
            return Dictionary(
                uniqueKeysWithValues: dictionary.map {
                    (String(describing: $0.key), normalize($0.value))
                }
            )
        case let array as [Any]:
            return array.map { normalize($0) }
        case let set as NSSet:
            return set.allObjects.map { normalize($0) }
        case let url as URL:
            return url.absoluteString
        case let date as Date:
            return ISO8601DateFormatter().string(from: date)
        case let data as Data:
            return data.base64EncodedString()
        case is NSNull, is String, is NSNumber:
            return value
        default:
            return String(describing: value)
        }
    }
}
