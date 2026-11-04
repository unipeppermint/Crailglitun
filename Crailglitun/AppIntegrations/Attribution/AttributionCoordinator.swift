import Foundation
import UIKit

extension Notification.Name {
    nonisolated static let attributionParametersDidResolve = Notification.Name(
        "AttributionParametersDidResolve"
    )
    nonisolated static let firstOpenAttributionDidResolve = Notification.Name(
        "FirstOpenAttributionDidResolve"
    )
}

nonisolated enum AttributionNotificationKey {
    static let parameters = "parameters"
    static let attribution = "attribution"
}

@MainActor
final class AttributionCoordinator {
    weak var delegate: AttributionCoordinatorDelegate?

    private(set) var latestParameters: AttributionParameters?
    private(set) var latestAttributionData: [String: AttributionValue] = [:]
    private(set) var firstOpenAttribution: FirstOpenAttribution?
    private(set) var productURL: URL?
    private(set) var firstOpenError: Error?
    private(set) var eventHistory: [AttributionEvent] = []
    private(set) var isReportingFirstOpen = false

    private let appsFlyerService: AppsFlyerAttributionService
    private let firstOpenClient: FirstOpenAttributionClientProtocol
    private let stateStore: AttributionStateStore
    private let requestMetadataProvider: FirstOpenRequestMetadataProviding
    private let notificationCenter: NotificationCenter
    private var resolutionState = CrailglitunAttributionResolutionState()
    private var firstOpenWaitWorkItem: DispatchWorkItem?
    private var hasStartedAutomaticFirstOpenReport = false
    private let logger = AttributionLogger(category: "FirstOpen")

    init(
        appsFlyerService: AppsFlyerAttributionService? = nil,
        firstOpenClient: FirstOpenAttributionClientProtocol? = nil,
        stateStore: AttributionStateStore? = nil,
        requestMetadataProvider: FirstOpenRequestMetadataProviding? = nil,
        notificationCenter: NotificationCenter = .default
    ) {
        self.appsFlyerService = appsFlyerService ?? AppsFlyerAttributionService()
        self.firstOpenClient = firstOpenClient ?? FirstOpenAttributionClient()
        self.stateStore = stateStore ?? AttributionStateStore()
        self.requestMetadataProvider = requestMetadataProvider
            ?? SystemFirstOpenRequestMetadataProvider()
        self.notificationCenter = notificationCenter
        self.productURL = self.stateStore.cachedProductURL
    }

    func configure(
        launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) {
        appsFlyerService.delegate = self
        appsFlyerService.configure(launchOptions: launchOptions)
        emit(
            level: AttributionConfiguration.appsFlyerAppID.isEmpty ? .warning : .info,
            title: "AppsFlyer Configuration",
            message: AttributionConfiguration.appsFlyerAppID.isEmpty
                ? "Apple App ID is missing. Add the numeric App Store ID to Info.plist."
                : "AppsFlyer SDK is configured."
        )
    }

    @discardableResult
    func handleOpen(
        url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        emit(level: .info, title: "URL Callback", message: url.absoluteString)
        return appsFlyerService.handleOpen(url: url, options: options)
    }

    @discardableResult
    func continueUserActivity(
        _ userActivity: NSUserActivity
    ) -> Bool {
        emit(
            level: .info,
            title: "Universal Link Callback",
            message: userActivity.webpageURL?.absoluteString ?? "No webpage URL"
        )
        return appsFlyerService.continueUserActivity(userActivity)
    }

    func submitFirstOpen(
        completion: @escaping @MainActor (Result<FirstOpenAttribution, Error>) -> Void
    ) {
        cancelFirstOpenWait()
        reportFirstOpen(
            with: resolutionState.mergedData,
            force: true,
            source: "Manual",
            completion: completion
        )
    }

    func clearEventHistory() {
#if DEBUG
        eventHistory.removeAll()
#endif
    }

