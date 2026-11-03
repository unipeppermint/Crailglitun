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

nonisolated enum AttributionValue: Encodable, Equatable, Sendable {
    case string(String)
    case boolean(Bool)
    case integer(Int64)
    case number(Double)
    case array([AttributionValue])
    case object([String: AttributionValue])

    nonisolated init?(rawValue: Any) {
        switch rawValue {
        case is NSNull:
            return nil
        case let value as String:
            guard Self.isMeaningful(value) else { return nil }
            self = .string(value)
        case let value as URL:
            self = .string(value.absoluteString)
        case let value as Date:
            self = .string(ISO8601DateFormatter().string(from: value))
        case let value as Data:
            guard !value.isEmpty else { return nil }
            self = .string(value.base64EncodedString())
        case let value as NSNumber:
            if CFGetTypeID(value) == CFBooleanGetTypeID() {
                self = .boolean(value.boolValue)
            } else if CFNumberIsFloatType(value) {
                let number = value.doubleValue
                guard number.isFinite else { return nil }
                self = .number(number)
            } else {
                self = .integer(value.int64Value)
            }
        case let values as [AnyHashable: Any]:
            let dictionary = Self.filteredDictionary(from: values)
            guard !dictionary.isEmpty else { return nil }
            self = .object(dictionary)
        case let values as NSDictionary:
            let dictionary = Self.filteredDictionary(from: values)
            guard !dictionary.isEmpty else { return nil }
            self = .object(dictionary)
        case let values as [Any]:
            let array = values.compactMap(Self.init(rawValue:))
            guard !array.isEmpty else { return nil }
            self = .array(array)
        case let values as NSSet:
            let array = values.allObjects.compactMap(Self.init(rawValue:))
            guard !array.isEmpty else { return nil }
            self = .array(array)
        default:
            let value = String(describing: rawValue)
            guard Self.isMeaningful(value) else { return nil }
            self = .string(value)
        }
    }

    nonisolated static func filteredDictionary(
        from values: [AnyHashable: Any]
    ) -> [String: AttributionValue] {
        var result: [String: AttributionValue] = [:]
        for (key, rawValue) in values {
            guard let value = AttributionValue(rawValue: rawValue) else {
                continue
            }
            result[String(describing: key)] = value
        }
        return result
    }

    nonisolated private static func filteredDictionary(
        from values: NSDictionary
    ) -> [String: AttributionValue] {
        var result: [String: AttributionValue] = [:]
        for (key, rawValue) in values {
            guard let value = AttributionValue(rawValue: rawValue) else {
                continue
            }
            result[String(describing: key)] = value
        }
        return result
    }

    nonisolated private static func isMeaningful(_ value: String) -> Bool {
        let normalizedValue = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        return !normalizedValue.isEmpty
            && normalizedValue != "null"
            && normalizedValue != "<null>"
            && normalizedValue != "nil"
    }

    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .string(value):
            try container.encode(value)
        case let .boolean(value):
            try container.encode(value)
        case let .integer(value):
            try container.encode(value)
        case let .number(value):
            try container.encode(value)
        case let .array(value):
            try container.encode(value)
        case let .object(value):
            try container.encode(value)
        }
    }
}

nonisolated struct FirstOpenAttributionRequest: Encodable, Sendable {
    let appInstanceId: String
    let attributionData: [String: AttributionValue]
    let ua: String?
    let appsflyerId: String?
    let deviceId: String?

    init(
        appInstanceId: String,
        attributionData: [String: AttributionValue],
        ua: String? = nil,
        appsflyerId: String? = nil,
        deviceId: String? = nil
    ) {
        self.appInstanceId = appInstanceId
        self.attributionData = attributionData
        self.ua = ua
        self.appsflyerId = appsflyerId
        self.deviceId = deviceId
    }

    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKey.self)
        try container.encode(
            appInstanceId,
            forKey: DynamicCodingKey("appInstanceId")
        )
        try container.encodeIfPresent(ua, forKey: DynamicCodingKey("ua"))
        try container.encodeIfPresent(
            appsflyerId,
            forKey: DynamicCodingKey("appsflyer_id")
        )
        try container.encodeIfPresent(
            deviceId,
            forKey: DynamicCodingKey("deviceId")
        )

        let reservedKeys = ["appInstanceId", "ua", "appsflyer_id", "deviceId"]
        for (key, value) in attributionData where !reservedKeys.contains(key) {
            try container.encode(value, forKey: DynamicCodingKey(key))
        }
    }

    private struct DynamicCodingKey: CodingKey {
        let stringValue: String
        let intValue: Int? = nil

        init(_ stringValue: String) {
            self.stringValue = stringValue
        }

        init?(stringValue: String) {
            self.init(stringValue)
        }

        init?(intValue: Int) {
            return nil
        }
    }
}

