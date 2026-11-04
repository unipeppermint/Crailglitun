import Foundation

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