    private func reportFirstOpen(
        with attributionData: [String: AttributionValue],
        force: Bool = false,
        source: String = "Automatic",
        completion: (@MainActor (Result<FirstOpenAttribution, Error>) -> Void)? = nil
    ) {
        cancelFirstOpenWait()
        guard force || !stateStore.didReportFirstOpen else { return }
        guard !isReportingFirstOpen else {
            let error = AttributionCoordinatorError.requestInProgress
            emit(level: .warning, title: "First Open Skipped", message: error.localizedDescription)
            completion?(.failure(error))
            return
        }
        if !force {
            guard !hasStartedAutomaticFirstOpenReport else {
                emit(
                    level: .info,
                    title: "First Open Skipped",
                    message: "The automatic first-open request has already been started for this launch."
                )
                return
            }
            hasStartedAutomaticFirstOpenReport = true
        }
        isReportingFirstOpen = true
        firstOpenError = nil

        requestMetadataProvider.makeMetadata { [weak self] metadata in
            guard let self else { return }

            let request = FirstOpenAttributionRequest(
                appInstanceId: self.stateStore.appInstanceID,
                attributionData: attributionData,
                ua: metadata.userAgent,
                appsflyerId: metadata.appsFlyerId,
                deviceId: metadata.deviceId
            )
            self.sendFirstOpenRequest(
                request,
                attributionFieldCount: attributionData.count,
                source: source,
                completion: completion
            )
        }
    }

    private func sendFirstOpenRequest(
        _ request: FirstOpenAttributionRequest,
        attributionFieldCount: Int,
        source: String,
        completion: (@MainActor (Result<FirstOpenAttribution, Error>) -> Void)?
    ) {
        isReportingFirstOpen = true
        emit(
            level: .info,
            title: "First Open Trigger",
            message: "\(source) request | \(request.appInstanceId) | \(attributionFieldCount) attribution fields"
        )

        firstOpenClient.reportFirstOpen(
            request: request,
            eventHandler: { [weak self] event in
                self?.recordNetworkEvent(event)
            }
        ) { [weak self] result in
            guard let self else { return }

            self.completeFirstOpen(result)
            completion?(result)
        }
    }

    private func completeFirstOpen(_ result: Result<FirstOpenAttribution, Error>) {
        isReportingFirstOpen = false

        switch result {
        case let .success(attribution):
            recordSuccessfulFirstOpen(attribution)
        case let .failure(error):
            firstOpenError = error
            logger.error("First-open attribution failed: \(error.localizedDescription)")
            emit(
                level: .failure,
                title: "First Open Failure",
                message: error.localizedDescription
            )
        }
    }

    private func recordSuccessfulFirstOpen(_ attribution: FirstOpenAttribution) {
        stateStore.didReportFirstOpen = true
        firstOpenAttribution = attribution
        updateProductURL(from: attribution)
        notificationCenter.post(
            name: .firstOpenAttributionDidResolve,
            object: self,
            userInfo: [AttributionNotificationKey.attribution: attribution]
        )
        logger.info("First-open attribution resolved.")
        emit(
            level: .success,
            title: "First Open Success",
            message: [
                attribution.attributionStatus,
                attribution.attributionMethod,
                attribution.organic.map { $0 ? "Organic" : "Non-organic" }
            ]
            .compactMap { $0 }
            .joined(separator: " | ")
            .ifEmpty("Attribution data returned")
        )
    }

    private func updateProductURL(from attribution: FirstOpenAttribution) {
        if let testProductURL = AttributionConfiguration.testProductURL {
            productURL = testProductURL
        } else if let productURL = attribution.productUrl {
            stateStore.cachedProductURL = productURL
            self.productURL = productURL
        } else {
            productURL = stateStore.cachedProductURL
        }
    }

    private func recordNetworkEvent(_ event: FirstOpenNetworkEvent) {
        switch event {
        case let .request(body):
            logger.info("First Open Request JSON:\n\(body)")
            emit(
                level: .info,
                title: "First Open Request JSON",
                message: body
            )
        case let .response(statusCode, body):
            let status = statusCode.map(String.init) ?? "No HTTP status"
            logger.info("First Open Response JSON (HTTP \(status)):\n\(body)")
            emit(
                level: statusCode.map { (200...299).contains($0) } == true ? .success : .warning,
                title: "First Open Response JSON",
                message: "HTTP \(status)\n\(body)"
            )
        }
    }

