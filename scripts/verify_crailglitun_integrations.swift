import Foundation
import JavaScriptCore

@main
@MainActor
struct CrailglitunIntegrationChecks {
    private static var passed = 0

    static func main() async throws {
        try checkWebContract()
        try checkAttributionContract()
        try checkResponseContract()
        try await checkTransportContract()
        print("\(passed) integration compatibility checks passed.")
    }

    private static func check(_ condition: Bool, _ name: String) {
        guard condition else {
            fatalError("FAIL: \(name)")
        }
        passed += 1
        print("PASS: \(name)")
    }

    private static func checkWebContract() throws {
        let externalCases: [(Any, String?)] = [
            (" https://example.com/a?q=1 \n", "https://example.com/a?q=1"),
            ("//example.com/a", "https://example.com/a"),
            ("example.com/a", "https://example.com/a"),
            ("http://example.com", "http://example.com"),
            (
                ["url": "", "href": "https://example.com/second", "link": "example.org"],
                "https://example.com/second"
            ),
            (["target": "example.com"], "https://example.com"),
            (["url": 123], nil),
            ("", nil),
            ("not-a-url", nil),
            ("javascript:alert(1)", nil),
            (123, nil)
        ]
        for (index, item) in externalCases.enumerated() {
            check(
                CrailglitunExperienceURLResolver.externalURL(from: item.0)?.absoluteString == item.1,
                "external URL payload compatibility \(index)"
            )
        }

        for scheme in ["about", "blob", "data", "file", "javascript"] {
            check(
                CrailglitunExperienceURLResolver.nativeIntentURL(from: "\(scheme):test") == nil,
                "native intent rejects \(scheme)"
            )
        }
        check(
            CrailglitunExperienceURLResolver.nativeIntentURL(from: " custom://item/1 ")?.absoluteString
                == "custom://item/1",
            "native intent keeps custom schemes"
        )
        check(
            CrailglitunExperienceURLResolver.nativeIntentURL(from: "https:") == nil,
            "native web intent requires a host"
        )

        check(
            CrailglitunExperienceJavaScript.callbackName(from: ["callback": "token_$1"]) == "token_$1",
            "dictionary callback payload"
        )
        check(
            CrailglitunExperienceJavaScript.callbackName(from: "googleLogin") == "googleLogin",
            "string callback payload"
        )
        for callback in ["", "window.callback", "callback()", "callback;alert(1)", "has space"] {
            check(
                CrailglitunExperienceJavaScript.callbackScript(named: callback, value: "value") == nil,
                "invalid callback is ignored: \(callback)"
            )
        }

        let context = JSContext()!
        context.evaluateScript(
            "var window = this; var received = null; window.token_$1 = function(value) { received = value; };"
        )
        let value = "token\"'\\\n); throw new Error('must remain data'); // 中文"
        let script = CrailglitunExperienceJavaScript.callbackScript(named: "token_$1", value: value)!
        check(context.evaluateScript(script)?.toBool() == true, "callback invokes existing function")
        check(context.exception == nil, "callback payload cannot become JavaScript code")
        check(
            context.objectForKeyedSubscript("received")?.toString() == value,
            "callback preserves token exactly")
        let missing = CrailglitunExperienceJavaScript.callbackScript(named: "missing", value: "value")!
        check(context.evaluateScript(missing)?.toBool() == false, "missing callback returns false")
        let json = CrailglitunExperienceJavaScript.jsonString(value)!
        let decoded = try JSONSerialization.jsonObject(with: Data(json.utf8), options: [.fragmentsAllowed])
        check(decoded as? String == value, "FCM event string encoding round trip")
    }

