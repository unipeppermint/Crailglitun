import Foundation

nonisolated enum AttributionEventLevel: Sendable {
    case info
    case success
    case warning
    case failure
}

nonisolated struct AttributionEvent: Identifiable, Sendable {
    let id = UUID()
    let date = Date()
    let level: AttributionEventLevel
    let title: String
    let message: String
}

@MainActor
protocol AttributionCoordinatorDelegate: AnyObject {
    func attributionCoordinatorDidUpdate(_ coordinator: AttributionCoordinator)
}

nonisolated enum AttributionCoordinatorError: LocalizedError {
    case requestInProgress

    var errorDescription: String? {
        switch self {
        case .requestInProgress:
            return "A first-open attribution request is already in progress."
        }
    }
}
