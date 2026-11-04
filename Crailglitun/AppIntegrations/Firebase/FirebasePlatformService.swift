import FirebaseAuth
import FirebaseCore
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
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        CrailglitunPushService.shared.configure()
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
                let failure = FirebasePlatformServiceError.firebaseAuthentication(
                    error.localizedDescription
                )
                completion(.failure(failure))
                return
            }

            guard let user = authResult?.user else {
                completion(.failure(FirebasePlatformServiceError.missingFirebaseUser))
                return
            }

            Self.fetchIDToken(for: user, completion: completion)
        }
    }

    private static func fetchIDToken(
        for user: User,
        completion: @escaping @MainActor (Result<String, Error>) -> Void
    ) {
        user.getIDToken { token, error in
            if let error {
                let failure = FirebasePlatformServiceError.firebaseAuthentication(
                    error.localizedDescription
                )
                completion(.failure(failure))
                return
            }

            guard let token, !token.isEmpty else {
                completion(.failure(FirebasePlatformServiceError.missingFirebaseIDToken))
                return
            }
            completion(.success(token))
        }
    }

    func fetchMessagingToken(
        completion: @escaping @MainActor (Result<String, Error>) -> Void
    ) {
        configure()
        CrailglitunPushService.shared.fetchMessagingToken(completion: completion)
    }
}
