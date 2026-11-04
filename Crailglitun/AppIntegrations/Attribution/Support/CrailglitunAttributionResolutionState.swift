import Foundation

/// Tracks callback completion separately from whether the callback supplied data.
nonisolated struct CrailglitunAttributionResolutionState {
    private var conversionData: [String: AttributionValue]?
    private var deepLinkData: [String: AttributionValue]?
    private var didResolveConversionData = false
    private var didResolveDeepLink = false

    var hasResolvedAnySource: Bool {
        didResolveConversionData || didResolveDeepLink
    }

    var hasResolvedAllSources: Bool {
        didResolveConversionData && didResolveDeepLink
    }

    var mergedData: [String: AttributionValue] {
        var merged = conversionData ?? [:]
        if let deepLinkData {
            merged.merge(deepLinkData) { _, deepLinkValue in deepLinkValue }
        }
        merged["af_app_id"] = .string(AttributionConfiguration.fixedAppsFlyerAppID)
        return merged
    }

    mutating func receive(_ payload: AppsFlyerAttributionPayload) {
        switch payload.source {
        case .conversionData:
            conversionData = payload.attributionData
        case .deepLink:
            deepLinkData = payload.attributionData
        }
        markResolved(payload.source)
    }

    mutating func markResolved(_ source: AppsFlyerAttributionPayload.Source) {
        switch source {
        case .conversionData:
            didResolveConversionData = true
        case .deepLink:
            didResolveDeepLink = true
        }
    }
}
