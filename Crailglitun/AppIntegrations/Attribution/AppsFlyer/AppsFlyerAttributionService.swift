import AppsFlyerLib
import Foundation
import UIKit

@MainActor
protocol AppsFlyerAttributionServiceDelegate: AnyObject {
    func appsFlyerServiceDidStart(_ service: AppsFlyerAttributionService)

    func appsFlyerService(
        _ service: AppsFlyerAttributionService,
        didReceive payload: AppsFlyerAttributionPayload
    )

    func appsFlyerService(
        _ service: AppsFlyerAttributionService,
        didFailWith error: Error
    )

    func appsFlyerServiceDidFinishConversionResolution(
        _ service: AppsFlyerAttributionService
    )

    func appsFlyerServiceDidFinishDeepLinkResolution(
        _ service: AppsFlyerAttributionService
    )
}

@MainActor
final class AppsFlyerAttributionService: NSObject {
    weak var delegate: AppsFlyerAttributionServiceDelegate?

    private let logger = AttributionLogger(category: "AppsFlyer")
    private var isConfigured = false

    func configure(
        launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) {
        guard !isConfigured else { return }

        let appsFlyer = AppsFlyerLib.shared()
        let appID = AttributionConfiguration.appsFlyerAppID
        appsFlyer.initialize(
            devKey: AttributionConfiguration.appsFlyerDevKey,
            appId: appID
        )
        appsFlyer.delegate = self
        appsFlyer.deepLinkDelegate = self
        appsFlyer.handleLaunchOptions(launchOptions)

        if appID.isEmpty {
            logger.error("AppsFlyerAppID is missing from Info.plist.")
        }

        appsFlyer.registerSessionReadyListener { [weak self] in
            DispatchQueue.main.async {
                AppsFlyerLib.shared().start()
                guard let self else { return }
                self.delegate?.appsFlyerServiceDidStart(self)
            }
        }
        isConfigured = true
    }

    @discardableResult
    func handleOpen(
        url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        AppsFlyerLib.shared().handleOpen(url, options: options)
        return true
    }
    
    @discardableResult
    func continueUserActivity(
        _ userActivity: NSUserActivity
    ) -> Bool {
        AppsFlyerLib.shared().continue(
            userActivity,
            restorationHandler: nil
        )
    }
}

extension AppsFlyerAttributionService: AppsFlyerLibDelegate {
    nonisolated func onConversionDataSuccess(_ conversionInfo: [AnyHashable: Any]) {
        let payload = AppsFlyerAttributionPayload(
            source: .conversionData,
            attributionData: conversionInfo
        )

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.logger.info("\(payload.source.logTitle):\n\(payload.formattedData)")
            self.delegate?.appsFlyerService(self, didReceive: payload)
            self.delegate?.appsFlyerServiceDidFinishConversionResolution(self)
        }
    }

    nonisolated func onConversionDataFail(_ error: Error) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.logger.error("AppsFlyer conversion data failed: \(error.localizedDescription)")
            self.delegate?.appsFlyerService(self, didFailWith: error)
            self.delegate?.appsFlyerServiceDidFinishConversionResolution(self)
        }
    }
}

extension AppsFlyerAttributionService: AppsFlyerDeepLinkDelegate {
    nonisolated func didResolveDeepLink(_ result: DeepLinkResult) {
        let resolution: AppsFlyerDeepLinkResolution

        switch result.status {
        case .found:
            if let deepLink = result.deepLink {
                let attributionData = Dictionary<AnyHashable, Any>(
                    uniqueKeysWithValues: deepLink.clickEvent.map {
                        (AnyHashable($0.key), $0.value)
                    }
                )
                resolution = .found(
                    AppsFlyerAttributionPayload(
                        source: .deepLink,
                        attributionData: attributionData
                    )
                )
            } else {
                resolution = .missingData
            }
        case .notFound:
            resolution = .notFound
        case .failure:
            resolution = .failure(
                result.error ?? AppsFlyerAttributionServiceError.deepLinkResolutionFailed
            )
        @unknown default:
            resolution = .unknown
        }

        DispatchQueue.main.async { [weak self] in
            self?.handleDeepLinkResolution(resolution)
        }
    }

    private func handleDeepLinkResolution(_ resolution: AppsFlyerDeepLinkResolution) {
        switch resolution {
        case let .found(payload):
            logger.info("\(payload.source.logTitle):\n\(payload.formattedData)")
            delegate?.appsFlyerService(self, didReceive: payload)
        case .missingData:
            logger.warning("AppsFlyer deep link status was found without data.")
        case .notFound:
            logger.info("AppsFlyer deep link data was not found.")
        case let .failure(error):
            logger.error("AppsFlyer deep link resolution failed: \(error.localizedDescription)")
            delegate?.appsFlyerService(self, didFailWith: error)
        case .unknown:
            logger.warning("AppsFlyer returned an unknown deep link status.")
        }

        delegate?.appsFlyerServiceDidFinishDeepLinkResolution(self)
    }
}

nonisolated private enum AppsFlyerDeepLinkResolution: Sendable {
    case found(AppsFlyerAttributionPayload)
    case missingData
    case notFound
    case failure(Error)
    case unknown
}

nonisolated private enum AppsFlyerAttributionServiceError: LocalizedError {
    case deepLinkResolutionFailed

    var errorDescription: String? {
        "AppsFlyer failed to resolve the deep link."
    }
}
