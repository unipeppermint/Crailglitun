import FirebaseAuth
import FirebaseCore
import FirebaseMessaging
import Foundation

nonisolated enum FirebasePlatformServiceError: LocalizedError {
    case missingFirebaseUser
    case missingFirebaseIDToken
    case firebaseAuthentication(String)
    case messagingToken(String)

    var errorDescription: String? {
        switch self {
        case .missingFirebaseUser:
            return "Firebase did not return an authenticated user."
        case .missingFirebaseIDToken:
            return "Firebase did not return an ID token."
        case let .firebaseAuthentication(message):
            return "Firebase authentication failed: \(message)"
        case let .messagingToken(message):
            return "FCM token request failed: \(message)"
        }
    }
}

@MainActor
final class FirebasePlatformService {
    var googleClientID: String? {
        FirebaseApp.app()?.options.clientID
    }

    func configure() {
        guard FirebaseApp.app() == nil else { return }
        FirebaseApp.configure()
    }

    func signIn(
        withGoogleTokens tokens: GoogleSignInTokens,
        completion: @escaping @MainActor (Result<String, Error>) -> Void
    ) {
        configure()

        let credential = GoogleAuthProvider.credential(
            withIDToken: tokens.idToken,
            accessToken: tokens.accessToken
        )
        Auth.auth().signIn(with: credential) { authResult, error in
            if let error {
                completion(
                    .failure(
                        FirebasePlatformServiceError.firebaseAuthentication(
                            error.localizedDescription
                        )
                    )
                )
                return
            }

            guard let user = authResult?.user else {
                completion(.failure(FirebasePlatformServiceError.missingFirebaseUser))
                return
            }

            user.getIDToken { token, error in
                if let error {
                    completion(
                        .failure(
                            FirebasePlatformServiceError.firebaseAuthentication(
                                error.localizedDescription
                            )
                        )
                    )
                    return
                }

                guard let token, !token.isEmpty else {
                    completion(.failure(FirebasePlatformServiceError.missingFirebaseIDToken))
                    return
                }
                completion(.success(token))
            }
        }
    }

    func fetchMessagingToken(
        completion: @escaping @MainActor (Result<String, Error>) -> Void
    ) {
        configure()
        Messaging.messaging().token { token, error in
            let result: Result<String, Error>

            if let error {
                result = .failure(
                    FirebasePlatformServiceError.messagingToken(error.localizedDescription)
                )
            } else if let token, !token.isEmpty {
                result = .success(token)
            } else {
                result = .failure(
                    FirebasePlatformServiceError.messagingToken("No token was returned.")
                )
            }

            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
}
