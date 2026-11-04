import AuthenticationServices
import UIKit

nonisolated enum CrailglitunAppleSignInError: LocalizedError {
    case invalidAuthorization

    var errorDescription: String? {
        "Apple sign-in could not be completed. Please try again."
    }
}

/// Keeps the native Apple sign-in state on this device. No cloud session is created.
@MainActor
final class CrailglitunAppleSignInService: NSObject,
    ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private var pending: CheckedContinuation<Void, Error>?
    private var authorizationController: ASAuthorizationController?
    private var presentationWindow: UIWindow?
    private var state: String?
    private let defaults: UserDefaults
    private let userIDKey = "Crailglitun.appleSignIn.userIdentifier"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        super.init()
    }

    var isSignedIn: Bool {
        defaults.string(forKey: userIDKey) != nil
    }

    func signOut() {
        defaults.removeObject(forKey: userIDKey)
    }

    func refreshSession() async {
        guard let userID = defaults.string(forKey: userIDKey),
              let credentialState = try? await ASAuthorizationAppleIDProvider().credentialState(forUserID: userID),
              defaults.string(forKey: userIDKey) == userID else {
            return
        }
        if credentialState != .authorized {
            signOut()
        }
    }

    func signIn(presenting controller: UIViewController) async throws {
        guard pending == nil, let window = controller.viewIfLoaded?.window else {
            throw CrailglitunAppleSignInError.invalidAuthorization
        }
        presentationWindow = window
        state = UUID().uuidString
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.state = state

        try await withCheckedThrowingContinuation { continuation in
            pending = continuation
            let authorization = ASAuthorizationController(authorizationRequests: [request])
            authorizationController = authorization
            authorization.delegate = self
            authorization.presentationContextProvider = self
            authorization.performRequests()
        }
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // The visible window is retained until the native request finishes.
        presentationWindow!
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard controller === authorizationController else { return }
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              !credential.user.isEmpty,
              credential.state == state else {
            finish(.failure(CrailglitunAppleSignInError.invalidAuthorization))
            return
        }
        defaults.set(credential.user, forKey: userIDKey)
        finish(.success(()))
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        guard controller === authorizationController else { return }
        finish(.failure(error))
    }

    private func finish(_ result: Result<Void, Error>) {
        let continuation = pending
        pending = nil
        authorizationController = nil
        presentationWindow = nil
        state = nil
        continuation?.resume(with: result)
    }
}
