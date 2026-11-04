import Foundation

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