    private static func checkAttributionContract() throws {
        let raw: [AnyHashable: Any] = [
            "media_source": " conversion ",
            "campaign": 42,
            "deep_link_value": NSNull(),
            "enabled": true,
            "count": Int64(7),
            "ratio": 1.25,
            "empty": " null ",
            "invalidNumber": Double.infinity,
            "nested": ["empty": "", "keep": "value"],
            "array": [NSNull(), "nil", "keep"]
        ]
        let conversion = AppsFlyerAttributionPayload(source: .conversionData, attributionData: raw)
        check(conversion.parameters.mediaSource == "conversion", "attribution parameter trimming")
        check(conversion.parameters.campaign == "42", "numeric attribution parameter string conversion")
        check(conversion.parameters.deepLinkValue == nil, "null attribution parameter omitted")
        check(conversion.attributionData["enabled"] == .boolean(true), "boolean stays distinct from integer")
        check(
            conversion.attributionData["count"] == .integer(7), "integer stays distinct from floating point")
        check(conversion.attributionData["ratio"] == .number(1.25), "finite floating point retained")
        check(conversion.attributionData["empty"] == nil, "null-like string omitted")
        check(conversion.attributionData["invalidNumber"] == nil, "non-finite number omitted")
        check(
            conversion.attributionData["nested"] == .object(["keep": .string("value")]),
            "nested empty values filtered")
        check(conversion.attributionData["array"] == .array([.string("keep")]), "array empty values filtered")

        let deepLink = AppsFlyerAttributionPayload(
            source: .deepLink,
            attributionData: ["media_source": "deep-link", "af_app_id": "incoming-id"]
        )
        var state = CrailglitunAttributionResolutionState()
        check(!state.hasResolvedAnySource && !state.hasResolvedAllSources, "initial attribution wait state")
        state.receive(conversion)
        check(
            state.hasResolvedAnySource && !state.hasResolvedAllSources,
            "one callback keeps remaining source pending")
        state.receive(deepLink)
        check(state.hasResolvedAllSources, "both callback sources resolved")
        check(state.mergedData["media_source"] == .string("deep-link"), "deep link wins overlapping fields")
        check(
            state.mergedData["af_app_id"] == .string(AttributionConfiguration.fixedAppsFlyerAppID),
            "fixed app ID wins incoming fields")
        var reversed = CrailglitunAttributionResolutionState()
        reversed.receive(deepLink)
        reversed.receive(conversion)
        check(reversed.mergedData == state.mergedData, "merge priority is independent of callback order")
        var noData = CrailglitunAttributionResolutionState()
        noData.markResolved(.conversionData)
        noData.markResolved(.deepLink)
        check(
            noData.hasResolvedAllSources && noData.mergedData.count == 1,
            "failed or empty callbacks still complete resolution")

        var fields = state.mergedData
        for key in ["appInstanceId", "ua", "appsflyer_id", "deviceId"] {
            fields[key] = .string("must-not-overwrite")
        }
        let request = FirstOpenAttributionRequest(
            appInstanceId: "ai_test",
            attributionData: fields,
            ua: "test-agent",
            appsflyerId: "af-test"
        )
        let data = try JSONEncoder().encode(request)
        let body = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        check(body["appInstanceId"] as? String == "ai_test", "request instance ID cannot be overwritten")
        check(body["ua"] as? String == "test-agent", "request UA cannot be overwritten")
        check(body["appsflyer_id"] as? String == "af-test", "request AppsFlyer ID cannot be overwritten")
        check(body["deviceId"] == nil, "absent reserved metadata stays omitted")
        check(
            body["media_source"] as? String == "deep-link" && body["attributionData"] == nil,
            "attribution fields remain flattened")
    }

