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
                eventHandler(
                    .request(body: CrailglitunFirstOpenResponseDecoder.formattedJSON(from: body))
                )
            }
#endif
        } catch {
            completion(.failure(error))
            return
        }

        session.dataTask(with: urlRequest) { [decoder] data, response, error in
#if DEBUG
            let statusCode = (response as? HTTPURLResponse)?.statusCode
            let responseBody = data.flatMap { data in
                data.isEmpty ? nil : CrailglitunFirstOpenResponseDecoder.formattedJSON(from: data)
            } ?? "No response body"
#endif

            let result = Result {
                try CrailglitunFirstOpenResponseDecoder.decode(
                    data: data,
                    response: response,
                    error: error,
                    using: decoder
                )
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
}
