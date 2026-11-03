import Foundation
import WebKit

protocol WebNativeBridgeDelegate: AnyObject {
    func webNativeBridge(_ bridge: WebNativeBridge, openIntent urlString: String)
    func webNativeBridge(_ bridge: WebNativeBridge, deleteCookieNamed name: String)
    func webNativeBridgeDidRequestGoogleLogin(_ bridge: WebNativeBridge)
}

final class WebNativeBridge: NSObject {
    private enum Action: String {
        case openIntent
        case deleteCookie
        case loginGoogle
    }

    private enum MessageKey {
        static let action = "action"
        static let value = "value"
    }

    private static let messageHandlerName = "nativeBridge"

    private static let injectionScript = """
    (function () {
        var handlers = window.webkit && window.webkit.messageHandlers;
        var messageHandler = handlers && handlers.nativeBridge;
        if (!messageHandler) {
            return;
        }

        var bridge = window.nativeBridge;
        if (!bridge || typeof bridge !== "object") {
            bridge = {};
        }

        bridge.openIntent = function (url) {
            messageHandler.postMessage({
                action: "openIntent",
                value: String(url == null ? "" : url)
            });
        };

        bridge.deleteCookie = function (key) {
            messageHandler.postMessage({
                action: "deleteCookie",
                value: String(key == null ? "" : key)
            });
        };

        bridge.loginGoogle = function () {
            messageHandler.postMessage({ action: "loginGoogle" });
        };

        // The current website invokes start when a native bridge exists.
        // Keep it as a no-op until the app owns a removable startup overlay.
        if (typeof bridge.start !== "function") {
            bridge.start = function () {};
        }

        window.nativeBridge = bridge;
    })();
    """

    weak var delegate: WebNativeBridgeDelegate?

    private weak var contentController: WKUserContentController?

    func install(in contentController: WKUserContentController) {
        uninstall()
        self.contentController = contentController
        contentController.add(self, name: Self.messageHandlerName)
        contentController.addUserScript(
            WKUserScript(
                source: Self.injectionScript,
                injectionTime: .atDocumentStart,
                forMainFrameOnly: true
            )
        )
    }

    func uninstall() {
        contentController?.removeScriptMessageHandler(
            forName: Self.messageHandlerName
        )
        contentController = nil
    }
}

extension WebNativeBridge: WKScriptMessageHandler {
    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard message.name == Self.messageHandlerName,
              message.frameInfo.isMainFrame,
              let body = message.body as? [String: Any],
              let actionValue = body[MessageKey.action] as? String,
              let action = Action(rawValue: actionValue) else {
            return
        }

        switch action {
        case .openIntent:
            guard let urlString = body[MessageKey.value] as? String else { return }
            delegate?.webNativeBridge(self, openIntent: urlString)

        case .deleteCookie:
            guard let name = body[MessageKey.value] as? String else { return }
            delegate?.webNativeBridge(self, deleteCookieNamed: name)

        case .loginGoogle:
            delegate?.webNativeBridgeDidRequestGoogleLogin(self)
        }
    }
}
