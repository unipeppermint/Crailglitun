import GoogleSignIn
import UIKit

nonisolated struct GoogleSignInTokens: Sendable {
    let accessToken: String
    let idToken: String
}

nonisolated enum GoogleSignInServiceError: LocalizedError {
    case missingClientID
    case missingIdentity
    case authorization(String)

    var errorDescription: String? {
        switch self {
        case .missingClientID:
            return "Google client ID is unavailable."
        case .missingIdentity:
            return "Google did not return valid authentication tokens."
        case let .authorization(message):
            return "Google sign-in failed: \(message)"
        }
    }
}

@MainActor
final class GoogleSignInService {
    private var clientID: String?

    func configure(clientID: String?) {
        self.clientID = clientID
    }

    @discardableResult
    func handleOpen(_ url: URL) -> Bool {
        GIDSignIn.sharedInstance.handle(url)
    }

    func signIn(
        presenting viewController: UIViewController,
        completion: @escaping @MainActor (Result<GoogleSignInTokens, Error>) -> Void
    ) {
        guard let clientID, !clientID.isEmpty else {
            completion(.failure(GoogleSignInServiceError.missingClientID))
            return
        }

        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.signIn(withPresenting: viewController) { result, error in
            let outcome = Self.signInResult(from: result, error: error)

            DispatchQueue.main.async {
                completion(outcome)
            }
        }
    }

    nonisolated private static func signInResult(
        from result: GIDSignInResult?,
        error: Error?
    ) -> Result<GoogleSignInTokens, Error> {
        if let error {
            return .failure(
                GoogleSignInServiceError.authorization(error.localizedDescription)
            )
        } else if let user = result?.user,
                  let idToken = user.idToken?.tokenString,
                  !idToken.isEmpty,
                  !user.accessToken.tokenString.isEmpty {
            return .success(
                GoogleSignInTokens(
                    accessToken: user.accessToken.tokenString,
                    idToken: idToken
                )
            )
        } else {
            return .failure(GoogleSignInServiceError.missingIdentity)
        }
    }
}
