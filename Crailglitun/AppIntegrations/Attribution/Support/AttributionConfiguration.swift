import Foundation

nonisolated enum AttributionConfiguration {
    static let firstOpenAttributionWaitTimeout: TimeInterval = 3.0
    static let fixedAppsFlyerAppID = "id6805295325"
//    static let fixedAppsFlyerAppID = "id6822245395"
    static let testProductURL: URL? = nil
    // URL(string: "https://fortunepurple.com/?pixelType=8&isApp=1&channelId=11")

    static let firstOpenEndpoint = URL(
        string: "https://attributionsolutions.com/tracking-api/attribution/first-open"
//        string: "https://qilnex.top/service/thinklever"
    )!

    static var appsFlyerDevKey: String {
        Bundle.main.object(forInfoDictionaryKey: "AppsFlyerDevKey") as? String ?? ""
    }

    static var appsFlyerAppID: String {
        Bundle.main.object(forInfoDictionaryKey: "AppsFlyerAppID") as? String ?? ""
    }
}
