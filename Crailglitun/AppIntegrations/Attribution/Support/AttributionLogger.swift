import Foundation

#if DEBUG
import OSLog
#endif

nonisolated struct AttributionLogger: Sendable {
#if DEBUG
    private let logger: Logger
#endif

    init(category: String) {
#if DEBUG
        logger = Logger(
            subsystem: Bundle.main.bundleIdentifier ?? "Attribution",
            category: category
        )
#endif
    }

    func info(_ message: @autoclosure () -> String) {
#if DEBUG
        let value = message()
        logger.info("\(value, privacy: .public)")
#endif
    }

    func warning(_ message: @autoclosure () -> String) {
#if DEBUG
        let value = message()
        logger.warning("\(value, privacy: .public)")
#endif
    }

    func error(_ message: @autoclosure () -> String) {
#if DEBUG
        let value = message()
        logger.error("\(value, privacy: .public)")
#endif
    }
}
