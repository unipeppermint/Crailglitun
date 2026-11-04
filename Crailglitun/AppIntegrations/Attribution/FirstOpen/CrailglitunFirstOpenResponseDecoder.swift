import Foundation

nonisolated enum FirstOpenAttributionError: LocalizedError {
    case invalidResponse
    case httpStatus(Int)
    case api(code: Int, message: String)
    case missingData
    case emptyResponse
    case decoding(path: String, reason: String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "The attribution server returned an invalid response."
        case let .httpStatus(statusCode):
            return "The attribution server returned HTTP status \(statusCode)."
        case let .api(code, message):
            return "The attribution server returned error \(code): \(message)"
        case .missingData:
            return "The attribution server response did not contain attribution data."
        case .emptyResponse:
            return "The attribution server returned HTTP 200 with an empty response body."
        case let .decoding(path, reason):
            return "Response decoding failed at \(path): \(reason)"
        }
    }
}

/// Decodes the existing API contract independently of the URLSession transport.
nonisolated enum CrailglitunFirstOpenResponseDecoder {
    static func decode(
        data: Data?,
        response: URLResponse?,
        error: Error?,
        using decoder: JSONDecoder
    ) throws -> FirstOpenAttribution {
        if let error {
            throw error
        }
        if let httpResponse = response as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            throw FirstOpenAttributionError.httpStatus(httpResponse.statusCode)
        }
        guard let data else {
            throw FirstOpenAttributionError.invalidResponse
        }
        guard !data.isEmpty else {
            throw FirstOpenAttributionError.emptyResponse
        }

        do {
            let apiResponse = try decoder.decode(
                APIResponse<FirstOpenAttribution>.self,
                from: data
            )
            guard apiResponse.code == 0 else {
                throw FirstOpenAttributionError.api(
                    code: apiResponse.code,
                    message: apiResponse.message
                )
            }
            guard let attribution = apiResponse.data else {
                throw FirstOpenAttributionError.missingData
            }
            return attribution
        } catch {
            throw detailedDecodingError(from: error)
        }
    }

    static func formattedJSON(from data: Data) -> String {
        guard
            let object = try? JSONSerialization.jsonObject(with: data),
            let formattedData = try? JSONSerialization.data(
                withJSONObject: object,
                options: [.prettyPrinted, .sortedKeys]
            )
        else {
            return String(decoding: data, as: UTF8.self)
        }
        return String(decoding: formattedData, as: UTF8.self)
    }

    private static func detailedDecodingError(from error: Error) -> Error {
        let context: DecodingError.Context
        switch error {
        case let DecodingError.typeMismatch(_, value):
            context = value
        case let DecodingError.valueNotFound(_, value):
            context = value
        case let DecodingError.keyNotFound(_, value):
            context = value
        case let DecodingError.dataCorrupted(value):
            context = value
        default:
            return error
        }

        let path = context.codingPath
            .map { $0.stringValue }
            .joined(separator: ".")
        return FirstOpenAttributionError.decoding(
            path: path.isEmpty ? "<root>" : path,
            reason: context.debugDescription
        )
    }
}
