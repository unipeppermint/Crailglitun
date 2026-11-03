import Foundation

nonisolated enum FirstOpenNetworkEvent: Sendable {
    case request(body: String)
    case response(statusCode: Int?, body: String)
}

@MainActor
protocol FirstOpenAttributionClientProtocol: AnyObject {
    func reportFirstOpen(
        request: FirstOpenAttributionRequest,
        eventHandler: @escaping @MainActor (FirstOpenNetworkEvent) -> Void,
        completion: @escaping @MainActor (Result<FirstOpenAttribution, Error>) -> Void
    )
}

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

@MainActor
final class FirstOpenAttributionClient: FirstOpenAttributionClientProtocol {
    private let endpoint: URL
    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        endpoint: URL = AttributionConfiguration.firstOpenEndpoint,
        session: URLSession = .shared,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.endpoint = endpoint
        self.session = session
        self.encoder = encoder
        self.decoder = decoder
    }

    func reportFirstOpen(
        request: FirstOpenAttributionRequest,
        eventHandler: @escaping @MainActor (FirstOpenNetworkEvent) -> Void,
        completion: @escaping @MainActor (Result<FirstOpenAttribution, Error>) -> Void
    ) {
        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            urlRequest.httpBody = try encoder.encode(request)
#if DEBUG
            if let body = urlRequest.httpBody {
                eventHandler(.request(body: Self.formattedJSON(from: body)))
            }
#endif
        } catch {
            completion(.failure(error))
            return
        }

        session.dataTask(with: urlRequest) { [decoder] data, response, error in
            let result: Result<FirstOpenAttribution, Error>
#if DEBUG
            let statusCode = (response as? HTTPURLResponse)?.statusCode
            let responseBody = data.flatMap { data in
                data.isEmpty ? nil : Self.formattedJSON(from: data)
            } ?? "No response body"
#endif

            if let error {
                result = .failure(error)
            } else if let httpResponse = response as? HTTPURLResponse,
                      !(200...299).contains(httpResponse.statusCode) {
                result = .failure(FirstOpenAttributionError.httpStatus(httpResponse.statusCode))
            } else if let data, !data.isEmpty {
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
                    result = .success(attribution)
                } catch {
                    result = .failure(Self.detailedDecodingError(from: error))
                }
            } else if data?.isEmpty == true {
                result = .failure(FirstOpenAttributionError.emptyResponse)
            } else {
                result = .failure(FirstOpenAttributionError.invalidResponse)
            }

            DispatchQueue.main.async {
#if DEBUG
                eventHandler(
                    .response(
                        statusCode: statusCode,
                        body: responseBody
                    )
                )
#endif
                completion(result)
            }
        }.resume()
    }

    nonisolated private static func formattedJSON(from data: Data) -> String {
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

    nonisolated private static func detailedDecodingError(from error: Error) -> Error {
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