nonisolated struct FirstOpenAttribution: Decodable, Sendable {
    let appInstanceId: String?
    let clickId: String?
    let attributionToken: String?
    let appCode: String?
    let productUrl: URL?
    let organic: Bool?
    let attributionMethod: String?
    let attributionStatus: String?
    let clickConsumed: Bool?
    let idempotentReplay: Bool?
    let tenantId: Int64?
    let campaignCode: String?

    enum CodingKeys: String, CodingKey {
        case appInstanceId
        case clickId
        case attributionToken
        case appCode
        case productUrl
        case organic
        case attributionMethod
        case attributionStatus
        case clickConsumed
        case idempotentReplay
        case tenantId
        case campaignCode
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        appInstanceId = container.lossyString(forKey: .appInstanceId)
        clickId = container.lossyString(forKey: .clickId)
        attributionToken = container.lossyString(forKey: .attributionToken)
        appCode = container.lossyString(forKey: .appCode)
        attributionMethod = container.lossyString(forKey: .attributionMethod)
        attributionStatus = container.lossyString(forKey: .attributionStatus)
        campaignCode = container.lossyString(forKey: .campaignCode)

        let productURLString = container.lossyString(forKey: .productUrl)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        productUrl = productURLString
            .flatMap { $0.isEmpty ? nil : URL(string: $0) }

        organic = container.lossyBool(forKey: .organic)
        clickConsumed = container.lossyBool(forKey: .clickConsumed)
        idempotentReplay = container.lossyBool(forKey: .idempotentReplay)
        tenantId = container.lossyInt64(forKey: .tenantId)
    }
}

nonisolated struct APIResponse<DataType: Decodable>: Decodable {
    let code: Int
    let message: String
    let data: DataType?
    let requestId: String?

    enum CodingKeys: String, CodingKey {
        case code
        case message
        case data
        case requestId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard
            let rawCode = container.lossyInt64(forKey: .code),
            let code = Int(exactly: rawCode)
        else {
            throw DecodingError.dataCorruptedError(
                forKey: .code,
                in: container,
                debugDescription: "Expected an integer or numeric string."
            )
        }

        self.code = code
        message = container.lossyString(forKey: .message) ?? ""
        data = try container.decodeIfPresent(DataType.self, forKey: .data)
        requestId = container.lossyString(forKey: .requestId)
    }
}

extension APIResponse: Sendable where DataType: Sendable {}

nonisolated private extension KeyedDecodingContainer {
    func lossyString(forKey key: Key) -> String? {
        guard contains(key), (try? decodeNil(forKey: key)) == false else {
            return nil
        }
        if let value = try? decode(String.self, forKey: key) {
            return value
        }
        if let value = try? decode(Int64.self, forKey: key) {
            return String(value)
        }
        if let value = try? decode(Double.self, forKey: key) {
            return String(value)
        }
        if let value = try? decode(Bool.self, forKey: key) {
            return String(value)
        }
        return nil
    }

    func lossyBool(forKey key: Key) -> Bool? {
        guard contains(key), (try? decodeNil(forKey: key)) == false else {
            return nil
        }
        if let value = try? decode(Bool.self, forKey: key) {
            return value
        }
        if let value = try? decode(Int.self, forKey: key) {
            return value != 0
        }
        guard let value = try? decode(String.self, forKey: key) else {
            return nil
        }
        switch value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "true", "1", "yes":
            return true
        case "false", "0", "no":
            return false
        default:
            return nil
        }
    }

    func lossyInt64(forKey key: Key) -> Int64? {
        guard contains(key), (try? decodeNil(forKey: key)) == false else {
            return nil
        }
        if let value = try? decode(Int64.self, forKey: key) {
            return value
        }
        guard let value = try? decode(String.self, forKey: key) else {
            return nil
        }
        return Int64(value.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}
