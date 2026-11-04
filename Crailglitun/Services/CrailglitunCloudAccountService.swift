import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import UIKit

nonisolated enum CrailglitunCloudError: LocalizedError {
    case configuration
    case signInRequired
    case invalidCredential
    case accountChanged

    var errorDescription: String? {
        switch self {
        case .configuration:
            return "Cloud backup is not available yet. Please try again later."
        case .signInRequired:
            return "Sign in to access your cloud backups."
        case .invalidCredential:
            return "Sign-in could not be verified. Please try again."
        case .accountChanged:
            return "Your account changed. Sign in again before continuing."
        }
    }
}

/// Google cloud accounts use the app's existing Firebase authentication.
@MainActor
final class CrailglitunCloudAccountService {
    var user: User? { Auth.auth().currentUser }

    func signInWithGoogle(presenting controller: UIViewController) async throws {
        let credential = try await googleCredential(presenting: controller)
        try Task.checkCancellation()
        _ = try await Auth.auth().signIn(with: credential)
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }

    func refreshSession() async throws {
        guard let user else { return }
        do {
            try await user.reload()
        } catch {
            let authError = error as NSError
            let expiredCodes = [AuthErrorCode.userNotFound, .userDisabled, .invalidUserToken, .userTokenExpired]
            if authError.domain == AuthErrorDomain, expiredCodes.contains(where: { $0.rawValue == authError.code }) {
                try signOut()
                throw CrailglitunCloudError.signInRequired
            }
            throw error
        }
    }

    /// Reauthentication happens before any destructive request, including cloud-file deletion.
    func reauthenticateForDeletion(presenting controller: UIViewController) async throws {
        guard let user else { throw CrailglitunCloudError.signInRequired }
        let credential = try await googleCredential(presenting: controller)
        _ = try await user.reauthenticate(with: credential)
        guard self.user?.uid == user.uid else { throw CrailglitunCloudError.accountChanged }
    }

    func deleteAccount(uid: String) async throws {
        guard let user, user.uid == uid else { throw CrailglitunCloudError.accountChanged }
        try await user.delete()
    }

    private func googleCredential(presenting controller: UIViewController) async throws -> AuthCredential {
        guard let clientID = FirebaseApp.app()?.options.clientID, !clientID.isEmpty else {
            throw CrailglitunCloudError.configuration
        }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: controller)
        guard let idToken = result.user.idToken?.tokenString, !idToken.isEmpty else {
            throw CrailglitunCloudError.invalidCredential
        }
        return GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )
    }

}
