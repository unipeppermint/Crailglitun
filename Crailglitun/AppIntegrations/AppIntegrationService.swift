import UIKit

/// The host app's entry point for attribution, Firebase, and Google sign-in.
@MainActor
final class AppIntegrationService {
    static let shared = AppIntegrationService()

    let attributionCoordinator = AttributionCoordinator()

    private let firebaseService = FirebasePlatformService()
    private let googleSignInService = GoogleSignInService()
    private var isConfigured = false

    private init() {}

    func configure(
        launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) {
        guard !isConfigured else { return }
        isConfigured = true

        configureAuthenticationServices()
        attributionCoordinator.configure(launchOptions: launchOptions)
    }

    @discardableResult
    func handleOpen(
        url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        if googleSignInService.handleOpen(url) {
            return true
        }
        return attributionCoordinator.handleOpen(url: url, options: options)
    }

    @discardableResult
    func continueUserActivity(_ userActivity: NSUserActivity) -> Bool {
        attributionCoordinator.continueUserActivity(userActivity)
    }

    func handleSceneConnection(_ connectionOptions: UIScene.ConnectionOptions) {
        if let response = connectionOptions.notificationResponse {
            CrailglitunPushService.shared.handleNotificationResponse(response)
        }
        handleOpenURLContexts(connectionOptions.urlContexts)
        for userActivity in connectionOptions.userActivities {
            continueUserActivity(userActivity)
        }
    }

    func handleOpenURLContexts(_ urlContexts: Set<UIOpenURLContext>) {
        for context in urlContexts {
            handleOpen(url: context.url, options: openURLOptions(for: context))
        }
    }

    /// Returns the Google OAuth access token expected by nativeBridge.loginGoogle.
    func signInWithGoogleAccessToken(
        presenting viewController: UIViewController,
        completion: @escaping @MainActor (Result<String, Error>) -> Void
    ) {
        signInWithGoogle(presenting: viewController) { result in
            completion(result.map(\.accessToken))
        }
    }

    /// Signs in to Firebase with Google credentials and returns a Firebase ID token.
    func signInWithFirebaseGoogle(
        presenting viewController: UIViewController,
        completion: @escaping @MainActor (Result<String, Error>) -> Void
    ) {
        signInWithGoogle(presenting: viewController) { [self] result in
            switch result {
            case let .success(tokens):
                firebaseService.signIn(withGoogleTokens: tokens, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    func fetchMessagingToken(
        completion: @escaping @MainActor (Result<String, Error>) -> Void
    ) {
        firebaseService.fetchMessagingToken(completion: completion)
    }

    private func openURLOptions(
        for context: UIOpenURLContext
    ) -> [UIApplication.OpenURLOptionsKey: Any] {
        var options: [UIApplication.OpenURLOptionsKey: Any] = [
            .openInPlace: context.options.openInPlace
        ]
        if let sourceApplication = context.options.sourceApplication {
            options[.sourceApplication] = sourceApplication
        }
        if let annotation = context.options.annotation {
            options[.annotation] = annotation
        }
        return options
    }

    private func signInWithGoogle(
        presenting viewController: UIViewController,
        completion: @escaping @MainActor (Result<GoogleSignInTokens, Error>) -> Void
    ) {
        configureAuthenticationServices()
        googleSignInService.signIn(presenting: viewController, completion: completion)
    }

    private func configureAuthenticationServices() {
        firebaseService.configure()
        googleSignInService.configure(clientID: firebaseService.googleClientID)
    }
}