    private static func checkResponseContract() throws {
        let body = Data(
            #"{"code":"0","message":123,"requestId":456,"data":{"appInstanceId":123,"organic":" YES ","clickConsumed":0,"idempotentReplay":"1","tenantId":" 42 ","productUrl":" https://example.com/home ","campaignCode":false}}"#
                .utf8)
        let attribution = try decode(body)
        check(attribution.appInstanceId == "123", "response numeric ID accepted")
        check(
            attribution.organic == true && attribution.clickConsumed == false,
            "response boolean variants accepted")
        check(
            attribution.idempotentReplay == true && attribution.tenantId == 42,
            "response numeric strings accepted")
        check(
            attribution.productUrl?.absoluteString == "https://example.com/home",
            "response product URL trimmed")
        check(attribution.campaignCode == "false", "response boolean string conversion")
        let envelope = try JSONDecoder().decode(APIResponse<FirstOpenAttribution>.self, from: body)
        check(envelope.message == "123" && envelope.requestId == "456", "API metadata uses tolerant decoding")
        let empty = try decode(Data(#"{"code":0,"data":{}}"#.utf8))
        check(empty.productUrl == nil && empty.organic == nil, "missing optional fields remain nil")

        let errorCases: [(Data?, Int, String)] = [
            (nil, 200, "The attribution server returned an invalid response."),
            (Data(), 200, "The attribution server returned HTTP 200 with an empty response body."),
            (body, 503, "The attribution server returned HTTP status 503."),
            (
                Data(#"{"code":9,"message":"rejected"}"#.utf8), 200,
                "The attribution server returned error 9: rejected"
            ),
            (
                Data(#"{"code":0}"#.utf8), 200,
                "The attribution server response did not contain attribution data."
            )
        ]
        for (data, status, expected) in errorCases {
            do {
                _ = try decode(data, status: status)
                check(false, "expected response error")
            } catch {
                check(error.localizedDescription == expected, "response error: \(expected)")
            }
        }
        do {
            _ = try decode(Data(#"{"code":"invalid","data":{}}"#.utf8))
            check(false, "invalid API code must fail")
        } catch let FirstOpenAttributionError.decoding(path, _) {
            check(path == "code", "decoding failure retains API code path")
        }
        do {
            _ = try decode(Data("not-json".utf8))
            check(false, "malformed JSON must fail")
        } catch let FirstOpenAttributionError.decoding(path, _) {
            check(path == "<root>", "malformed JSON retains root path")
        }
        do {
            _ = try decode(Data(#"{"code":0,"data":[]}"#.utf8))
            check(false, "invalid data shape must fail")
        } catch let FirstOpenAttributionError.decoding(path, _) {
            check(path == "data", "decoding failure retains nested path")
        }
        do {
            _ = try decode(body, status: 503, error: URLError(.timedOut))
            check(false, "transport error must win")
        } catch let error as URLError {
            check(error.code == .timedOut, "transport errors take precedence over HTTP and payload errors")
        }
    }

    private static func decode(
        _ data: Data?,
        status: Int = 200,
        error: Error? = nil
    ) throws -> FirstOpenAttribution {
        let response = HTTPURLResponse(
            url: URL(string: "https://example.invalid")!, statusCode: status, httpVersion: nil,
            headerFields: nil)
        return try CrailglitunFirstOpenResponseDecoder.decode(
            data: data,
            response: response,
            error: error,
            using: JSONDecoder()
        )
    }

    private static func checkTransportContract() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [CrailglitunStubURLProtocol.self]
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        let client = FirstOpenAttributionClient(
            endpoint: URL(string: "https://example.invalid/first-open")!,
            session: session
        )
        var events: [String] = []
        let result: FirstOpenAttribution = try await withCheckedThrowingContinuation { continuation in
            client.reportFirstOpen(
                request: FirstOpenAttributionRequest(appInstanceId: "ai_transport", attributionData: [:]),
                eventHandler: { event in
                    MainActor.assertIsolated()
                    switch event {
                    case .request:
                        events.append("request")
                    case .response(let status, _):
                        check(status == 200, "transport reports HTTP status")
                        events.append("response")
                    }
                },
                completion: { result in
                    MainActor.assertIsolated()
                    events.append("completion")
                    continuation.resume(with: result)
                }
            )
        }
        check(
            result.appInstanceId == "ai_transport",
            "transport sends POST with JSON content type and delivers decoded result")
        #if DEBUG
        check(events == ["request", "response", "completion"], "debug events precede completion")
        #else
        check(events == ["completion"], "release omits diagnostic payload events")
        #endif
        var encodingFailed = false
        client.reportFirstOpen(
            request: FirstOpenAttributionRequest(
                appInstanceId: "ai_invalid", attributionData: ["invalid": .number(.infinity)]),
            eventHandler: { _ in check(false, "invalid request must not emit network events") },
            completion: { result in
                if case .failure = result {
                    encodingFailed = true
                }
            }
        )
        check(encodingFailed, "request encoding failure completes synchronously without transport")
    }
}

/// All transport checks are fulfilled locally; this protocol never starts a network connection.
nonisolated private final class CrailglitunStubURLProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard request.httpMethod == "POST",
            request.value(forHTTPHeaderField: "Content-Type") == "application/json"
        else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        let response = HTTPURLResponse(
            url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(#"{"code":0,"data":{"appInstanceId":"ai_transport"}}"#.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