    private func evaluateFirstOpenReporting() {
        guard !stateStore.didReportFirstOpen, !isReportingFirstOpen else { return }
        guard resolutionState.hasResolvedAnySource else { return }

        if resolutionState.hasResolvedAllSources {
            cancelFirstOpenWait()
            reportFirstOpen(with: resolutionState.mergedData)
            return
        }

        guard firstOpenWaitWorkItem == nil else { return }
        let waitWorkItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.firstOpenWaitWorkItem = nil
            guard !self.stateStore.didReportFirstOpen, !self.isReportingFirstOpen else {
                return
            }
            self.emit(
                level: .warning,
                title: "Attribution Wait Timeout",
                message: "Sending the attribution data resolved within the wait window."
            )
            self.reportFirstOpen(with: self.resolutionState.mergedData)
        }
        firstOpenWaitWorkItem = waitWorkItem
        emit(
            level: .info,
            title: "Waiting for Attribution Data",
            message: "Waiting up to \(AttributionConfiguration.firstOpenAttributionWaitTimeout) seconds for the remaining AppsFlyer callback."
        )
        DispatchQueue.main.asyncAfter(
            deadline: .now() + AttributionConfiguration.firstOpenAttributionWaitTimeout,
            execute: waitWorkItem
        )
    }

    private func cancelFirstOpenWait() {
        firstOpenWaitWorkItem?.cancel()
        firstOpenWaitWorkItem = nil
    }

    private func emit(
        level: AttributionEventLevel,
        title: @autoclosure () -> String,
        message: @autoclosure () -> String
    ) {
#if DEBUG
        let event = AttributionEvent(
            level: level,
            title: title(),
            message: message()
        )
        eventHistory.append(event)
        if eventHistory.count > 200 {
            eventHistory.removeFirst(eventHistory.count - 200)
        }
#endif
        delegate?.attributionCoordinatorDidUpdate(self)
    }
}

extension AttributionCoordinator: AppsFlyerAttributionServiceDelegate {
    func appsFlyerServiceDidStart(_ service: AppsFlyerAttributionService) {
        emit(
            level: .info,
            title: "AppsFlyer Session Ready",
            message: "The SDK started the attribution session."
        )
    }

    func appsFlyerService(
        _ service: AppsFlyerAttributionService,
        didReceive payload: AppsFlyerAttributionPayload
    ) {
        let parameters = payload.parameters
        latestParameters = parameters
        resolutionState.receive(payload)
        latestAttributionData = resolutionState.mergedData
        notificationCenter.post(
            name: .attributionParametersDidResolve,
            object: self,
            userInfo: [AttributionNotificationKey.parameters: parameters]
        )
        emit(
            level: .success,
            title: payload.source.logTitle,
            message: payload.formattedData
        )
        evaluateFirstOpenReporting()
    }

    func appsFlyerService(
        _ service: AppsFlyerAttributionService,
        didFailWith error: Error
    ) {
        logger.error("AppsFlyer attribution failed: \(error.localizedDescription)")
        emit(
            level: .failure,
            title: "AppsFlyer Attribution Failure",
            message: error.localizedDescription
        )
    }

    func appsFlyerServiceDidFinishConversionResolution(
        _ service: AppsFlyerAttributionService
    ) {
        resolutionState.markResolved(.conversionData)
        evaluateFirstOpenReporting()
    }

    func appsFlyerServiceDidFinishDeepLinkResolution(
        _ service: AppsFlyerAttributionService
    ) {
        resolutionState.markResolved(.deepLink)
        evaluateFirstOpenReporting()
    }
}

private extension String {
    func ifEmpty(_ fallback: String) -> String {
        isEmpty ? fallback : self
    }
}
